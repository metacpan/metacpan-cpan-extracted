#!perl

use Test::More tests => 3;

BEGIN { use_ok('Device::USB::MissileLauncher') } # 1

my $ml = Device::USB::MissileLauncher->new();

ok(defined($ml));
ok(exists($ml->{dev})); # 3

$ml->do('left') for (1..3);

for (1..3) {
  $ml->do('up');
  $ml->do('down');
}

$ml->do('up') for (1..2);
$ml->do('right') for (1..3);

$ml->do('fire');

