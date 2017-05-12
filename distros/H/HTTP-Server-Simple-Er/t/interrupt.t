#!/usr/bin/perl

use warnings;
use strict;

use Test::More qw(no_plan);

# Set an END block and call child_server(), then check that the end
# block did not run and that the child is dead.
my $pid = open(my $fh, '-|', $^X, 't/interrupt.pl') or die "that was no fun";
my @said = <$fh>;

# give the child time to go away :-(
use Time::HiRes (); Time::HiRes::sleep(0.2);

my %data = map({chomp; split(/: /, $_, 2)} @said);
ok($data{child}, 'got child pid') or die "all bets are off here";
my $killed = kill(INT => $data{child});
ok(! $killed, 'child already gone') or die $killed;
ok(! exists($data{END}), 'correctly skipped END');
like($data{warning}, qr/^interrupt/);

# vim:ts=2:sw=2:et:sta
