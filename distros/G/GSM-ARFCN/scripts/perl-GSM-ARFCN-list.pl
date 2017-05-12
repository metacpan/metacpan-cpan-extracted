#!/usr/bin/perl

=head1 NAME

perl-GSM-ARFCN-list.pl - List all known channels with band, uplink and downlink frequencies,

=cut

use strict;
use warnings;
use GSM::ARFCN;
my $ga=GSM::ARFCN->new;
foreach my $channel (0..124,128..251,259..293,306..340,350..425,438..511,512..885,955..1023) {
  $ga->channel($channel);  #sets channel and recalculates the object properties
  printf "Channel: %s;\tBand: %s\tUplink: %s MHz,\tDownlink: %s MHz\n", $ga->channel, $ga->band, $ga->ful, $ga->fdl;
}
