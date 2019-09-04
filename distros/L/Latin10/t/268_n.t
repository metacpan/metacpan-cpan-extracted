# encoding: Latin10
# This file is encoded in Latin-10.
die "This file is not encoded in Latin-10.\n" if q{‚ } ne "\x82\xa0";

use strict;
use Latin10;
print "1..4\n";

my $__FILE__ = __FILE__;

$_ = "A\nBCDEF";

if (/(\N{3})/ and ("<$1>" eq "<BCD>")) {
    print qq{ok - 1 $^X $__FILE__ ($1)\n};
}
else {
    print qq{not ok - 1 $^X $__FILE__ ($1)\n};
}

if (/(\N{3,5})/ and ("<$1>" eq "<BCDEF>")) {
    print qq{ok - 2 $^X $__FILE__ ($1)\n};
}
else {
    print qq{not ok - 2 $^X $__FILE__ ($1)\n};
}

$_ = "A\nBC\nDEF";

if (/(\N{3,})/ and ("<$1>" eq "<DEF>")) {
    print qq{ok - 3 $^X $__FILE__ ($1)\n};
}
else {
    print qq{not ok - 3 $^X $__FILE__ ($1)\n};
}

$_ = "\n\n\nBC\nDEF";

if (/(\N+)/ and ("<$1>" eq "<BC>")) {
    print qq{ok - 4 $^X $__FILE__ ($1)\n};
}
else {
    print qq{not ok - 4 $^X $__FILE__ ($1)\n};
}

__END__
