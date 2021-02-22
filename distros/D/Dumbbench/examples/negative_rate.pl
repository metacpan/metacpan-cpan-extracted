#!/usr/bin/env perl
use strict;
use warnings;

use lib qw(lib);

use Benchmark::Dumb qw(:all);
# use Benchmark qw(:all :hireswallclock);
use Time::HiRes qw(sleep);

cmpthese 0, {
    fast => sub { return 1 },
    slow => sub { sleep 0.001; return 1 },
};
