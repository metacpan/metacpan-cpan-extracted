#!perl

use strict;
use warnings;

use Test::Perl::Critic (-profile => "testcritic.rc") x!! -e "testcritic.rc";
all_critic_ok();
