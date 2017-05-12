use strict;
use Test::Base;
plan tests => 2 * blocks;

use Geo::Formatter;

run {
    my $block           = shift;
    my ($lat,$lng,@opt) = split(/\n/,$block->input);
    my ($elat,$elng)    = split(/\n/,$block->expected);

    my %opt = map { my ($key,$val) = split(/,/,$_); ($key => $val) } @opt;

    my ($tlat,$tlng) = latlng2format("degree",$lat,$lng,\%opt);

    is $tlat, $elat;
    is $tlng, $elng;
};

__END__
===
--- input
35
+135
--- expected
35.000000
135.000000
===
--- input
35.23456789
+135.0123
--- expected
35.234568
135.012300
===
--- input
35.23456789
+135.0123
sign,1
--- expected
+35.234568
+135.012300
===
--- input
-35.23456789
-135.0123
under_decimal,2
--- expected
-35.23
-135.01
===
--- input
-35.93456789
-135.0123
under_decimal,0
--- expected
-36
-135

