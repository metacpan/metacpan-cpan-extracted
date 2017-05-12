#!perl
use 5.010;
use strict;
use warnings;
use utf8;


BEGIN {
    unless ( $ENV{RELEASE_TESTING} ) {
        require Test::More;
        Test::More::plan(
            skip_all => 'these tests are for release candidate testing' );
    }
}

use Test::More;

eval "use Test::Kwalitee";
plan skip_all => "Test::Kwalitee required for testing kwalitee"
    if $@;
