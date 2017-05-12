#!perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Games::Sudoku::Component::TkPlayer;

Games::Sudoku::Component::TkPlayer->bootstrap;
