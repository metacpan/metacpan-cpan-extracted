package Flower::Files;

# a container holding the files for a node

use 5.12.0;

use strict;
use warnings;

use Data::UUID;
use File::Find qw/find/;
use Scalar::Util qw/refaddr/;
use Time::Duration qw/duration concise/;

use Flower::File;

use Carp qw/confess/;

sub new {

  my $class = shift;
  my $args = shift || {};

  confess "called as object method" if ref $class;

  my $self = {};
  bless $self, __PACKAGE__;

  # initialise
  $self->{files} = [];

  return $self;
}

sub remove {
  my $self = shift;
  my $file = shift;
  $self->{files} = [
    map {
      if   ( refaddr($_) ne refaddr($file) ) {$_}
      else                                   { () }
      } @{ $self->{files} }
  ];
  return $self;
}

sub list {
  my $self = shift;
  return @{ $self->{files} };
}

sub count {
  my $self = shift;
  return scalar @{ $self->{files} };
}

sub as_hashref {
  my $self = shift;
  return [
    map {
      { uuid      => $_->uuid,
        filename  => $_->filename,
        size      => $_->size,
        mtime     => $_->mtime,
        nice_size => $_->nice_size,
        age       => concise( duration( time() - $_->mtime ) )
      }
      } $self->list
  ];
}

# search our list of files for a file with a particular name
sub existing_file_with_filename {
  my $self     = shift;
  my $filename = shift;

  foreach ( @{ $self->{files} } ) {
    return $_ if ( $_->filename eq $filename );
  }
  return;
}

sub update_all_in_path {
  my $self = shift;
  my $path = shift;

  # first nuke any files that have disappeared or can no
  # longer be read
  foreach ( @{ $self->{files} } ) {
    $self->remove($_) if ( !-r $_->filename );
  }

  # omg I hate File::Find
  find(
    { no_chdir => 1,
      wanted   => sub {
        my $filename = $_;
        return unless -f $filename;    # exists
        return unless -r $filename;    # readable
        return if -z $filename;        # not zero length

        my $file = $self->existing_file_with_filename($filename);
        if ( $file && ( $file->mtime == ( stat($filename) )[9] ) ) {

          # do nothing, it's already on our list
          return;
        }
        if ( $file && ( $file->mtime != ( stat($filename) )[9] ) ) {

          # it's changed, so delete it, and then fall through
          # to create a new object
          $self->remove($file);
        }

        $file = Flower::File->new_from_local_file(
          { parent   => $self,
            filename => $filename,
            path     => $path,
          }
        );
        push @{ $self->{files} }, $file;
        return;
      },
    },
    $path
  );
  return;
}

sub update_files_from_arrayref {
  my $self = shift;
  my $ref  = shift;

  my @new_files;
  foreach (@$ref) {
    push @new_files,
      Flower::File->new(
      { filename => $_->{filename},
        size     => $_->{size},
        uuid     => $_->{uuid},
        mtime    => $_->{mtime},
        parent   => $self,
      }
      );
  }

  # replace the old with the new
  $self->{files} = [@new_files];
}

1;
