#!/usr/bin/perl -T
use Lingua::HU::Numbers qw/num2hu num2hu_ordinal/;
use Test::More tests => 52;
use utf8;

### num2hu
## integers [1-12]
is (num2hu(0), "nulla");
is (num2hu(12), "tizenkettő");
is (num2hu(100), "száz");
is (num2hu(1000), "ezer");
is (num2hu(1999), "ezerkilencszázkilencvenkilenc");
is (num2hu(2001), "kettőezer-egy");
is (num2hu(2110), "kettőezer-egyszáztíz");
is (num2hu(5000), "ötezer");
is (num2hu(123000),"százhuszonháromezer");
is (num2hu(1000000),"egymillió");
is (num2hu(1001000), "egymillió-ezer");
is (num2hu('999000000000000000000000000000000000000000000000000000000000000'),
	"kilencszázkilencvenkilenc decillió");

## -+ signs [13-18]
is (num2hu('-1100'), "mínusz ezeregyszáz");
is (num2hu('-21000'), "mínusz huszonegyezer");
is (num2hu('+1111'), "ezeregyszáztizenegy");
is (num2hu('+23000'), "huszonháromezer");
is (num2hu('-0'), "nulla");
is (num2hu('+0'), "nulla");

## real numbers [19-25]

is (num2hu('1.5'), "egy egész öt tized");
is (num2hu('2001.2005'), "kettőezer-egy egész kettőezer-öt tízezred");
is (num2hu('11.10'), "tizenegy egész egy tized");
is (num2hu('20.101'), "húsz egész százegy ezred");
is (num2hu('120.000'), "százhúsz");
is (num2hu('99.010'), "kilencvenkilenc egész egy század");
is (num2hu('0.0101'), "nulla egész százegy tízezred");

## combined cases [26-27]
is (num2hu('+0.0'), "nulla");
is (num2hu('-0.010'),"mínusz nulla egész egy század");

## formatting errors [28-31]

ok (! eval("num2hu('0.')") && $@);
ok (! eval("num2hu('0,')") && $@);
ok (! eval("num2hu('text')") && $@);
ok (! eval('$_="1" x 67;num2hu($_)') && $@);

### num2hu_ordinal

## integers [32-47]

is (num2hu_ordinal(0), "nulladik");
is (num2hu_ordinal(1), "első");
is (num2hu_ordinal(10),"tizedik");
is (num2hu_ordinal(100),"századik");
is (num2hu_ordinal(11), "tizenegyedik");
is (num2hu_ordinal(25), "huszonötödik");
is (num2hu_ordinal(38), "harmincnyolcadik");
is (num2hu_ordinal(120), "százhuszadik");
is (num2hu_ordinal(1000), "ezredik");
is (num2hu_ordinal(1300), "ezerháromszázadik");
is (num2hu_ordinal(2538), "kettőezer-ötszázharmincnyolcadik");
is (num2hu_ordinal(26000), "huszonhatezredik");
is (num2hu_ordinal(26438), "huszonhatezer-négyszázharmincnyolcadik");
is (num2hu_ordinal(100000), "százezredik");
is (num2hu_ordinal(10**6), "egymilliomodik");
is (num2hu_ordinal(15345678),
	"tizenötmillió-háromszáznegyvenötezer-hatszázhetvennyolcadik");
is (num2hu_ordinal(199000000), "százkilencvenkilencmilliomodik");
is (num2hu_ordinal(199000999),
	"százkilencvenkilencmillió-kilencszázkilencvenkilencedik");

## formatting [50-52]

ok (! eval('num2hu_ordinal("text")') && $@);
ok (! eval('num2hu_ordinal("0.0")') && $@);
ok (! eval('$_="1" x 67;num2hu_ordinal($_)') && $@);
