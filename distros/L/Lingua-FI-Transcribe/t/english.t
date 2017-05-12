use Lingua::FI::Transcribe;

sub EN {
    return Lingua::FI::Transcribe->English($_[0]);
}

print "1..19\n";

print EN("sauna") eq "sow-nah"    ? "ok 1\n" : "not ok 1\n";
print EN("sisu")  eq "see-soo"    ? "ok 2\n" : "not ok 2\n";
print EN("olut")  eq "aw-loot"    ? "ok 3\n" : "not ok 3\n";
print EN("nokia") eq "naw-kee-ah" ? "ok 4\n" : "not ok 4\n";

print EN("helsingin sanomat") eq "hhehl-seen-geen sah-naw-maht" ?
	"ok 5\n" : "not ok 5\n";
print EN("jarkko hietaniemi") eq "yahrrk-kaw hheeeh-tah-neeeh-mee" ?
	"ok 6\n" : "not ok 6\n";

print EN("tuli")  eq "too-lee"    ? "ok 7\n" : "not ok 7\n";
print EN("tuuli") eq "toooo-lee"  ? "ok 8\n" : "not ok 8\n";
print EN("tulli") eq "tool-lee"   ? "ok 9\n" : "not ok 9\n";

print EN("aa") eq "ahh" ? "ok 10\n" : "not ok 10\n";
print EN("ai") eq "igh" ? "ok 11\n" : "not ok 11\n";
print EN("au") eq "ow"  ? "ok 12\n" : "not ok 12\n";
print EN("ee") eq "ehh" ? "ok 13\n" : "not ok 13\n";
print EN("ei") eq "ey"  ? "ok 14\n" : "not ok 14\n";
print EN("ng") eq "nng" ? "ok 15\n" : "not ok 15\n";
print EN("nk") eq "ng"  ? "ok 16\n" : "not ok 16\n";
print EN("oo") eq "aww" ? "ok 17\n" : "not ok 17\n";
print EN("ou") eq "ow"  ? "ok 18\n" : "not ok 18\n";
print EN("öö") eq "urr" ? "ok 19\n" : "not ok 19\n";

