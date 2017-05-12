#!perl

use strict;
use warnings;

use Test::More tests => 4;

use_ok('HTTP::LoadGen::Run');
use_ok('HTTP::LoadGen::Logger');
use_ok('HTTP::LoadGen::ScoreBoard');
use_ok('HTTP::LoadGen');

