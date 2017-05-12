#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use English qw(-no_match_vars);

$ENV{TEST_AUTHOR} or plan(
    skip_all => 'Author test. Set (export) $ENV{TEST_AUTHOR} to a true value to run.'
);

eval 'use Test::Kwalitee';

if ( $EVAL_ERROR ) {
    my $msg = 'Test::Kwalitee not installed; skipping';
    plan( skip_all => $msg );
}
