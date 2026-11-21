#!/usr/bin/env perl
use v5.40;
use MIDI::RtMidi::Util qw(out_port program_changer);

my $port     = shift || 'GP-100';
my $program  = shift || 1;
my $channel  = shift // 0;
my $msb_bank = shift // undef;
my $lsb_bank = shift // undef; # nb: change this value *each* time!

my $device = out_port($port);

program_changer($device, $program - 1, $channel, $msb_bank, $lsb_bank);