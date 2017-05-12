use strict;
use warnings;
use Test::More 0.88;

use Log::Stamper;

$Log::Stamper::GMTIME = 1;

my $GMTIME = 1030429942 - 7*3600;

my $formatter = Log::Stamper->new(
    "yyyy yy yyyy",
    sub {
        my $str = shift;
        $str =~ s/0/X/g;
        return $str;
    }
);

is($formatter->format($GMTIME), "2XX2 X2 2XX2");

done_testing;