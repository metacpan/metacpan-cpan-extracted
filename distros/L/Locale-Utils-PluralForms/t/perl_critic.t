#!perl -T

use strict;
use warnings;

use English qw(-no_match_vars $EVAL_ERROR);
use Test::More;

eval 'use Test::Perl::Critic -severity => 1';
plan skip_all => "Test::Perl::Critic required" if $EVAL_ERROR;

$ENV{TEST_AUTHOR}
or plan skip_all => 'Author test. Set $ENV{TEST_AUTHOR} to a true value to run.';

all_critic_ok( qw{
    lib
    example
} );
