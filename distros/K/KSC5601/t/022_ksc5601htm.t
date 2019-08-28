# encoding: KSC5601
# This file is encoded in KS C 5601.
die "This file is not encoded in KS C 5601.\n" if q{ㄲ} ne "\xa4\xa2";

use KSC5601;
print "1..1\n";

# ⅷι【ㅛㅟㅚㅹㅚㄴㅁㅙ訶샙꼍ㅁㅉㅻÅ５￠
if (lc('ⅱⅳⅵⅷⅹ') eq 'ⅱⅳⅵⅷⅹ') {
    print "ok - 1 lc('ⅱⅳⅵⅷⅹ') eq 'ⅱⅳⅵⅷⅹ'\n";
}
else {
    print "not ok - 1 lc('ⅱⅳⅵⅷⅹ') eq 'ⅱⅳⅵⅷⅹ'\n";
}

__END__

KSC5601.pm ㅞ썼果룸꽐ㄼ걺꼈ㅛㅚㅻㅃㅘㆂ덟쫠ㅇㅖㄴㅻ

if (lc('ⅱⅳⅵⅷⅹ') eq 'ⅱⅳⅵⅷⅹ') {

Shift-JISΖ��ⅩΘㆂ윳ㅇㄿ갬ㄶ
http://homepage1.nifty.com/nomenclator/perl/shiftjis.htm
