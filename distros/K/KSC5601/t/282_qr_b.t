# encoding: KSC5601
# This file is encoded in KS C 5601.
die "This file is not encoded in KS C 5601.\n" if q{ㄲ} ne "\xa4\xa2";

use strict;
use KSC5601;
print "1..4\n";

my $__FILE__ = __FILE__;

if ('、⇒' =~ qr'⇔') {
    print qq{not ok - 1 '、⇒' =~ qr'⇔' $^X $__FILE__\n};
}
else {
    print qq{ok - 1 '、⇒' =~ qr'⇔' $^X $__FILE__\n};
}

if ('、⇒' =~ qr'⇔'b) {
    print qq{ok - 2 '、⇒' =~ qr'⇔'b $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 '、⇒' =~ qr'⇔'b $^X $__FILE__\n};
}

if ('、⇒' =~ qr'⇔'i) {
    print qq{not ok - 3 '、⇒' =~ qr'⇔'i $^X $__FILE__\n};
}
else {
    print qq{ok - 3 '、⇒' =~ qr'⇔'i $^X $__FILE__\n};
}

if ('、⇒' =~ qr'⇔'ib) {
    print qq{ok - 4 '、⇒' =~ qr'⇔'ib $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 '、⇒' =~ qr'⇔'ib $^X $__FILE__\n};
}

__END__

