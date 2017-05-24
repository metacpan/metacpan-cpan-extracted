package Lab::Moose::DataFile::Read;
use 5.010;
use warnings;
use strict;
use MooseX::Params::Validate 'validated_list';
use PDL::Lite;
use PDL::IO::Misc 'rcols';
use Fcntl 'SEEK_SET';
use Carp;
use Exporter 'import';
our $VERSION = '3.543';

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
