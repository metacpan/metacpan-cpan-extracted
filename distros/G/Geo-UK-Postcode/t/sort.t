# sort.t

use Test::Most;

use List::Util qw/ shuffle /;
use Geo::UK::Postcode qw/ pc_sort /;

use lib 't/lib';
use TestGeoUKPostcode;

sub pc {
    eval { Geo::UK::Postcode->new(shift) };
}

note 'as sort method with $a,$b';

my @pcs = grep {defined} map { pc($_) } TestGeoUKPostcode->test_pcs_raw();

my @unsorted = shuffle @pcs;

my @sorted = sort pc_sort @unsorted;

my @expected = (    #
    "A1 1AA",
    "A1A 1AA",
    "A11 1AA",
    "AA1 1AA",
    "AA1A 1AA",
    "AA11 1AA",
    "AB1",
    "AB1 2CD",
    "AB10 1AA",
    "AB10 1II",
    "AB99 1AA",
    "AB99 1AA",
    "B1 1",
    "B11",
    "BF1 1AA",
    "BF1 1AA",
    "BX99 1AA",
    "E2 0HP",
    "N1 0XX",
    "N1P 2NG",
    "QI1 1AA",
    "SE1",
    "SE1",
    "SE1 0LH",
    "WC1H 9",
    "WC1H 9EB",
    "XX1",
    "XX1X",
    "XX1X 1",
    "XX11"
);

is_deeply [ map {"$_"} @sorted ], [@expected], "sorted correctly";

note "as method with arguments";

is pc_sort( pc("AB10 1AA"), pc("AB10 1AA") ), 0,  "match";
is pc_sort( pc("AB10 2AA"), pc("AB10 1AA") ), 1,  "gt";
is pc_sort( pc("AB10 1AA"), pc("AB10 2AA") ), -1, "lt";

done_testing();

