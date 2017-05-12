#!/usr/bin/perl -w
#
# Copyright (C) 2007, 2009 by Mark Hindess

use strict;
use t::Helpers qw/:all/;
my %msg;

BEGIN {
  my $case = $ENV{DEVICE_RFXCOM_TESTCASE};
  my $tests = 1;
  my $dir = 't/rf';
  opendir my $dh, $dir or die "Open of $dir directory: $!\n";
  local $/ = "\n\n";
  foreach (sort readdir $dh) {
    next if ($case && !/$case/);
    next if (!/^(.*)\.txt$/);
    my $name = $1;
    my $f = $dir.'/'.$_;
    open my $fh, '<', $f or die "Failed to open $f: $!\n";
    my ($message, $summary, $warn, $rem, $flags) = <$fh>;
    chomp $message;
    $summary =~ s/\n+$//;
    $warn && $warn =~ s/\n+$//;
    $rem && $rem =~ s/\n+$//;
    $flags && chomp $flags;
    $msg{$name} =
      {
       msg => $message,
       summary => $summary,
       warn => $warn,
       rem => $rem || '',
       flags => $flags,
      };
    $tests += 3;
    close $fh;
  }
  closedir $dh;
  require Test::More;
  import Test::More tests => $tests;
}

{
  package My::RX;
  use base 'Device::RFXCOM::RX';
  sub _open {
  }
  sub _init {
  }
  1;
}

my $rf = My::RX->new();
ok($rf, 'instantiated mock device');
foreach my $m (sort keys %msg) {
  my $rec = $msg{$m};
  my $res;
  if ($rec->{flags} && $rec->{flags} =~ s/^pause//) {
    diag "Sleeping to cause timeout\r";
    sleep 1;
  }
  if ($rec->{flags} && $rec->{flags} =~ s/^clear//) {
    # clear unit code cache and try again - trash non-X10 decoders, nevermind
    $_->{unit_cache} = {} foreach (@{$rf->{plugins}});
    $rf->{_cache} = {}; # clear duplicate cache to avoid hitting it
  }

  my $buf = pack "H*", $rec->{msg}.'deadbeef';
  my $w = test_warn( sub { $res = $rf->read_one(\$buf); });
  is((unpack 'H*', $buf), $rec->{rem}.'deadbeef', $m.' - buffer remaining');

  is($w || "none\n", $rec->{warn} ? $rec->{warn}."\n" : "none\n",
     $m.' - test warning');

  is_deeply($res ? $res->summary : '', $rec->{summary},
            $m.' - correct summary');
}
