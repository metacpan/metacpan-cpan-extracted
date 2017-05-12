use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Digest::Haval256')
};

BEGIN {
    my $haval = new Digest::Haval256;
    $haval->add("0123456789");
    my $digest = $haval->hexdigest();
    is("357e2032774abbf5f04d5f1dec665112ea03b23e6e00425d0df75ea155813126",
        $digest);
};

