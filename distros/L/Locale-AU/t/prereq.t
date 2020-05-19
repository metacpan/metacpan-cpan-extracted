#!perl -wT

use strict;
use warnings;

use Test::Most;

unless($ENV{RELEASE_TESTING}) {
    plan( skip_all => "Author tests not required for installation" );
}

eval "use Test::Prereq";
plan skip_all => "Test::Prereq required to test dependencies" if $@;
prereq_ok();
