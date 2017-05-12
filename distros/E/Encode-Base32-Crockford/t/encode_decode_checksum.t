#!/usr/bin/perl

use warnings;
use strict;

use constant MAX => 1024;
use Test::More tests => MAX + 1;

use Encode::Base32::Crockford qw(:all);

for my $num(0 .. MAX) {
  is(base32_decode_with_checksum(base32_encode_with_checksum($num)), $num, "check encode, decode $num");
}
