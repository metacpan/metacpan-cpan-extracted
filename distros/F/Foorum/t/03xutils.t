#!/usr/bin/perl

use strict;
use warnings;

BEGIN {
    $ENV{TEST_FOORUM} = 1;
}

use Test::More tests => 5;
use FindBin qw/$RealBin/;
use Cwd qw/abs_path/;
use Foorum::XUtils qw/base_path cache config/;
use File::Spec;

my $base_path = base_path();

my $real = abs_path( File::Spec->catdir( $RealBin, '..' ) );
is( $base_path, $real, 'base_path OK' );

#diag($base_path);

## test config
my $config = config();
ok( $config->{'View::TT'}, 'View::TT config defined' );
is( ref $config->{session}, 'HASH', 'session config is a HASHREF' );

my $cache = cache();

my $key = 'Foorum:testfunction:cache';
my $val = scalar( localtime() );

$cache->set( $key, $val, 60 );
my $ret = $cache->get($key);
is( $ret, $val, 'cache: get ok' );

$cache->remove($key);
$ret = $cache->get($key);
is( $ret, undef, 'cache: get after remove ok' );

