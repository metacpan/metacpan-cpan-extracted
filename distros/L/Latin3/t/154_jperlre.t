# encoding: Latin3
# This file is encoded in Latin-3.
die "This file is not encoded in Latin-3.\n" if q{ } ne "\x82\xa0";

use Latin3;
print "1..1\n";

my $__FILE__ = __FILE__;

if (' eĤ' =~ /( [^˘¤]Ĥ)/) {
    if ("$1" eq " eĤ") {
        print "ok - 1 $^X $__FILE__ (' eĤ' =~ / [^˘¤]Ĥ/).\n";
    }
    else {
        print "not ok - 1 $^X $__FILE__ (' eĤ' =~ / [^˘¤]Ĥ/).\n";
    }
}
else {
    print "not ok - 1 $^X $__FILE__ (' eĤ' =~ / [^˘¤]Ĥ/).\n";
}

__END__
