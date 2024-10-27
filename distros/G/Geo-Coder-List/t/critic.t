#!perl -w

use strict;
use warnings;

use Test::DescribeMe qw(author);
use File::Spec;
use Test::Most;
use Test::Needs 'Test::Perl::Critic';
use English qw(-no_match_vars);

Test::Perl::Critic::all_critic_ok();
