# encoding: GBK
# This file is encoded in GBK.
die "This file is not encoded in GBK.\n" if q{偁} ne "\x82\xa0";

use GBK;
print "1..2\n";

my $__FILE__ = __FILE__;

if (length('偁偄偆偊偍') == 10) {
    print qq{ok - 1 length('偁偄偆偊偍') == 10 $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 length('偁偄偆偊偍') == 10 $^X $__FILE__\n};
}

if (GBK::length('偁偄偆偊偍') == 5) {
    print qq{ok - 2 GBK::length('偁偄偆偊偍') == 5 $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 GBK::length('偁偄偆偊偍') == 5 $^X $__FILE__\n};
}

__END__
