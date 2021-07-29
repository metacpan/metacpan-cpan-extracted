#!perl

use strict;
use warnings;

use Test::Perl::Critic (-profile => "t/perlcriticrc") x!! -e "t/perlcriticrc";
all_critic_ok();
