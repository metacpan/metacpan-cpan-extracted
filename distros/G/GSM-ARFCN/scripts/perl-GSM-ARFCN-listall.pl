#!/usr/bin/perl

=head1 NAME

perl-GSM-ARFCN-listall.pl - List all known channels with band, uplink and downlink frequencies,

=cut

use strict;
use warnings;
use GSM::ARFCN;
my $ga=GSM::ARFCN->new;
foreach my $channel (0..1023) {
  $ga->channel($channel);  #sets channel and recalculates the object properties
  if ($ga->band) {
    printf "Channel: %s;\tBand: %s\tUplink: %s MHz,\tDownlink: %s MHz\n", $ga->channel, $ga->band, $ga->ful, $ga->fdl;
  } else {
    printf "Channel: %s;\tUnknown\n", $ga->channel;
  }
}
