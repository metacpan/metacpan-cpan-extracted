use warnings;
use strict;

use Geo::Compass::Variation qw(mag_dec);
use Test::More;

my $year;
(undef, undef, undef, undef, undef, $year) = localtime;
$year += 1900;

my @t = (51.0486, -114.0708, 1100, $year);

my $ok = eval {
    mag_dec(@t);
    1;
};

is $ok, 1, "new WWM data not yet available";

$ok = eval {
    mag_dec(10, 10, 0, 2015);
    1;
};

is $ok, 1, "2015 is a valid year";

$ok = eval {
    mag_dec(10, 10, 0, 2019);
    1;
};

is $ok, 1, "2019 is a valid year";

$ok = eval {
    mag_dec(10, 10, 0, 2014);
    1;
};

is $ok, undef, "fail prior to 2015";

$ok = eval {
    mag_dec(10, 10, 0, 2020);
    1;
};

is $ok, undef, "fail after 2019";
like $@, qr/Calculation model has expired:/, "error is sane";

$ok = eval {
    mag_dec(10, 10, 0, 2020);
    1;
};

is $ok, undef, "fail after 2018.9";
like $@, qr/Calculation model has expired:/, "error is sane";

done_testing;

