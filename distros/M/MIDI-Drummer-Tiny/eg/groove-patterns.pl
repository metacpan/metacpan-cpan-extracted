#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper::Compact 'ddc';
use MIDI::Drummer::Tiny::Grooves ();

my $grooves = MIDI::Drummer::Tiny::Grooves->new(return_patterns => 1);

my $set = $grooves->search({ cat => 'house' });
# print ddc $set;

my %pattern = $set->{27}{groove}->();
print ddc \%pattern;