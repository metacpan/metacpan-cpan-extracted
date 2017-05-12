#!/sw/bin/perl

use strict;
use warnings;
use Test::More;

eval 'use Test::Perl::Critic (-severity => 3) ';
plan skip_all => 'Test::Perl::Critic required to criticize code' if $@;

all_critic_ok();
