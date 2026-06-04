package FalkorDBTests;

use strict;
use warnings;
use Test::More;

use Exporter 'import';
our @EXPORT_OK = qw(get_connection_details);

sub get_connection_details {
    if ( !defined $ENV{FALKORDB} || $ENV{FALKORDB} eq '' ) {
        plan skip_all => 'FALKORDB environment variable is not set';
    }

    my ( $host, $port ) = ( $ENV{FALKORDB}, 6379 );
    if ( $ENV{FALKORDB} =~ /^(.*):(\d+)$/ ) {
        $host = $1;
        $port = $2;
    }

    return ( $host, $port );
}

1;
