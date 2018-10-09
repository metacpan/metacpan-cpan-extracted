package Lab::Moose::DataFile::Gnuplot::Compressed;
$Lab::Moose::DataFile::Gnuplot::Compressed::VERSION = '3.662';
#ABSTRACT: Text based data file ('Gnuplot style'), auto-compressed

use 5.010;
use warnings;
use strict;

use Moose;
use IO::Compress::Bzip2;
use File::Basename qw/dirname basename/;
use Lab::Moose::Catfile 'our_catfile';
use Carp;

extends 'Lab::Moose::DataFile::Gnuplot';

has compression => (
    is      => 'ro',
    isa     => 'Str',
    default => 'Bzip2',
);


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

    $self->_path($path);

    if ( -e $path ) {
        croak "path '$path' does already exist";
    }

    my $fh = new IO::Compress::Bzip2 $path
        or croak "cannot open '$path': $!";

    binmode $fh
        or croak "cannot set binmode for '$path'";

    if ( $self->autoflush() ) {
        $fh->autoflush();
    }

    $self->_filehandle($fh);
}

sub add_plot {
   croak("Compressed data files do not (yet) support plots.");
}

sub refresh_plots {
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::DataFile::Gnuplot::Compressed - Text based data file ('Gnuplot style'), auto-compressed

=head1 VERSION

version 3.662

=head1 SYNOPSIS

 use Lab::Moose;

 my $folder = datafolder();

 my $file = datafile(
     type => 'Gnuplot::Compressed',
     folder => $folder,
     filename => 'gnuplot-file.dat',
     columns => [qw/time voltage temp/]
     );

 $file->log(time => 1, voltage => 2, temp => 3);

=head1 METHODS

=head2 new

Supports the following attributes in addition to the 
L<Lab::Moose::DataFile::Gnuplot> requirements:

=over

=item * compression

Compression type; defaults to 'Bzip2' (which is also the only supported value 
right now).

=back

Note: this datafile type does not (yet) support any plots.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by the Lab::Measurement team; in detail:

  Copyright 2018       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
