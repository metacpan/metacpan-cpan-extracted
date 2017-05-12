use 5.006;
use strict;
use warnings;

package Metabase::Index::SQLite::Sharded;
# ABSTRACT: Metabase index using multiple SQLite databases

our $VERSION = '1.001';

use Moose;
use Data::Stream::Bulk::Callback;
use List::Util qw/sum/;
use Storable qw/dclone/;
use Moose::Util::TypeConstraints;
use Metabase::Index::SQLite;

with 'Metabase::Backend::SQLite';
with 'Metabase::Index' => { -excludes => 'exists' };

subtype 'IndexShardSize', # XXX should refactor with Archive one
    as 'Int',
    where { $_ > 0 && $_ < 8 }, # can't trust last byte of timestamp
    message { "The number you provided, $_, was not between 1 and 8" };

has shard_digits => (
  is => 'ro',
  isa => 'IndexShardSize',
  default => 2,
);

has _shards => (
  is => 'ro',
  traits => ['Hash'],
  isa => 'HashRef[Object]',
  default => sub { return {} },
  handles => {
    '_get_shard' => 'get',
    '_set_shard' => 'set',
    '_all_shards' => 'values',
  },
);

sub initialize {
  my ($self, $classes, $resources) = @_;
  my $filename = $self->filename;
  my ($basename, $ext) = $self->filename =~ m{^(.*)\.([^.]+)$};
  $ext = '' unless defined $ext;
  $basename = $filename unless defined $basename;
  my $digits = $self->shard_digits;
  my $template = $digits == 1 ? "H2" : "H$digits";
#  warn "*** TEMPLATE: $template";
  for my $n ( 0 .. 16**$digits - 1) {
    my $key = unpack($template,pack("I",$n));
    my $index_file;
    if ( $basename && $ext ) {
      $index_file = "$basename\_$key.$ext";
    }
    else {
      $index_file = "$basename\_$key";
    }
    my $index = Metabase::Index::SQLite->new(
      filename => $index_file,
    ) or die "Couldn't not build shard '$index_file' \n";
#    warn "*** Initializing $key\n";
    $index->initialize($classes, $resources);
    $self->_set_shard($key, $index);
  }
  return;
}

sub _shard_key {
  my ($self, $guid) = @_;
  my $digits = $self->shard_digits;
  my $key = substr $guid, (7-$digits), $digits;
  if ( defined $key && length $key > 1 ) {
    return $key;
  }
  elsif ( defined $key && length $key == 1 ) {
    return "0$key";
  }
  else {
    return scalar "0"x($digits==1 ? 2 : $digits);
  }
}

# override from role to target query at right shard
sub exists {
    my ($self, $guid) = @_;
    my $key = $self->_shard_key($guid);
    my $shard = $self->_get_shard($key);
    # if desired guid in upper case, fix it
    return scalar @{ $shard->search(-where => [-eq =>'core.guid'=>lc $guid])};
}

sub add {
  my ( $self, $fact ) = @_;
  my $key = $self->_shard_key($fact->guid);
#  warn "***Adding to shard '$key'\n";
  my $shard = $self->_get_shard($key)
    or die "Couldn't find shard for '$key' from " . $fact->guid. "\n";
  return $shard->add($fact);
}

sub delete {
  my ( $self, $guid ) = @_;
  my $key = $self->_shard_key($guid);
  return $self->_get_shard($key)->delete($guid);
}

sub count {
  my ( $self, %spec ) = @_;
  return sum map { $_->count(%{ dclone(\%spec) }) } $self->_all_shards;
}

sub query {
  my ( $self, %spec) = @_;
  my @shards = $self->_all_shards;
  my @iters = map { $_->_shard_query(%{ dclone(\%spec) }) } $self->_all_shards;

  # XXX this does not preserve order or limit
  my $limit = $spec{-limit};
  my $count = 0;
  return Data::Stream::Bulk::Callback->new(
    callback => sub {
      return if $limit && $count == $limit; # shortcut
      # Need to merge results
      my @results;
      my @not_done;
      for my $s ( @iters ) {
        if ( my @items = $s->items ) {
          push @not_done, $s; # round-robin
          push @results, @items;
        }
      }
      return unless @results;
      @iters = @not_done; # for next invocation
      # Need to order results
      if ( my @clauses = $self->_order_clauses(\%spec) ) {
        @results = $self->_sort_results(\@results, \@clauses);
      }
      # Need to limit results
      if ( $limit ) {
        if ( $count + @results <= $limit ) {
          $count += @results;
        }
        else {
          my $need = $limit - $count;
          $count += $need;
          splice @results, $need;
        }
      }
      # Need to extract just guid
#      warn "*** RESULTS: @results\n";
      return [ map { $_->[0] } @results ]; # just the GUID
    },
  );
}

sub _order_clauses {
  my ($self, $spec) = @_;
  if ( defined $spec->{-order} and ref $spec->{-order} eq 'ARRAY') {
    my @clauses;
    my @order = @{$spec->{-order}};
    while ( @order ) {
      my ($dir, $field) = splice( @order, 0, 2);
      $dir =~ s/^-//;
      $dir = uc $dir;
      push @clauses, [$field, $dir];
    }
    return @clauses;
  }
  else {
    return ();
  }
}

sub _sort_results {
  my ($self, $results, $clauses) = @_;
  my $sorter = sub {
    my ($left_data, $right_data) = @_;
    for my $i ( 0 .. $#$clauses ) {
      my $dir = $clauses->[$i][1];
      my $left  = $left_data->[$i+1];
      my $right = $right_data->[$i+1];
      if ( $dir eq 'ASC' ) {
        return 1  if $left gt $right;
        return -1 if $left lt $right;
      }
      else {
        return -1 if $left gt $right;
        return 1  if $left lt $right;
      }
    }
    return 0; # everything was equal
  };
  return sort { $sorter->($a,$b) } @$results; ## no critic
}

# Fake these to satisfy the role -- we actually delegate everything out
# to shards
sub op_and { }
sub op_between { }
sub op_eq { }
sub op_ge { }
sub op_gt { }
sub op_le { }
sub op_like { }
sub op_lt { }
sub op_ne { }
sub op_not { }
sub op_or { }
sub translate_query { }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Metabase::Index::SQLite::Sharded - Metabase index using multiple SQLite databases

=head1 VERSION

version 1.001

=head1 SYNOPSIS

  use Metabase::Index::SQLite::Sharded;

  my $index = Metabase::Index::SQLite::Sharded->new(
    filename => $sqlite_file,
    shard_digits => 2,
  ); 

=head1 DESCRIPTION

This is an implementation of the L<Metabase::Index::SQL> role using SQLite
shards.

SQLite stores a database entirely in a single file.  That starts to become
slow as the size of the file gets large.  This Metabase::Index shards
the index across multiple SQLite files.

It takes the same options as L<Metabase::Index::SQLite>, with one additional
option, C<shard_digits>.  The C<shard_digits> attribute defines how many digits
of the GUID to use as a shard key.  Each digit is a hexadecimal number, so
digits increase the number of shards as a power of 16.  E.g., "1" means 16
shards, "2" means 256 shards and so on.

The shard key is inserted to the database C<filename> parameter either before
the final period or at the end.  E.g. for C<shard_digits> of "2" and
C<filename> "db.sqlite3", the shards would be "db_00.slite3", "db_01.sqlite3",
and so on.

=for Pod::Coverage::TrustPod add query delete count exists initialize
translate_query op_eq op_ne op_gt op_lt op_ge op_le op_between op_like
op_not op_or op_and

=head1 AUTHORS

=over 4

=item *

David Golden <dagolden@cpan.org>

=item *

Leon Brocard <acme@astray.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
