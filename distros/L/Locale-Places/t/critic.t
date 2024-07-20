#!perl -w

use strict;
use warnings;

use File::Spec;
use Test::Most;
use Test::Needs 'Test::Perl::Critic';
use English qw(-no_match_vars);

if($ENV{AUTHOR_TESTING}) {
	Test::Perl::Critic::all_critic_ok();
} else {
	plan(skip_all => 'Author tests not required for installation');
}
