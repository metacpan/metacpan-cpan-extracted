print "1..16\n";

use Lingua::FI::Hyphenate 'tavuta';

print "ok 1\n";

print "ok 2\n" if join(" ", tavuta("tavuta")) eq "ta vu ta";
print "ok 3\n" if join(" ", tavuta("kasvis")) eq "kas vis";
print "ok 4\n" if join(" ", tavuta("huutaa")) eq "huu taa";
print "ok 5\n" if join(" ", tavuta("saarni")) eq "saar ni";
print "ok 6\n" if join(" ", tavuta("ansa")) eq "an sa";
print "ok 7\n" if join(" ", tavuta("apu")) eq "a pu";
print "ok 8\n" if join(" ", tavuta("aave")) eq "aa ve";
print "ok 9\n" if join(" ", tavuta("turska")) eq "turs ka";
print "ok 10\n" if join(" ", tavuta("uistin")) eq "uis tin";
print "ok 11\n" if join(" ", tavuta("arkku")) eq "ark ku";
print "ok 12\n" if join(" ", tavuta("proto")) eq "pro to";
print "ok 13\n" if join(" ", tavuta("sanoa")) eq "sa no a";
print "ok 14\n" if join(" ", tavuta("kodeissansakaan")) eq "ko deis san sa kaan";
print "ok 15\n" if join(" ", tavuta("sanomattomuudellaanko")) eq "sa no mat to muu del laan ko";
print "ok 16\n" if join(" ", tavuta("alavilla mailla hallan vaara")) eq "a la vil la mail la hal lan vaa ra";

