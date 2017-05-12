use strict;
use warnings;

use Test::More;
my $tests;
plan tests => $tests;

use EV::Cron;

BEGIN { $tests = 2; }

ok(defined $EV::Cron::VERSION);
ok($EV::Cron::VERSION =~ /^\d{1}.\d{6}$/);

BEGIN { $tests += 1; }

can_ok('EV', qw(cron cron_ns));

