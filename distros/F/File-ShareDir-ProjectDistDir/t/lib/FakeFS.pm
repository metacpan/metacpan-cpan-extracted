use 5.006;
use strict;
use warnings;

package FakeFS;

# ABSTRACT: Inflate a directory at a given path temporarily

# AUTHORITY

use Class::Tiny qw(root), {
  files => sub { [] }
};
use Path::Tiny qw(path);

sub BUILD {
  my ( $self, $args ) = @_;
  path( $self->root )->mkpath;
}

sub add_file {
  my ( $self, $path, $content ) = @_;
  my $target = path( $self->root )->child($path);
  $target->parent->mkpath;
  $target->spew($content);
  push @{ $self->files }, $target;
}

sub DESTROY {
  my ($self) = @_;
  return if $ENV{NODELETE};
  for my $file ( @{ $self->files } ) {
    $file->remove;
  }
  path( $self->root )->remove_tree( { safe => 0 } );
}

1;

