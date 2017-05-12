use strict;
use Test::Base;
plan tests => 2 * blocks;

use Geo::Formatter;

run {
    my $block           = shift;
    my ($lat,$lng,@opt) = split(/\n/,$block->input);
    my ($elat,$elng)    = split(/\n/,$block->expected);

    my %opt = map { my ($key,$val) = split(/,/,$_); ($key => $val) } @opt;

    my ($tlat,$tlng) = latlng2format("dms",$lat,$lng,\%opt);

    is $tlat, $elat;
    is $tlng, $elng;
};

__END__
===
--- input
35
135
--- expected
35.0.0.000
135.0.0.000
===
--- input
35.23456789
135.0123
sign,1
--- expected
+35.14.4.444
+135.0.44.280
===
--- input
35.23456789
135.0123
zerofill,1
under_decimal,5
--- expected
35.14.04.44440
135.00.44.28000
--- input
-35.23456789
-135.0123
devider,%
under_decimal,0
--- expected
-35%14%4
-135%0%44


