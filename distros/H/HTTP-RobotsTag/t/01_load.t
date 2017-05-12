use strict;
use Test::More;

my @modules = qw(HTTP::RobotsTag HTTP::RobotsTag::Rules);
plan tests => scalar @modules;

use_ok($_) for @modules;