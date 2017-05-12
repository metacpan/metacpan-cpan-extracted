use 5.006;    # 06 -> [pragmas, our]
use strict;
use warnings;

package Dist::Zilla::Tempdir::Item::State;

our $VERSION = '1.001003';

# ABSTRACT: Intermediate state for a file

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose qw( has );
use Carp qw( croak );
use Path::Tiny qw( path );







has 'hash' => ( is => ro =>, lazy_build => 1 );







has 'file' => (
  is       => ro =>,
  required => 1,
  handles => { name => name => },
);







has 'new_content' => ( is => ro =>, lazy_build => 1 );







has 'new_hash' => ( is => ro =>, lazy_build => 1 );







has 'storage_prefix' => ( is => ro =>, required => 1 );

has '_digester' => ( is => ro =>, lazy_build => 1 );







sub BUILD {
  my ($self) = @_;
  $self->hash;
  return;
}

sub _build__digester {
  require Digest::SHA;
  ## no critic ( ProhibitMagicNumbers )
  return Digest::SHA->new(512);
}

sub _digest_for {
  my ( $self, $content ) = @_;
  if ( not defined $content ) {
    return croak('->_digest_for( content ) must have a defined value of content');
  }
  $self->_digester->reset();
  $self->_digester->add($content);
  return $self->_digester->b64digest;
}

sub _build_hash {
  my ($self) = @_;
  return $self->_digest_for( $self->_encoded_content );
}

sub _build_new_content {
  my ($self) = @_;
  return unless $self->on_disk;
  return $self->_relpath->slurp_raw();
}

sub _build_new_hash {
  my ($self) = @_;
  return unless $self->on_disk;
  return $self->_digest_for( $self->new_content );
}

sub _encoded_content {
  my ($self) = @_;
  my $content;
  my $method = 'content';
  if ( $self->file->can('encoded_content') ) {
    $method  = 'encoded_content';
    $content = $self->file->encoded_content;
  }
  else {
    $content = $self->file->content;
  }
  if ( not defined $content ) {
    croak( $self->file . " returned undef for $method" );
  }
  return $content;
}

sub _relpath {
  my ($self)   = @_;
  my $d        = path( $self->storage_prefix );
  my $out_path = $d->child( $self->file->name );
  return $out_path;
}







sub write_out {
  my ($self) = @_;
  my $out_path = $self->_relpath();
  $out_path->parent->mkpath(1);
  $out_path->spew_raw( $self->_encoded_content );
  return;
}







sub on_disk {
  my ($self) = @_;
  my $out_path = $self->_relpath();
  return -e $out_path;
}








sub on_disk_changed {
  my ($self) = @_;
  return unless $self->on_disk;
  return $self->hash ne $self->new_hash;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Tempdir::Item::State - Intermediate state for a file

=head1 VERSION

version 1.001003

=head1 ATTRIBUTES

=head2 C<hash>

Provides a digest hash of C<file>'s content

=head2 C<file>

A C<Dist::Zilla::File>

=head2 C<new_content>

Content of C<storage_prefix>/C<file> read from disk.

=head2 C<new_hash>

Hash of C<new_content>

=head2 C<storage_prefix>

The root directory to write this file out to, and to read it from.

=head1 METHODS

=head2 C<BUILD>

Ensures C<hash> is populated at build time.

=head2 C<write_out>

Emits C<file> into C<storage_prefix>

=head2 C<on_disk>

Returns true if C<file> exists in C<storage_prefix>

=head2 C<on_disk_changed>

Returns true if the file is on disk, and the on-disk hash
doesn't match the written out C<file>'s hash.

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
