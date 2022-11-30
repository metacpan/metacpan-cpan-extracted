#!perl
use warnings;
use strict;

use Test::More;

{
	## no critic

	eval "
        use Test::Perl::Critic (-exclude => [
                        ]);
    ";
};

if ($@ or ! $ENV{AUTHOR_TESTING}){
	plan skip_all => "Test::Perl::Critic not installed or not AUTHOR_TESTING";
}

all_critic_ok('.');

