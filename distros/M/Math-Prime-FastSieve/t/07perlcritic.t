## no critic(RCS,VERSION,explicit,Module)
use strict;
use warnings;

use Test::More;
use English qw(-no_match_vars);

if ( not $ENV{RELEASE_TESTING} ) {
    my $msg = 'Author test.  Set $ENV{RELEASE_TESTING} to a true value to run.';
    plan( skip_all => $msg );
}

eval 'use Test::Perl::Critic';    ## no critic (eval)

if ($EVAL_ERROR) {
    my $msg = 'Test::Perl::Critic required to criticise code';
    plan( skip_all => $msg );
}

all_critic_ok( 'examples', 't', 'lib' );
