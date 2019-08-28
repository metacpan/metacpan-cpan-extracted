# encoding: KSC5601
# This file is encoded in KS C 5601.
die "This file is not encoded in KS C 5601.\n" if q{ㄲ} ne "\xa4\xa2";

use KSC5601;
print "1..1\n";

my $__FILE__ = __FILE__;

# s///g
$a = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";

if ($a =~ s/CD|JK|UV/ㄲㄴㄶ/g) {
    if ($a eq "ABㄲㄴㄶEFGHIㄲㄴㄶLMNOPQRSTㄲㄴㄶWXYZ") {
        print qq{ok - 1 \$a =~ s/CD|JK|UV/ㄲㄴㄶ/g ($a) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 1 \$a =~ s/CD|JK|UV/ㄲㄴㄶ/g ($a) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 1 \$a =~ s/CD|JK|UV/ㄲㄴㄶ/g ($a) $^X $__FILE__\n};
}

__END__
