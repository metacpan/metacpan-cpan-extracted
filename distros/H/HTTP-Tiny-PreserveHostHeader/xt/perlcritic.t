#!/usr/bin/perl

use strict;
use warnings;
use File::Spec;
use Test::More;

require Test::Perl::Critic;

Test::Perl::Critic->import(-profile => '.perlcriticrc');

all_critic_ok('examples', 'lib', 't', 'xt', 'Build.PL');
