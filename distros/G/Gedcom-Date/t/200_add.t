use strict;
use warnings;

use Gedcom::Date;

use Test::More;

# -------------------

while (<DATA>) {
    chomp;
    my ($d1, $dur, $d2) = split /\s*,\s*/;
    my $gd1 = Gedcom::Date->parse( $d1 );
    $gd1->add( split /\s+/, $dur );
    is( $gd1->gedcom, $d2, "$d1 + $dur = $d2" );
}

done_testing();

__DATA__
21 AUG 2003 , years 1 months 1 days 1   , CAL 22 SEP 2004
AUG 2003    , years 1 months 1 days 1   , CAL SEP 2004
2003        , years 1 months 1 days 1   , CAL 2004
21 AUG 2003 , years 1 months 1          , CAL SEP 2004
21 AUG 2003 , years 1                   , CAL 2004
21 AUG 2003 , days 1                    , CAL 22 AUG 2003
