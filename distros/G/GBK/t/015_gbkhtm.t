# encoding: GBK
# This file is encoded in GBK.
die "This file is not encoded in GBK.\n" if q{偁} ne "\x82\xa0";

use GBK;
print "1..1\n";

# 儅僢僠偟側偄偼偢側偺偵儅僢僠偡傞乮侾乯
if ("儎僇儞" =~ /億僢僩/) {
    print qq<not ok - 1 "YAKAN" =~ /POTTO/\n>;
}
else {
    print qq<ok - 1 "YAKAN" =~ /POTTO/\n>;
}

__END__

Shift-JIS僥僉僗僩傪惓偟偔埖偆
http://homepage1.nifty.com/nomenclator/perl/shiftjis.htm
