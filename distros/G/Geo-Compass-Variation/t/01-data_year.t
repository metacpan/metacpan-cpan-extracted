use warnings;
use strict;

use Geo::Compass::Variation qw(mag_dec);
use Test::More;

use constant {
    REL     => 2020,    # release year
    EXP     => 2024,    # expire year
    BEFORE  => 2026,    # before release
    PAST    => 2019,    # beyond expire
};

my $year;
(undef, undef, undef, undef, undef, $year) = localtime;
$year += 1900;

my @t = (51.0486, -114.0708, 1100, $year);

# new model not available
{
    my $w;
    local $SIG{__WARN__} = sub {$w = shift};
    mag_dec(@t);
    is $w, undef, "new WWM data not yet available";
};

# rel is valid year
{
    my $w;
    local $SIG{__WARN__} = sub {$w = shift};
    mag_dec(10, 10, 0, REL);
    is $w, undef, REL . " is a valid year";
}

# exp is valid year
{
    my $w;
    local $SIG{__WARN__} = sub {$w = shift};
    mag_dec(10, 10, 0, EXP);
    is $w, undef, EXP . " is a valid year";
}

# prior to first year
{
    my $warn;
    local $SIG{__WARN__} = sub {$warn = $_[0];};
    mag_dec(10, 10, 0, BEFORE);
    like $warn, qr/Calculation model is expired/, "fail prior to " . REL;
}

# greater than last year
{
    my $warn;
    local $SIG{__WARN__} = sub {$warn = $_[0];};
    mag_dec(10, 10, 0, PAST);
    like $warn, qr/Calculation model is expired/, "fail after " . EXP;
}

done_testing;

