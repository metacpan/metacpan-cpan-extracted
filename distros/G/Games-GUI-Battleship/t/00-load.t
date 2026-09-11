#!/usr/bin/env perl

use v5.38;
use experimental 'signatures';
use Test2::V0;

use lib 'lib';
use lib '../lib';

use ok 'Games::GUI::Battleship::Ship';
use ok 'Games::GUI::Battleship::Board';
use ok 'Games::GUI::Battleship::Renderer';
use ok 'Games::GUI::Battleship::AI';
use ok 'Games::GUI::Battleship::AI::Naive';
use ok 'Games::GUI::Battleship::AI::Parity';
use ok 'Games::GUI::Battleship';

done_testing;
1;

