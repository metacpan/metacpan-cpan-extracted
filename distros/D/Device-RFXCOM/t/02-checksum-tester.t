##!/usr/bin/perl
#
# Copyright (C) 2010 by Mark Hindess

use strict;
use Test::More tests => 4;

use_ok('Device::RFXCOM::Decoder::Oregon');

my $rf = '2a1d00863000815540031b';
my @n = map { hex $_ } split //, $rf;
my @b = unpack 'C*', pack 'H*', $rf;
eval { Device::RFXCOM::Decoder::Oregon::checksum_tester(\@b,\@n); };
is($@, q{Possible use of checksum, checksum6
($_[1]->[16] + ($_[1]->[19])<<4)) == ( ( nibble_sum(16, $_[1]) - 0xa) & 0xff);
}, 'checksum6');

$rf = '0a4d100a902300002a00';
@n = map { hex $_ } split //, $rf;
@b = unpack 'C*', pack 'H*', $rf;
eval { Device::RFXCOM::Decoder::Oregon::checksum_tester(\@b,\@n); };
is($@, q{Possible use of checksum, checksum2
$_[0]->[8] == ( ( nibble_sum(15, $_[0]) - 0xa) & 0xff)
$_[0]->[8] == ( ( nibble_sum(16, $_[0]) - 0xa) & 0xff);
}, 'checksum2');

$rf = '0a4d100a9023dc0002a0';
@n = map { hex $_ } split //, $rf;
@b = unpack 'C*', pack 'H*', $rf;
eval { Device::RFXCOM::Decoder::Oregon::checksum_tester(\@b,\@n); };
is($@, qq{Could not determine checksum\n}, 'no checksum');
