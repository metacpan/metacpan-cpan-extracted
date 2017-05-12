package StdTests;
use v5.14;
use PlackTest;
use HTTP::Request::Common;
use Device::WebIO::Dancer;
use Device::WebIO;
use JSON;
use Test::More;

use constant TEST_COUNT => 12;


sub run
{
    my ($class, $dev) = @_;
    plan tests => TEST_COUNT;

    my $webio = Device::WebIO->new;
    $webio->register( 'foo', $dev );

    my $test = PlackTest->get_plack_test( $webio, 'foo' );

    $class->run_gpio_tests( $test );
}


sub run_gpio_tests
{
    my ($class, $test) = @_;

    my $res = $test->request( GET "/GPIO/17/function" );
    cmp_ok( $res->content, 'eq', 'in', "Pin 17 is IN by default" );

    my $pin_map = $class->get_pin_map( $test );
    cmp_ok( $pin_map->{GPIO}{17}{function}, 'eq', 'IN', "Pin 17 set in /*" );

    $res = $test->request( POST "/GPIO/17/function/OUT" );
    cmp_ok( $res->code, '==', 200, "Set pin 17 to OUT" );

    $res = $test->request( GET "/GPIO/17/function" );
    cmp_ok( $res->content, 'eq', 'out', "Pin 17 is OUT" );

    $pin_map = $class->get_pin_map( $test );
    cmp_ok( $pin_map->{GPIO}{17}{function}, 'eq', 'OUT', "Pin 17 set in /*" );
    cmp_ok( $pin_map->{GPIO}{17}{value}, '==', 0, "Pin 17 value set in /*" );

    $res = $test->request( GET "/GPIO/17/function" );
    cmp_ok( $res->content, 'eq', 'out', "Pin 17 is still OUT" );

DEBUG: $DB::single = 1;
    $res = $test->request( POST "/GPIO/17/value/1" );
    cmp_ok( $res->code, '==', 200, "Set pin 17 value to 1" );

    $res = $test->request( GET "/GPIO/17/value" );
    cmp_ok( $res->content, '==', 1, "Pin 17 value is 1" );

    $pin_map = $class->get_pin_map( $test );
    cmp_ok( $pin_map->{GPIO}{17}{function}, 'eq', 'OUT', "Pin 17 set in /*" );
    cmp_ok( $pin_map->{GPIO}{17}{value}, '==', 1, "Pin 17 value set in /*" );

    $res = $test->request( GET "/GPIO/17/value" );
    cmp_ok( $res->content, '==', 1, "Pin 17 value is still 1" );
}


sub get_pin_map
{
    my ($class, $test) = @_;
    my $res = $test->request( GET "/*" );
    my $all_data = decode_json( $res->content );
    return $all_data;
}


1;
__END__

