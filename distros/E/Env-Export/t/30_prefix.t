#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

# TEST SCOPE: These tests exercise the ":prefix" and ":noprefix" keywords

plan tests => 4;

# First two tests test against this value
$ENV{VALUE} = 'test value';

eval q|
use Env::Export qw(:prefix PRE_ VALUE);

is(PRE_VALUE(), $ENV{VALUE}, "Basic :prefix usage");
|;
warn "eval fail: $@" if $@;

$ENV{VALUE2} = 'second value';
$ENV{VALUE3} = 'third value';
eval q|
use Env::Export qw(:prefix P_ VALUE2 VALUE3 :prefix Q_ VALUE2);

is(P_VALUE3(), $ENV{VALUE3}, "Carry-over of a prefix");
is(P_VALUE2(), Q_VALUE2(), "Changing prefix");
|;
warn "eval fail: $@" if $@;

$ENV{VALUE4} = 'fourth value';
eval q|
use Env::Export qw(:prefix P_ VALUE4 :noprefix VALUE4);

is(P_VALUE4(), VALUE4(), "Turning off a prefix");
|;
warn "eval fail: $@" if $@;

exit;
