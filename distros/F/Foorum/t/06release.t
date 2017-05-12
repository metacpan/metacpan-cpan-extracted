#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;
use FindBin;
use File::Spec;
use lib File::Spec->catdir( $FindBin::Bin, 'lib' );
use Foorum::Release qw/bump_up_version/;

my $version = '0.003001';
$version = bump_up_version($version);
is( $version, '0.003002' );

$version = '0.003009';
$version = bump_up_version($version);
is( $version, '0.004000' );

$version = '0.009009';
$version = bump_up_version($version);
is( $version, '1.000000' );
