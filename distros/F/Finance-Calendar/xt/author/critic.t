#!perl

use strict;
use warnings;

use Test::Perl::Critic (-profile => "t/rc/perlcriticrc") x!! -e "t/rc/perlcriticrc";
all_critic_ok();
