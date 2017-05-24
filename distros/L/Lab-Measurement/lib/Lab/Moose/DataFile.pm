package Lab::Moose::DataFile;

use 5.010;
use warnings;
use strict;

use Moose;
use MooseX::Params::Validate;

use Lab::Moose::DataFolder;

use File::Basename qw/dirname basename/;
use File::Path 'make_path';
use File::Spec::Functions 'catfile';
use IO::Handle;

use Carp;

use namespace::autoclean;

our $VERSION = '3.543';

has folder => (
    is       => 'ro',
    isa      => 'Lab::Moose::DataFolder',
    required => 1,
);

has filename => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has autoflush => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1
);

has filehandle => (
    is       => 'ro',
    isa      => 'FileHandle',
    writer   => '_filehandle',
    init_arg => undef
);

has mode => (
    is      => 'ro',
    isa     => 'Str',
    builder => '_build_file_mode',
);

sub _build_file_mode {
    return '+>';
}

# relative to cwd.
has path => (
    is       => 'ro',
    isa      => 'Str',
    writer   => '_path',
    init_arg => undef
);

sub BUILD {
    my $self = shift;
    $self->_open_file();
}

sub _open_file {
    my $self = shift;

    my $folder   = $self->folder->path();
    my $filename = $self->filename();

    my $dirname = dirname($filename);
    my $dirpath = catfile( $folder, $dirname );

    if ( not -e $dirpath ) {
        make_path($dirpath)
            or croak "cannot make directory '$dirname'";
    }

    my $path = catfile( $folder, $filename );

    $self->_path($path);

    if ( -e $path ) {
        croak "path '$path' does already exist";
    }

    open my $fh, $self->mode(), $path
        or croak "cannot open '$path': $!";

    # Do not use crlf line endings on ms-w32.
    binmode $fh
        or croak "cannot set binmode for '$path'";

    if ( $self->autoflush() ) {
        $fh->autoflush();
    }

    $self->_filehandle($fh);
}

__PACKAGE__->meta->make_immutable();

=head1 NAME

Lab::Moose::DataFile - Base class for data file types.

=head1 METHODS

=head2 new

 my $datafile = Lab::Moose::DataFile->new(
     folder => $folder,
     filename => 'myfile.dat'
 );

=head3 Attributes

=over

=item folder (required)

A L<Lab::Moose::DataFolder> object.

=item filename (required)

filename in the folder.

=item autoflush

Enable autoflush of the filehandle. On by default.

=item mode

C<open> mode. Defaults to ">".

=back

=head3 Read-only attributes available after creation:

=over

=item path

path relative to the current working directory.

=item filehandle

=back

=cut

1;
