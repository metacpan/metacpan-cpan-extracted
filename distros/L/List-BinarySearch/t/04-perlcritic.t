#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use English qw( -no_match_vars );


# To enable this suite one must set the RELEASE_TESTING environment variable
# to a true value.
# This prevents author tests from running on a user install.
# It's possible users would have their own conflicting Perl::Critic config,
# so it would be a bad idea to let this test run on users systems.

if ( not $ENV{RELEASE_TESTING} ) {
    my $msg =
        'Author Test: Set $ENV{RELEASE_TESTING} to a true value to run.';
    plan( skip_all => $msg );
}

# We also don't want to force a dependency on Test::Perl::Critic, so if the
# user doesn't have the module, we won't run the test.

eval { require Test::Perl::Critic; }; ## no critic (eval)

if ( $EVAL_ERROR ) {
    my $msg = 'Author Test: Test::Perl::Critic required to criticise code.';
    plan( skip_all => $msg );
}

# Set a higher severity level.  Note: List/BinarySearch.pm meets level 2.
Test::Perl::Critic->import( -severity => 4 );

# We want to test the primary module components (blib/) as well as the
# test suite (t/).
my @directories = qw{  blib/  t/  };


Test::Perl::Critic::all_critic_ok( @directories );

done_testing();
