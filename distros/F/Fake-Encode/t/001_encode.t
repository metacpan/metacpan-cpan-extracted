use 5.00503;
use strict;
BEGIN { $|=1; print "1..1\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" }}
use FindBin;
use lib "$FindBin::Bin/../lib";
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
