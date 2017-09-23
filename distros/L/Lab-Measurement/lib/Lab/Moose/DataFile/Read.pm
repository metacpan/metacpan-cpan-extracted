package Lab::Moose::DataFile::Read;
#ABSTRACT: Read a gnuplot-style 2D data file
$Lab::Moose::DataFile::Read::VERSION = '3.600';
use 5.010;
use warnings;
use strict;
use MooseX::Params::Validate 'validated_list';
use PDL::Lite;
use PDL::IO::Misc 'rcols';
use Fcntl 'SEEK_SET';
use Carp;
use Exporter 'import';

our @EXPORT_OK = qw/read_2d_gnuplot_format/;

sub read_2d_gnuplot_format {
    my ( $fh, $file ) = validated_list(
        \@_,
        fh   => { isa => 'FileHandle', optional => 1 },
        file => { isa => 'Str',        optional => 1 }
    );

    if ( !( $fh || $file ) ) {
        croak "read_2d_gnuplot_format needs either 'fh' or 'file' argument";
    }

    if ( !$fh ) {
        open $fh, '<', $file
            or croak "cannot open file $file: $!";
    }

    # Rewind filehandle.
    seek $fh, 0, SEEK_SET
        or croak "cannot seek";

    # Read data into array of PDLs
    my @columns = rcols( $fh, { EXCLUDE => '/^(#|\s*$)/' } );
    if ( not @columns ) {
        croak "cannot read: $!";
    }

    return \@columns;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::DataFile::Read - Read a gnuplot-style 2D data file

=head1 VERSION

version 3.600

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by the Lab::Measurement team; in detail:

  Copyright 2016       Simon Reinhardt
            2017       Andreas K. Huettel, Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
