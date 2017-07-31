#!perl -T

use strict;
use warnings;

use utf8;

use Test::More tests => 8;

use lib 't/lib';
use IPC::MorseSignals::TestSuite qw<try init cleanup>;

*IPC::MorseSignals::TestSuite::diag = *Test::More::diag;

sub test {
 my ($desc, @args) = @_;
 my ($res, $speed, $len);
 eval {
  ($res, $speed, $len) = try(@args);
 };
 fail($desc . " (died : $@)") if $@;
 ok($res, $desc . ' (' . $len . ' bits @ ' . $speed . ' bauds)');
}

my @msgs = (
 \(undef, -273, 1.1, 'yes', '¥€$'),
 [ 5, 6 ],
 { hlagh => 1, HLAGH => 2 },
 { x => -3.573 },
);
$msgs[7]->{y} = $msgs[7];

init 6;

for (1 .. @msgs) {
 test 'storable ' . $_ => $msgs[$_-1];
}

cleanup;

