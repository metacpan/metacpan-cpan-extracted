#!/usr/bin/perl -w

use Test::More tests => 17;
use Test::NoWarnings;
use Mac::Alias::Parse;
use Unicode::Normalize qw(NFC NFD);

#  Grab some normally-not-exported fns for testing
*packLongTime = *Mac::Alias::Parse::packLongTime;
*unpackLongTime = *Mac::Alias::Parse::unpackLongTime;

sub roundtripUC {
    my($p, $u, $descr) = @_;
    
    my($pu) = Mac::Alias::Parse::unpackUC($p);
    is(NFC($pu), NFC($u), "unpack $descr");

    my($up) = Mac::Alias::Parse::packUC($u);
    is($up, $p, "pack $descr");
}

&roundtripUC("\x00\x05\x00\x55\x00\x73\x00\x65\x00\x72\x00\x73", 'Users', 'simple unicode str');
&roundtripUC("\x00\x00", '', 'empty unicode str');
&roundtripUC("\x00\x0a\x00\x74\x00\x65\x00\x73\x00\x74\x00\x66\x00\x69\x03\x01\x00\x6c\x00\x65\x00\x31",
             "testf\N{U+00ED}le1", 'latin unicode str');


is("\0"x8, packLongTime(0), "pack time 0");
cmp_ok(0, '==', unpackLongTime("\0"x8), "unpack time 0");

is("\x00\x00\xcd\x14\x0e\x60\x00\x00", packLongTime(3440643680), "pack time med");
cmp_ok(3440643680, '==', unpackLongTime("\x00\x00\xcd\x14\x0e\x60\x00\x00"), "unpack time med");

is("\x00\x00\xcd\x14\x0e\x60\x20\x00", packLongTime(3440643680.125), "pack time frac");
cmp_ok(3440643680.125, '==', unpackLongTime("\x00\x00\xcd\x14\x0e\x60\x20\x00"), "unpack time frac");

cmp_ok(140879597152, '==', unpackLongTime("\x00\x20\xcd\x14\x0e\x60\x00\x00"), "unpack time big");
cmp_ok(140879597152.25, '==', unpackLongTime("\x00\x20\xcd\x14\x0e\x60\x40\x00"), "unpack time big frac");

TODO: {
      local $TODO = "48-bit time packing not finished";

      is("\x00\x20\xcd\x14\x0e\x60\x00\x00", packLongTime(140879597152),
         "pack time big");
      is("\x00\x20\xcd\x14\x0e\x60\x40\x00", packLongTime(140879597152.25),
         "pack time big frac");
}

