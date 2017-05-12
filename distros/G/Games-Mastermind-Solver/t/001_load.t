#!/usr/bin/perl -w

use strict;
use Test::More tests => 2;

use_ok( 'Games::Mastermind::Solver' );
use_ok( 'Games::Mastermind::Solver::BruteForce' );
