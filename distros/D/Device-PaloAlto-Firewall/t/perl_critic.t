#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

use Test::Perl::Critic (-severity => 4, -exclude => ['RequireArgUnpacking']);

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

all_critic_ok();








