package MockFTDI;

use strict;
use warnings;

use Test::More;
use Test::HexString;

use Future;

use Exporter 'import';
our @EXPORT_OK = qw( is_write is_writeread );

our $MPSSE;
my $GOT_WRITE;
my $SEND_READ;

# Exported test helpers

sub is_write
{
    my ( $write, $name ) = @_;

    undef $GOT_WRITE;
    # Gutwrench - a 'flush' operation
    $MPSSE->_send_bytes( "" )->get;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    is_hexstr( $GOT_WRITE, $write, $name );
}

sub is_writeread
{
    my ( $write, $read, $name ) = @_;

    undef $GOT_WRITE;
    $SEND_READ = $read;
    # Gutwrench - a 'flush' operation
    $MPSSE->_send_bytes( "" )->get;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    is_hexstr( $GOT_WRITE, $write, $name );
    ok( !length $SEND_READ, "All data consumed for $name" );
}


sub reset {}

sub read_data_set_chunksize {}
sub write_data_set_chunksize {}

sub purge_buffers {}

my $bitmode;
sub set_bitmode { ( undef, undef, $bitmode ) = @_; }

sub write_data
{
    shift;
    my ( $bytes ) = @_;

    $GOT_WRITE .= $bytes;
    return Future->done;
}

sub read_data
{
    shift;
    my ( undef, $len ) = @_;

    die "ARGH need $len more bytes of data" unless length $SEND_READ;
    $_[0] = substr( $SEND_READ, 0, $len, "" );
    return Future->done;
}

0x55AA;
