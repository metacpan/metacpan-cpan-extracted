#!perl

use strict;
use warnings;

use English qw(-no_match_vars $EVAL_ERROR);
use Test::More;

$ENV{TEST_RELEASE}
    or plan(
        skip_all => 'Author test.  Set $ENV{TEST_RELEASE} to a true value to run.'
    );

eval 'use Test::Prereq::Build';
if ( $EVAL_ERROR ) {
    my $msg = 'Test::Prereq::Build not installed; skipping';
    plan( skip_all => $msg );
}

# These modules should not go into Build.PL
my @skip_devel_only = qw{
    Test::Kwalitee
    Test::Perl::Critic
    Test::Prereq::Build
};

my @skip = (
    @skip_devel_only,
);

prereq_ok( undef, undef, \@skip );
