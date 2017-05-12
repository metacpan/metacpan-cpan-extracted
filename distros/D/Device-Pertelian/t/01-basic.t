#! /usr/bin/perl -w

use Test::NoWarnings;
use Test::More qw/no_plan/;

use Device::Pertelian;

my $buf;
my $pert = new Device::Pertelian \$buf;

can_ok($pert, qw/writeline clearscreen/);
# backlight etc.

ok($pert->clearscreen);
ok($pert->writeline(0, "Hello, world!"));
