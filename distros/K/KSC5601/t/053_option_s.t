# encoding: KSC5601
# This file is encoded in KS C 5601.
die "This file is not encoded in KS C 5601.\n" if q{ㄲ} ne "\xa4\xa2";

use KSC5601;
print "1..1\n";

my $__FILE__ = __FILE__;

# s///i
$a = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
if ($a =~ s/JkL/ㄲㄴㄶ/i) {
    if ($a eq "ABCDEFGHIㄲㄴㄶMNOPQRSTUVWXYZ") {
        print qq{ok - 1 \$a =~ s/JkL/ㄲㄴㄶ/i ($a) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 1a \$a =~ s/JkL/ㄲㄴㄶ/i ($a) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 1b \$a =~ s/JkL/ㄲㄴㄶ/i ($a) $^X $__FILE__\n};
}

__END__
