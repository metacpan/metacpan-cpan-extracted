#!perl

BEGIN {
    unless ($ENV{AUTHOR_TESTING}) {
        print "1..0 # SKIP these tests are for author testing";
        exit;
    }
}

use strict;
use warnings;

use Test::Perl::Critic (-profile => "t/perlcriticrc") x!! -e "t/perlcriticrc";
all_critic_ok();
