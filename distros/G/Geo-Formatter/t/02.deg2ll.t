use strict;
use Test::Base;
plan tests => 2 * blocks;

use Geo::Formatter;

run {
    my $block           = shift;
    my ($lat,$lng,@opt) = split(/\n/,$block->input);
    my ($elat,$elng)    = split(/\n/,$block->expected);

    my %opt = map { my ($key,$val) = split(/,/,$_); ($key => $val) } @opt;

    my ($tlat,$tlng) = format2latlng("degree",$lat,$lng,\%opt);

    is $tlat, $elat;
    is $tlng, $elng;
};

__END__
===
--- input
35
+135
--- expected
35
135
===
--- input
35.000000
+135.000000
--- expected
35
135
===
--- input
35.23456789
+135.0123
--- expected
35.23456789
135.0123
===
--- input
-35.23456789
-135.0123
--- expected
-35.23456789
-135.0123
===
--- input
-35.93456789
-135.0123
--- expected
-35.93456789
-135.0123
