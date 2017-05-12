#!/usr/bin/perl -w

use strict;
use FindBin;
use Test::More tests => 2;

use lib "$FindBin::Bin/../perllib";

use_ok($_) foreach qw(Games::Affenspiel Games::Affenspiel::Board);
