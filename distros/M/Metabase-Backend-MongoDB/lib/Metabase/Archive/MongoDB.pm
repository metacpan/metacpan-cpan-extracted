use 5.006;
use strict;
use warnings;

package Metabase::Archive::MongoDB;
our $VERSION = '1.000'; # VERSION

use boolean;
use Carp       ();
use Compress::Zlib 2 qw(compress uncompress);
use Data::Stream::Bulk::Callback;
use JSON 2 qw/encode_json decode_json/;
use Metabase::Fact;
use Try::Tiny;


use Moose;

with 'Metabase::Backend::MongoDB';
with 'Metabase::Archive' => { -version => 0.017 };

#--------------------------------------------------------------------------#
# required by Metabase::Backend::MongoDB
#--------------------------------------------------------------------------#

sub initialize {}

sub _build_collection_name {
  return 'metabase_archive';
}

sub _ensure_index {
  my ($self, $coll) = @_;
  return $coll->ensure_index(
    { 'g' => 1 },
    { safe => 1, unique => true}
  );
}

#--------------------------------------------------------------------------#
# required by Metabase::Archive
#--------------------------------------------------------------------------#

# given fact, store it and return guid;
sub store {
    my ( $self, $fact_struct ) = @_;
    my $guid = $fact_struct->{metadata}{core}{guid};
    my $type = $fact_struct->{metadata}{core}{type};

    unless ($guid) {
        Carp::confess "Can't store: no GUID set for fact\n";
    }

    my $json = compress(encode_json($fact_struct));

    # g for guid; d for data
    $self->coll->insert( { g => $guid, d => $json }, {safe => 1} );

    return $guid;
}

# given guid, retrieve it and return it
# type is directory path
# class isa Metabase::Fact::Subclass
sub extract {
    my ( $self, $guid ) = @_;
    local $MongoDB::Cursor::slave_okay = 1;
    my $obj = $self->coll->find_one( { g => $guid } );
    return decode_json(uncompress($obj->{d}));
}

# DO NOT lc() GUID
sub delete {
    my ( $self, $guid ) = @_;
    return $self->coll->remove( {g => $guid}, {safe => 1} );
}

sub iterator {
  my $self = shift;
  local $MongoDB::Cursor::slave_okay = 1;
  my $cursor = $self->coll->query;
  $cursor->immortal(1); # this could take a while!
  return Data::Stream::Bulk::Callback->new(
    callback => sub {
      my @results;
      for ( 1 .. 50 ) {
        last unless $cursor->has_next;
        my $obj = $cursor->next;
        push @results, decode_json(uncompress($obj->{d}));
      }
      return @results ? \@results : undef;
    }
  );
}

1;

# ABSTRACT: Metabase storage using MongoDB
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

Metabase::Archive::MongoDB - Metabase storage using MongoDB

=head1 VERSION

version 1.000

=head1 SYNOPSIS

  use Metabase::Archive::MongoDB;

  Metabase::Archive::MongoDB->new(
    host    => 'mongodb://localhost:27017',
    db_name => 'my_metabase',
  );

=head1 DESCRIPTION

This is an implementation of the L<Metabase::Archive> role using MongoDB.

=for Pod::Coverage::TrustPod store extract delete iterator initialize

=head1 USAGE

See L<Metabase::Backend::MongoDB> for constructor attributes.  See
L<Metabase::Archive> and L<Metabase::Librarian> for details on usage.

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut

