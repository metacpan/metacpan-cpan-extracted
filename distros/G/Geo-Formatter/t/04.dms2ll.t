use strict;
use Test::Base;
plan tests => 2 * blocks;

use Geo::Formatter;

run {
    my $block           = shift;
    my ($lat,$lng,@opt) = split(/\n/,$block->input);
    my ($elat,$elng)    = split(/\n/,$block->expected);

    my %opt = map { my ($key,$val) = split(/,/,$_); ($key => $val) } @opt;

    my ($tlat,$tlng) = format2latlng("dms",$lat,$lng,\%opt);

    is $tlat, $elat;
    is $tlng, $elng;
};

__END__
===
--- input
35.0.0.000
135.0.0.000
--- expected
35
135
===
--- input
+35.00.00.000
+135.00.00.000
--- expected
35
135
===
--- input
+35.00.00.000
+135.00.00.000
--- expected
35
135
===
--- input
-35/14/04.444404
-135/00/44.280000
devider,/
--- expected
-35.23456789
-135.0123
===
--- input
-35[14[04.444404
-135[00[44.280000
devider,[
--- expected
-35.23456789
-135.0123
