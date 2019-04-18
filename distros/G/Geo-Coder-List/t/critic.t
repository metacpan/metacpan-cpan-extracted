#!perl -w

use strict;
use warnings;
use File::Spec;
use Test::Most;
use English qw(-no_match_vars);

unless($ENV{AUTHOR_TESTING}) {
	plan(skip_all => 'Author tests not required for installation');
}

eval "use Test::Perl::Critic";

plan(skip_all => 'Test::Perl::Critic not installed; skipping') if $@;

all_critic_ok();
