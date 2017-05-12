#!perl

if (!require Test::Perl::Critic) {
    Test::More::plan(
        skip_all => "Test::Perl::Critic required for testing PBP compliance"
    );
}

use Test::Perl::Critic(-exclude => ['ProhibitExplicitReturnUndef']);
all_critic_ok();
