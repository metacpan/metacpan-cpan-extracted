#!/usr/bin/perl
#
# Test for Filter::Rijndael
#

use strict;
use warnings;
use utf8;

use Test::More tests => 1;
use Data::Dumper;

require_ok( 'Filter::Rijndael' );

my $crypt_data = {};
open( my $fh, '<', 'Rijndael.h' );
while ( <$fh> ) {
    next if ( $_ !~ m/static unsigned char\s+([^\[]*)\[[^\{]*\{(.*)\}/ );
    $crypt_data->{$1} = $2;
}

