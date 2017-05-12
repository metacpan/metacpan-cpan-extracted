use strict;
use Test::Base;
plan tests => 2 * blocks;

use Geo::Formatter;

alias_format("degree8","degree",{encode=>{under_decimal => 8}});
alias_format("mapion","dms",{encode=>{devider=>"/",zerofill=>1},decode=>{devider=>"/"}});
alias_format("mapion2","dms",{devider=>"/",zerofill=>1});
alias_format("gpsone","dms",{encode=>{under_decimal => 2}});

run {
    my $block           = shift;
    my ($format,$dir,$lat,$lng,@opt) 
                        = split(/\n/,$block->input);
    my ($elat,$elng)    = split(/\n/,$block->expected);

    my %opt = map { my ($key,$val) = split(/,/,$_); ($key => $val) } @opt;

    my ($tlat,$tlng) = $dir eq "encode" ?
                       latlng2format($format,$lat,$lng,\%opt) :
                       format2latlng($format,$lat,$lng,\%opt);

    is $tlat, $elat;
    is $tlng, $elng;
};

__END__
===
--- input
degree8
encode
35.2345678901
135.0123456789
--- expected
35.23456789
135.01234568
===
--- input
degree8
encode
35.2345678901
135.0123456789
under_decimal,1
--- expected
35.2
135.0
===
--- input
degree8
decode
35.2345678901
135.0123456789
--- expected
35.2345678901
135.0123456789
===
--- input
mapion
encode
35.2345678901
135.0123456789
--- expected
35/14/04.444
135/00/44.444
===
--- input
mapion
decode
35/14/04.444
135/00/44.444
--- expected
35.2345677777778
135.012345555556
===
--- input
mapion2
encode
35.2345678901
135.0123456789
--- expected
35/14/04.444
135/00/44.444
===
--- input
mapion2
decode
35/14/04.444
135/00/44.444
--- expected
35.2345677777778
135.012345555556
===
--- input
gpsone
encode
35.2345678901
135.0123456789
--- expected
35.14.4.44
135.0.44.44
===
--- input
gpsone
decode
35.14.4.444
135.0.44.444
--- expected
35.2345677777778
135.012345555556
