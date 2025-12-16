#!/usr/bin/env perl

use Test2::V0;
use Test2::Require::AuthorTesting;

use Dev::Util::Syntax;

use Test2::Require::Module 'Test2::Tools::PerlCritic';
use Test2::Tools::PerlCritic;
use Test2::Require::Module 'Perl::Critic';
use Perl::Critic;
use Test2::Require::Module 'Perl::Critic::Freenode';

my $critic = Perl::Critic->new( -profile => 't/perlcriticrc', );

perl_critic_ok [ 'lib', 't', 'examples' ], $critic;

done_testing;
