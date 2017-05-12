use 5.006;
use strict;
use warnings;

package Metabase::Archive::SQLite::Sharded;
# ABSTRACT: Metabase storage using multiple SQLite databases

our $VERSION = '1.001';

use Moose;
use Data::Stream::Bulk::Callback;
use Moose::Util::TypeConstraints;
use Metabase::Archive::SQLite;

with 'Metabase::Backend::SQLite';
with 'Metabase::Archive';

subtype 'ShardSize',
    as 'Int',
    where { $_ > 0 && $_ < 8 },
    message { "The number you provided, $_, was not between 1 and 8" };

has shard_digits => (
  is => 'ro',
  isa => 'ShardSize',
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

sub initialize { }

sub _create_shard {
  my ($self, $key) = @_;

  my $filename = $self->filename;
  my ($basename, $ext) = $self->filename =~ m{^(.*)\.([^.]+)$};
  if ( $basename && $ext ) {
    $filename = "$basename\_$key.$ext";
  }
  else {
    $filename .= "_$key";
  }
  my %args = (
    filename => $filename,
    ($self->has_page_size ? ( page_size => $self->page_size ) : ()),
    ($self->has_cache_size ? ( cache_size => $self->cache_size ) : ()),
  );
  my $archive = Metabase::Archive::SQLite->new( %args );
  $archive->initialize;
  $self->_set_shard($key, $archive);
  return $archive;
}

sub _shard_key {
  my ($self, $guid) = @_;
  return substr $guid, (7-$self->shard_digits), $self->shard_digits;
}

sub store {
  my ( $self, $fact_struct ) = @_;
  my $key = $self->_shard_key( $fact_struct->{metadata}{core}{guid} );
  my $archive = $self->_get_shard($key) || $self->_create_shard($key);
  return $archive->store($fact_struct);
}


sub extract {
  my ( $self, $guid ) = @_;
  my $key = $self->_shard_key( $guid );
  my $archive = $self->_get_shard($key) || $self->_create_shard($key);
  return $archive->extract($guid);
}

sub delete {
  my ( $self, $guid ) = @_;
  my $key = $self->_shard_key( $guid );
  my $archive = $self->_get_shard($key) || $self->_create_shard($key);
  return $archive->delete($guid);
}

sub iterator {
  my ($self) = @_;

  my @iters = map { $_->iterator } $self->_all_shards;

  return Data::Stream::Bulk::Callback->new(
    callback => sub {
      if ( @iters ) {
        my $s = shift @iters;
        if ( my $next = $s->next ) {
          push @iters, $s; # round-robin
          return $next;
        }
      } else {
        return; # done
      }
    },
  );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Metabase::Archive::SQLite::Sharded - Metabase storage using multiple SQLite databases

=head1 VERSION

version 1.001

=head1 SYNOPSIS

  use Metabase::Archive::SQLite::Sharded;

  my $archive = Metabase::Archive::SQLite::Sharded->new(
    filename => $sqlite_file,
    shard_digits => 2,
  ); 

=head1 DESCRIPTION

This is an implementation of the L<Metabase::Archive::SQL> role using SQLite
shards.

SQLite stores a database entirely in a single file.  That starts to become
slow as the size of the file gets large.  This Metabase::Archive shards
facts across multiple SQLite files.

It takes the same options as L<Metabase::Archive::SQLite>, with one additional
option, C<shard_digits>.  The C<shard_digits> attribute defines how many digits
of the GUID to use as a shard key.  Each digit is a hexadecimal number, so
digits increase the number of shards as a power of 16.  E.g., "1" means 16
shards, "2" means 256 shards and so on.

The shard key is inserted to the database C<filename> parameter either before
the final period or at the end.  E.g. for C<shard_digits> of "2" and
C<filename> "db.sqlite3", the shards would be "db_00.slite3", "db_01.sqlite3",
and so on.

=for Pod::Coverage::TrustPod store extract delete iterator initialize

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
