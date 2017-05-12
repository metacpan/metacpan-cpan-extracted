use strict;
use warnings;

use Test::More;
use EV;
use EV::Cron;

my $count = 1;
plan(tests => $count + 1);

my @watchers;
push @watchers, EV::cron '* * * * *', sub { pass('callback'); EV::break unless --$count; };
EV::run;

ok(1);

