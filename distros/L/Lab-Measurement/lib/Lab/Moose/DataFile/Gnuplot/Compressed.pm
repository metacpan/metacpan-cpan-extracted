package Lab::Moose::DataFile::Gnuplot::Compressed;
$Lab::Moose::DataFile::Gnuplot::Compressed::VERSION = '3.682';
#ABSTRACT: Text based data file ('Gnuplot style'), auto-compressed

use 5.010;
use warnings;
use strict;

use Moose;
use File::Basename qw/dirname basename/;
use Lab::Moose::Catfile 'our_catfile';
use Module::Load;
use Carp;

extends 'Lab::Moose::DataFile::Gnuplot';

has compression => (
    is      => 'ro',
    isa     => 'Str',
    default => 'Bzip2',
);


sub _suffix {
    my %suffixtable=(
        None  => '',
        Gzip  => '.gz',
        Bzip2 => '.bz2',
        Lzf   => '.lzf',
        Xz    => '.xz'
    );

    my $module = shift;
    if (defined $suffixtable{$module}) {
        return $suffixtable{$module};
    } else {
        croak "Unsupported compression module $module";
    };
}

sub _modify_file_path {
    my $self = shift;
    my $path = shift;
    return $path . _suffix($self->compression());
}

sub _open_filehandle {
    my $self = shift;
    my $path = shift;

    my $fh;

    if ($self->compression() eq 'None') {

        $fh = super();

    } else {

	my $modulename = "IO::Compress::" . $self->compression();
        load $modulename;

        $fh   = ("IO::Compress::".$self->compression())->new($path)
            or croak "cannot open '$path': $!";

    }

    return $fh;
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

version 3.682

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

Compression type; defaults to 'Bzip2', which is also the only value
that has been tested so far. The following values are possible:

  None
  Gzip
  Bzip2
  Lzf
  Xz

Note that (except for None) this requires the corresponding
IO::Compress:: modules to be available; only Gzip and Bzip2 are
part of core perl.

=back

This datafile type does not support any plots.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2018       Andreas K. Huettel, Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
