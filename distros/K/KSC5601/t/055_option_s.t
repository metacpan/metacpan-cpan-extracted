# encoding: KSC5601
# This file is encoded in KS C 5601.
die "This file is not encoded in KS C 5601.\n" if q{ㄲ} ne "\xa4\xa2";

use KSC5601;
print "1..1\n";

my $__FILE__ = __FILE__;

# s///s
$a = "ABCDEFG\nHIJKLMNOPQRSTUVWXYZ";
if ($a =~ s/FG.HI/ㅅㅇㅉ/s) {
    if ($a eq "ABCDEㅅㅇㅉJKLMNOPQRSTUVWXYZ") {
        print qq{ok - 1 \$a =~ s/FG.HI/ㅅㅇㅉ/s ($a) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 1 \$a =~ s/FG.HI/ㅅㅇㅉ/s ($a) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 1 \$a =~ s/FG.HI/ㅅㅇㅉ/s ($a) $^X $__FILE__\n};
}

__END__
