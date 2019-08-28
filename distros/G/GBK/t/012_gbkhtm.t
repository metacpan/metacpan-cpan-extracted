# encoding: GBK
# This file is encoded in GBK.
die "This file is not encoded in GBK.\n" if q{偁} ne "\x82\xa0";

use GBK;
print "1..1\n";

# Bareword found where operator expected
# 乽棁偺岅偑墘嶼巕偑偁偭偰傎偟偄埵抲偵尒偮偐偭偨乿
if ("<img alt=\"懳墳昞\" height=115 width=150>" eq sprintf('<img alt="%s" height=115 width=150>',pack('C6',0x91,0xce,0x89,0x9e,0x95,0x5c))) {
    print qq<ok - 1 "<img alt="TAIOUHYO" height=115 width=150>"\n>;
}
else {
    print qq<not ok - 1 "<img alt="TAIOUHYO" height=115 width=150>"\n>;
}

__END__

GBK.pm 偺張棟寢壥偑埲壓偵側傞偙偲傪婜懸偟偰偄傞

if ("<img alt=\"懳墳昞\\" height=115 width=150>" eq sprintf('<img alt="%s" height=115 width=150>',pack('C6',0x91,0xce,0x89,0x9e,0x95,0x5c))) {

Shift-JIS僥僉僗僩傪惓偟偔埖偆
http://homepage1.nifty.com/nomenclator/perl/shiftjis.htm
