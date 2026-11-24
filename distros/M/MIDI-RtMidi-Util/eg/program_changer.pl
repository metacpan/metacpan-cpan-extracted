#!/usr/bin/env perl
use v5.40;
use MIDI::RtMidi::Util qw(out_port program_changer);

my $port     = shift || 'GP-100';
my $program  = shift // 0;
my $channel  = shift // 0;
my $msb_bank = shift // undef;
my $lsb_bank = shift // undef;

my $device = out_port($port);

program_changer($device, $program, $channel, $msb_bank, $lsb_bank);