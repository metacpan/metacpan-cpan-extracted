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
