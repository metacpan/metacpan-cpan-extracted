#!perl -T

use strict;
use warnings;
use Test::More;

BEGIN {

    # Count who's installed
    my @order = qw(Cpanel::JSON::XS JSON::XS JSON::PP JSON JSON::DWIW JSON::Syck);
    my $count = scalar grep { eval "require $_"; 1; } @order;

    ok($count, 'have at least one JSON backend installed');

    # we should have installed a backend if one wasn't already present
    use_ok('JSON::Any');
}

diag("Testing JSON::Any $JSON::Any::VERSION, Perl $], $^X");
can_ok( 'JSON::Any', qw(new) );
can_ok( 'JSON::Any', qw(objToJson jsonToObj) );
can_ok( 'JSON::Any', qw(to_json from_json ) );
can_ok( 'JSON::Any', qw(Dump Load ) );
can_ok( 'JSON::Any', qw(encode decode ) );

is( JSON::Any->objToJson( { foo => 'bar' } ), q[{"foo":"bar"}] );

done_testing;
