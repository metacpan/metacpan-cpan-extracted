#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 22;

BEGIN {
    use_ok('DhMakePerl::Utils');
};

sub check {
    my( $src, $dst ) = @_;

    is( DhMakePerl::Utils::nice_perl_ver($src), $dst, "perl version '$src' corresponds to Debian package version '$dst'" );
}

check( '5.006002', '5.6.2' );
check( '5.007003', '5.7.3' );
check( '5.008'   , '5.8.0' );
check( '5.008001', '5.8.1' );
check( '5.008002', '5.8.2' );
check( '5.008003', '5.8.3' );
check( '5.008004', '5.8.4' );
check( '5.008005', '5.8.5' );
check( '5.008006', '5.8.6' );
check( '5.008007', '5.8.7' );
check( '5.008008', '5.8.8' );
check( '5.008009', '5.8.9' );
check( '5.009'   , '5.9.0' );
check( '5.009001', '5.9.1' );
check( '5.009002', '5.9.2' );
check( '5.009003', '5.9.3' );
check( '5.009004', '5.9.4' );
check( '5.009005', '5.9.5' );
check( '5.01'    , '5.10.0');
check( '5.010000', '5.10.0');

check( '5.9.1', '5.9.1' );
