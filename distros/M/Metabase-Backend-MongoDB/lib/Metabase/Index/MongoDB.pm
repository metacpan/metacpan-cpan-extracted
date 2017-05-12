use 5.010;
use strict;
use warnings;

package Metabase::Index::MongoDB;
our $VERSION = '1.000'; # VERSION 

use boolean;
use re qw/regexp_pattern/;
use Data::Stream::Bulk::Callback;
use MongoDB;
use Regexp::SQL::LIKE 0.001 qw/to_regexp/;
use Try::Tiny;

use Moose;
with 'Metabase::Backend::MongoDB';
with 'Metabase::Index' => { -version => 0.017 };

#--------------------------------------------------------------------------#
# required by Metabase::Backend::MongoDB
#--------------------------------------------------------------------------#

sub _build_collection_name {
  return 'metabase_index';
}

sub _ensure_index {
  my ($self, $coll) = @_;
  return $coll->ensure_index(
    $self->_munge_keys({ 'core.guid' => 1 }),
    { safe => 1, unique => true} 
  );
}

sub initialize {}

#--------------------------------------------------------------------------#
# required by Metabase::Index
#--------------------------------------------------------------------------#

sub add {
    my ( $self, $fact ) = @_;

    Carp::confess("can't index a Fact without a GUID") unless $fact->guid;

    my $metadata = $self->clone_metadata( $fact );
    $self->_munge_keys($metadata);

    return $self->coll->insert( $metadata, {safe => 1} );
}

sub count {
    my ($self, %spec) = @_;
    my ($query, $mods) = $self->get_native_query(\%spec);
    local $MongoDB::Cursor::slave_okay = 1;
    return $self->coll->count($query);
}

sub query { 
    my ($self, %spec) = @_;
    my ($query, $mods) = $self->get_native_query(\%spec);

    local $MongoDB::Cursor::slave_okay = 1;
    my $cursor = $self->coll->query( $query, $mods );
    $cursor->immortal(1); # this could take a while!
    my $guid_key = $self->_munge_keys('core.guid');

    return Data::Stream::Bulk::Callback->new(
      callback => sub {
        my @results;
        for ( 1 .. 50 ) {
          last unless $cursor->has_next;
          my $obj = $cursor->next;
          push @results, $obj->{$guid_key} ;
        }
        return @results ? \@results : undef;
      }
    );
}

# DO NOT lc() GUID
sub delete {
    my ( $self, $guid ) = @_;

    Carp::confess("can't delete without a GUID") unless $guid;

    my $query = $self->_munge_keys( { 'core.guid' => $guid }, '.' => '|' );

    try { $self->coll->remove($query, { safe => 1 }) };

    # XXX should we be confessing on a failed delete? -- dagolden, 2011-06-30
    return $@ ? 0 : 1;
}

#--------------------------------------------------------------------------#
# required by Metabase::Query
#--------------------------------------------------------------------------#

sub translate_query {
  my ( $self, $spec ) = @_;

  my $query = {};

  # translate search query
  if ( defined $spec->{-where} and ref $spec->{-where} eq 'ARRAY') {
    $query = $self->dispatch_query_op( $spec->{-where} );
  }

  # translate query modifiers
  my $options = {};

  if ( defined $spec->{-order} and ref $spec->{-order} eq 'ARRAY') {
    my @order = @{$spec->{-order}};
    while ( @order ) {
      my ($dir, $field) = splice( @order, 0, 2);
      $options->{sort_by}{$field} = ($dir eq '-asc') ? 1 : -1;
      $self->_munge_keys( $options->{sort_by} );
    }
  }

  if ( defined $spec->{-limit} ) {
    $options->{limit} = $spec->{-limit};
  }

  return $query, $options;
}

sub op_eq {
  my ($self, $field, $val) = @_;
  return $self->_munge_keys( { $field, $val } );
}

sub op_ne {
  my ($self, $field, $val) = @_;
  return $self->_munge_keys( { $field, { '$ne', $val } } );
}

sub op_gt {
  my ($self, $field, $val) = @_;
  return $self->_munge_keys( { $field, { '$gt', $val } } );
}

sub op_lt {
  my ($self, $field, $val) = @_;
  return $self->_munge_keys( { $field, { '$lt', $val } } );
}

sub op_ge {
  my ($self, $field, $val) = @_;
  return $self->_munge_keys( { $field, { '$gte', $val } } );
}

sub op_le {
  my ($self, $field, $val) = @_;
  return $self->_munge_keys( { $field, { '$lte', $val } } );
}

sub op_between {
  my ($self, $field, $low, $high) = @_;
  return $self->_munge_keys( { $field, { '$gte' => $low, '$lte' => $high } } );
}

sub op_like {
  my ($self, $field, $val) = @_;
  my ($re) = regexp_pattern(to_regexp($val));
  return $self->_munge_keys( { $field, { '$regex' => $re } } );
}

my %can_negate = map { $_ => 1 } qw(
  -ne -lt -le -gt -ge -between
);

sub op_not {
  my ($self, $pred) = @_;
  my $op = $pred->[0];
  if ( ! $can_negate{$op} ) {
    Carp::confess( "Cannot negate '$op' operation\n" );
  }
  my $clause = $self->dispatch_query_op($pred);
  for my $k ( keys %$clause ) {
    $clause->{$k} = { '$not' => $clause->{$k} };
  }
  return $self->_munge_keys($clause);
}

sub op_or {
  my ($self, @args) = @_;
  state $depth = 0;
  if ( $depth++ ) {
    Carp::confess( "Cannot nest '-or' predicates\n" );
  }
  my @predicates = map { $self->dispatch_query_op($_) } @args;
  $depth--;
  return { '$or' => \@predicates };
}

# AND has to flatten criteria into a single hash, but that means
# there are several things that don't work and we have to croak
sub op_and {
  my ($self, @args) = @_;

  my $query = {};
  while ( my $pred = shift @args ) {
    my $clause = $self->dispatch_query_op( $pred );
    for my $field ( keys %$clause ) {
      if ( exists $query->{$field} ) {
        if ( ref $query->{$field} ne 'HASH' ) {
          Carp::croak("Cannot '-and' equality with other operations");
        }
        _merge_hash( $field, $query, $clause );
      }
      else {
        $query->{$field} = $clause->{$field};
      }
    }
  }

  return $query;
}

sub _merge_hash {
  my ( $field, $orig, $new ) = @_;
  for my $op ( keys %{$new->{$field}} ) {
    if ( exists $orig->{$field}{$op} ) {
      Carp::confess( "Cannot merge '$op' criteria for '$field'\n" );
    }
    $orig->{$field}{$op} = $new->{$field}{$op};
  }
  return;
}

1;

# ABSTRACT: Metabase index on MongoDB
#
# This file is part of Metabase-Backend-MongoDB
#
# This software is Copyright (c) 2011 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#


__END__
=pod

=head1 NAME

Metabase::Index::MongoDB - Metabase index on MongoDB

=head1 VERSION

version 1.000

=head1 SYNOPSIS

  use Metabase::Index::MongoDB;

  Metabase::Index::MongoDB->new(
    host    => 'mongodb://localhost:27017',
    db_name => 'my_metabase',
  );

=head1 DESCRIPTION

This is an implementation of the L<Metabase::Index> and L<Metabase::Query>
roles using MongoDB.

=for Pod::Coverage::TrustPod add query delete count initialize
translate_query op_eq op_ne op_gt op_lt op_ge op_le op_between op_like
op_not op_or op_and

=head1 USAGE

See L<Metabase::Backend::MongoDB> for constructor attributes.  See
L<Metabase::Index>, L<Metabase::Query> and L<Metabase::Librarian>
for details on usage.

=head1 LIMITATIONS

Search queries have limitations based on the underlying MongoDB search
API.  Specifically:

=over

=item C<-and>

It is not possible to combine C<-eq> with other comparisons on the same
field or to combine multiple constraints on the same field using the
same operator (e.g. two C<-like> constraints).

=item C<-or>

The C<-or> operator cannot be nested.

=item C<-not>

Only simple comparisons can be negated.  This makes C<-not> not particularly
useful.

=back

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut

