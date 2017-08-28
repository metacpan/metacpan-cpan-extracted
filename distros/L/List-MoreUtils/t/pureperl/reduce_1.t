#!perl

use strict ("subs", "vars", "refs");
use warnings ("all");
BEGIN { $ENV{LIST_MOREUTILS_PP} = 1; }
END { delete $ENV{LIST_MOREUTILS_PP} } # for VMS
use lib ("t/lib");
use List::MoreUtils (":all");


use Test::More;
use Test::LMU;

use Scalar::Util qw(looks_like_number);

# (this code shamelessly stolen from Math::Complex's t/Trig.t, with some mods to near) from BBYRD in RT#72638 and taken from SQL-Statement now
use Math::Trig;
my $eps = 1e-11;

if ( $^O eq 'unicos' )
{    # See lib/Math/Complex.pm and t/lib/complex.t.
    $eps = 1e-10;
}

sub near ($$$;$)
{
    my $d = $_[1] ? abs( $_[0] / $_[1] - 1 ) : abs( $_[0] );
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    looks_like_number( $_[0] ) or return cmp_ok( $_[0], "eq", $_[1], "near? $_[0] ~= $_[1]" );
    $_[0] =~ m/nan/i and return cmp_ok( $_[0], "eq", $_[1], "near? $_[0] ~= $_[1]" );
    $_[0] =~ m/inf/i and return cmp_ok( $_[0], "eq", $_[1], "near? $_[0] ~= $_[1]" );
    my $e = defined $_[3] ? $_[3] : $eps;
    cmp_ok( $d, '<', $e, "$_[2] => near? $_[0] ~= $_[1]" ) or diag("near? $_[0] ~= $_[1]");
}

my $half_pi = reduce_1 { $a * ( (4 * $b * $b) / ((2 * $b - 1) * (2 * $b + 1)) ) } 1 .. 750;

near( $half_pi, pi/2, "Wallis product", 1e-2 );

done_testing;


