#!perl -T

use strict;
use warnings;

use Test::More tests => 7;

use lib 't/lib';
use IPC::MorseSignals::TestSuite qw/try init cleanup/;

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

my @msgs = qw/hlagh hlaghlaghlagh HLAGH HLAGHLAGHLAGH \x{0dd0}\x{00}
              h\x{00}la\x{00}gh \x{00}\x{ff}\x{ff}\x{00}\x{00}\x{ff}/;

init 6;

for (1 .. @msgs) {
 test 'plain ' . $_ => $msgs[$_-1];
}

cleanup;

