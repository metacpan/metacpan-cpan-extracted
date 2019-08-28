# encoding: KSC5601
# This file is encoded in KS C 5601.
die "This file is not encoded in KS C 5601.\n" if q{ㄲ} ne "\xa4\xa2";

use KSC5601;
print "1..2\n";

my $__FILE__ = __FILE__;

if (KSC5601::ord('ㄲ') == 0xA4A2) {
    print qq{ok - 1 KSC5601::ord('ㄲ') == 0xA4A2 $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 KSC5601::ord('ㄲ') == 0xA4A2 $^X $__FILE__\n};
}

$_ = 'ㄴ';
if (KSC5601::ord == 0xA4A4) {
    print qq{ok - 2 \$_ = 'ㄴ'; KSC5601::ord() == 0xA4A4 $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 \$_ = 'ㄴ'; KSC5601::ord() == 0xA4A4 $^X $__FILE__\n};
}

__END__
