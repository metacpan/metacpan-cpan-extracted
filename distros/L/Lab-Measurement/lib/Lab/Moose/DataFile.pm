package Lab::Moose::DataFile;
$Lab::Moose::DataFile::VERSION = '3.682';
#ABSTRACT: Base class for data file types

use 5.010;
use warnings;
use strict;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Params::Validate;

use Lab::Moose::DataFolder;

use File::Basename qw/dirname basename/;
use File::Path 'make_path';
use Lab::Moose::Catfile 'our_catfile';
use IO::Handle;

use Carp;

use namespace::autoclean;

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

# Subclass this to use fancy stuff like IO::Compress
sub _open_filehandle {
    my $self = shift;
    my $path = shift;

    open my $fh, $self->mode(), $path
        or croak "cannot open '$path': $!";

    return $fh;
}

# Let subclasses add suffixes
sub _modify_file_path {
    my $self = shift;
    my $path = shift;
    return $path;
}

sub _open_file {
    my $self = shift;

    my $folder   = $self->folder->path();
    my $filename = $self->filename();

    my $dirname = dirname($filename);
    my $dirpath = our_catfile( $folder, $dirname );

    if ( not -e $dirpath ) {
        make_path($dirpath)
            or croak "cannot make directory '$dirname'";
    }

    my $path = our_catfile( $folder, $filename );

    $path = $self->_modify_file_path($path);

    $self->_path($path);

    if ( -e $path ) {
        croak "path '$path' does already exist";
    }

    my $fh = $self->_open_filehandle($path);

    # Do not use crlf line endings on ms-w32.
    binmode $fh
        or croak "cannot set binmode for '$path'";

    if ( $self->autoflush() ) {
        $fh->autoflush();
    }

    $self->_filehandle($fh);
}

__PACKAGE__->meta->make_immutable();


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::DataFile - Base class for data file types

=head1 VERSION

version 3.682

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

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2016       Simon Reinhardt
            2017       Andreas K. Huettel, Simon Reinhardt
            2018       Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
