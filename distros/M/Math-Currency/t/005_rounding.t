use Test::More qw(no_plan);

BEGIN { use_ok('Math::Currency'); }

# For subsequent testing, we need to make sure that format is default US
Math::Currency->format('USD');

# testing the extended precision code
# suggested by Brian Phillips <brianp@holmescorp.com>
{

    # make sure we know what rounding mode we are testing
    local $Math::Currency::round_mode = 'even';
    my $test;
    my $mc = Math::Currency->new('5');
    is( "$mc",         '$5.00', 'hides extended precision (overloaded "")' );
    is( $mc->bstr,     '$5.00', 'hides extended precision (bstr)' );
    is( $mc->as_float, '5.00',  'hides extended precision (as_float)' );
    $test = $mc / 8;
    is( $test, '$0.62', 'hides extended precision, rounding works' );
    $test = $mc / 8 * 8;    # power of two
    is( $test, '$5.00', "no preliminary rounding" );
    $test = $mc / 11 * 11;    # try to get repeated decimal fraction
    is( $test, '$5.00', "no preliminary rounding" );
}
