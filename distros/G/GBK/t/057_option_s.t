# encoding: GBK
# This file is encoded in GBK.
die "This file is not encoded in GBK.\n" if q{偁} ne "\x82\xa0";

use GBK;
print "1..1\n";

my $__FILE__ = __FILE__;

# s///g
$a = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";

if ($a =~ s/CD|JK|UV/偁偄偆/g) {
    if ($a eq "AB偁偄偆EFGHI偁偄偆LMNOPQRST偁偄偆WXYZ") {
        print qq{ok - 1 \$a =~ s/CD|JK|UV/偁偄偆/g ($a) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 1 \$a =~ s/CD|JK|UV/偁偄偆/g ($a) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 1 \$a =~ s/CD|JK|UV/偁偄偆/g ($a) $^X $__FILE__\n};
}

__END__
