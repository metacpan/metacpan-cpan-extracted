package Lab::Moose::DataFile;
$Lab::Moose::DataFile::VERSION = '3.831';
#ABSTRACT: Base class for data file types

use v5.20;

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

use Net::RFC3161::Timestamp;

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

has timestamp => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0
);

has tsauthority => (
    is      => 'ro',
    isa     => 'Str',
    default => 'dfn.de'
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


sub _close_file {
    my $self = shift;
    my $fh = $self->filehandle();

    close $fh || croak "cannot close datafile";
}

sub DEMOLISH {
    my $self = shift;

    if ( $self->timestamp() ) {

        $self->_close_file();
        attest_file($self->path(), $self->path().".ts", $self->tsauthority());

    }
};

__PACKAGE__->meta->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::DataFile - Base class for data file types

=head1 VERSION

version 3.831

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

=item timestamp

Request RFC3616 compatible timestamps of the measured data
upon completion, from the timestamp authority specified via
tsauthority. Off by default.

If enabled, an additional file with the suffix .ts containing
the signed timestamp will be created.

=item tsauthority

When timestamps are requested, specify the authority to be
contacted. The parameter can be a shorthand as, e.g., "dfn.de";
see L<Net::RFC3161::Timestamp> for details. If no valid shorthand
is found, the parameter is interpreted as a RFC3161 URL.

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

This software is copyright (c) 2022 by the Lab::Measurement team; in detail:

  Copyright 2016       Simon Reinhardt
            2017       Andreas K. Huettel, Simon Reinhardt
            2018       Simon Reinhardt
            2020-2021  Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
