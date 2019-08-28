# encoding: GBK
# This file is encoded in GBK.
die "This file is not encoded in GBK.\n" if q{偁} ne "\x82\xa0";

use GBK;
print "1..1\n";

$_ = '';

# unmatched [ ] in regexp
# 乽惓婯昞尰偵儅僢僠偟側偄 [ ] 偑偁傞乿
eval { /僾乕儖/ };
if ($@) {
    print "not ok - 1 eval { /PUURU/ }\n";
}
else {
    print "ok - 1 eval { /PUURU/ }\n";
}

__END__

Shift-JIS僥僉僗僩傪惓偟偔埖偆
http://homepage1.nifty.com/nomenclator/perl/shiftjis.htm
