# encoding: KSC5601
# This file is encoded in KS C 5601.
die "This file is not encoded in KS C 5601.\n" if q{あ} ne "\xa4\xa2";

use KSC5601;
print "1..2\n";

my $__FILE__ = __FILE__;

if (KSC5601::ord('あ') == 0xA4A2) {
    print qq{ok - 1 KSC5601::ord('あ') == 0xA4A2 $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 KSC5601::ord('あ') == 0xA4A2 $^X $__FILE__\n};
}

$_ = 'い';
if (KSC5601::ord == 0xA4A4) {
    print qq{ok - 2 \$_ = 'い'; KSC5601::ord() == 0xA4A4 $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 \$_ = 'い'; KSC5601::ord() == 0xA4A4 $^X $__FILE__\n};
}

__END__
