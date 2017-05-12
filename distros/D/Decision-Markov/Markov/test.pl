#!/usr/bin/perl -w

# We test this in the top-level test.pl, so this is minimal.

use Test::Simple tests => 1;
use strict;

use Decision::Markov::State;
ok(1, "Can use Decision::Markov::State, but you won't");

