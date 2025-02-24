BEGIN {
    if ("$]" == 5.008009 or "$]" == 5.010000 or "$]" <= 5.006002) {
        print "1..0 # Skip: known to fail on $]\n";
        exit 0;
    }
}

use strict;
use warnings;

use List::Util::PP qw(reduce);
use Test::More tests => 1;

my $ret = "original";
$ret = $ret . broken();
is($ret, "originalreturn");

sub broken {
    reduce { return "bogus"; } qw/some thing/;
    return "return";
}
