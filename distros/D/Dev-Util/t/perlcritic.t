#!/usr/bin/env perl

use Test2::V0;
use Test2::Require::AuthorTesting;

use Dev::Util::Syntax;

use Test2::Require::Module 'Test::Perl::Critic';
use Test::Perl::Critic;
use FindBin qw($RealBin);

# perlcritic config set in this file
local $ENV{ PERLCRITIC } = $RealBin . '/perlcriticrc';

Test::Perl::Critic::all_critic_ok();
