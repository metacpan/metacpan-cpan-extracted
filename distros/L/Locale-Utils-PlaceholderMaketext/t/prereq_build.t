#!perl

use strict;
use warnings;

use Test::More;

$ENV{RELEASE_TESTING}
    or plan(
        skip_all => 'Author test.  Set $ENV{RELEASE_TESTING} to a true value to run.'
    );

eval 'use Test::Prereq::Build; 1'
    or plan( skip_all => 'Test::Prereq::Build not installed' );

# These modules should not go into Build.PL
my @skip_devel_only = qw(
    Test::Kwalitee
    Test::Perl::Critic
    Test::Prereq::Build
);

my @skip = (
    @skip_devel_only,
);

prereq_ok( undef, undef, \@skip );
