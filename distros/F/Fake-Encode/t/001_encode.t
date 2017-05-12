use 5.00503;
use strict;
use Test::Simply tests => 1;
BEGIN {
    if ($] > 5.00503) {
        for (1..1) {
            ok(1, " # PASS $^X @{[__FILE__]}");
        }
        exit;
    }
}

use Fake::Encode;

ok('‚ ' eq Encode::encode('cp932','‚ '), q{'‚ ' eq Encode::encode('cp932','‚ ')});

__END__
