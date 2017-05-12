#!perl -T

use strict;
use warnings;

use utf8;

use Test::More tests => 5;

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

my @msgs = qw/€éèë 月語 x tata たTÂ/;

init 6;

for (1 .. @msgs) {
 test 'utf8 ' . $_ => $msgs[$_-1];
}

cleanup;

