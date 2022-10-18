#!perl

use strict;
use warnings;

use Test::Perl::Critic (-profile => "t/rc/perlcriticrc:q") x!! -e "t/rc/perlcriticrc:q";
all_critic_ok();
