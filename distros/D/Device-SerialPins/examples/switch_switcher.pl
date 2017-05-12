#!/usr/bin/perl

use warnings;
use strict;

=head1 Hardware

You'll need some hardware wired to your port like so:

Relays and something to show that they're working

  dtr 4 ---|>|------.
                    |
                    |     ----- + BAT ------.
                    3     \                 |
                    3- - - \  INDICATOR A   |
                    3     |                 |
                    |     ------ LED -------'
  gnd 5 ------------|
                    |
                    |
                    |     ----- + BAT ------.
                    3     \                 |
                    3- - - \  INDICATOR B   |
                    3     |                 |
                    |     ------ LED -------'
  rts 7 ---|>|------'

And some momentary-contact switches.

  car 1  ---.
            |
            \
             \
            |
  rxd 3 ----|----------.
            |     |    |
            \     |    |
             \    |    |
            |     |    |
  dsr 6 ----'     |    |
                  \    |
                   \   |
                  |    |
  cts 8 ----------'    |
                       \
                        \
                       |
  rng 9 ---------------'

This example uses each switch as an off or on signal.  It assumes only
one of each on/off pair will be pressed at any given moment.

=cut

use Device::SerialPins;
use Time::HiRes ();

my $dev = shift(@ARGV) or
  die "need a device argument (e.g. '/dev/ttyS0')";

my $sp = Device::SerialPins->new($dev);
$sp->set_dtr(0);
$sp->set_rts(0);
$sp->set_txd(1); # powers the switches

my %plan = (
  car => [dtr => 1],
  dsr => [dtr => 0],
  cts => [rts => 1],
  rng => [rts => 0],
);

while(1) {
  foreach my $pin (keys(%plan)) {
    if($sp->$pin) {
      print "$pin is on\n";
      $sp->set(@{$plan{$pin}});
    }
  }
  Time::HiRes::sleep(0.005);
}

# vim:ts=2:sw=2:et:sta
