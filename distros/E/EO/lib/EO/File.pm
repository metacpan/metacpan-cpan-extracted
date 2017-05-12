package EO::File;

use strict;
use warnings;

use NEXT;
use EO::Data;
use IO::File;
use EO::Storage;
use EO::delegate;
use Path::Class::File;

our $VERSION = 0.96;
our @ISA = qw(EO::Storage);

exception EO::Error::File;
exception EO::Error::File::NotFound
  extends => 'EO::Error::File';
exception EO::Error::File::Permission
  extends => 'EO::Error::File';
exception EO::Error::File::IsDirectory
  extends => 'EO::Error::File';
exception EO::Error::File::Permission::Read
  extends => 'EO::Error::File::Permission';
exception EO::Error::File::Open
  extends => 'Eo::Error::File';

sub init {
  my $self = shift;

  return 0 unless ($self->NEXT::init(@_));

  my %params = @_;

  if ( my $file = $params{path} ) {
    $self->path($file)
  }

  return 1;
}

sub path {
  my $self = shift;
  if(@_) {
    my $path = shift;
    unless(UNIVERSAL::isa($path, 'Path::Class::File')) {
      $path = Path::Class::File->new(ref $path
				     ? @{$path}
				     : $path
				    );
      $path = $path->absolute();
    }
    $self->delegate($path);
    return $self;
  }
  return $self->delegate();
}

sub as_string {
  my $self = shift;
  return $self->stringify();
}

sub exists {
  my $self = shift;
  my $filename = $self->as_string;
  unless(-e $filename) {
    throw EO::Error::File::NotFound
      text => "Cannot open file: $filename, file not found",
      filename => $filename;
  }
}

sub isfile {
  my $self = shift;
  my $filename = $self->as_string;
  if (-d $filename) {
    throw EO::Error::File::IsDirectory
      text => "Cannot open file: $filename, path is a directory";
  }
}

sub readable {
  my $self = shift;
  my $filename = $self->as_string;
  unless(-r $filename) {
    throw EO::Error::File::Permission::Read
      text => "Cannot open file: $filename, file not readable";
  }
}

sub handle {
  my $self = shift;
  my $mode = shift;
  if (!$mode) {
    throw EO::Error::InvalidParameters
      text => "no mode supplied";
  }
  my $fh = IO::File->new( $self->as_string, $mode );
  if (!$fh) {
    my $err = 'Cannot open file: ';
    $err   .= $self->as_string;
    $err   .= " with mode $mode ($!)";
    throw EO::Error::File::Open text => $err;
  }
  return $fh;
}

sub load {
  my $self = shift;

  $self->exists;
  $self->isfile;
  $self->readable;

  my $fh = $self->handle("<");

  local($/);
  my $raw_content = $fh->getline;

  $self->data(
	      EO::Data->new()
	              ->storage( $self )
	              ->content( \$raw_content )
	     );

  $fh->close();

  return $self->data;
}

sub data {
  my $self = shift;
  if (@_) {
    $self->{ e_file_data } = shift;
    return $self;
  }
  return $self->{ e_file_data };
}

sub file_error {
  my $self = shift;
  throw EO::Error::File
    text => "Could not perform operation on file ", $self->as_string, " ($!)";
}

sub unlink {
  my $self = shift;
  unlink($self->as_string) || $self->file_error;
  return $self;
}


sub save {
  my $self = shift;
  my $data = shift;

  my $filename = $self->as_string();
  my $parent = $self->dir();

  my $fh = $self->handle( "+>" );
  my $content = $data->content_ref;

  $fh->print( $$content ) || $self->file_error;
  $fh->close();
}

sub DESTROY {
  my $self = shift;

  if ($self->data) {
    $self->data->delete_storage( $self );
  }

  $self->NEXT::DESTROY;
}

sub make_absolute {
  my $self = shift;
  $self->delegate($self->absolute);
}

sub make_relative {
  my $self = shift;
  $self->delegate($self->absolute);
}

1;
