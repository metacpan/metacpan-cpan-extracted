use strict;
use warnings;

use Test::More 0.88;
use Test::Fatal;
use JSON::Any;

my $has_cpanel = eval { require Cpanel::JSON::XS; 1 };
my $has_json_xs; $has_json_xs = eval { require JSON::XS; 1 } if not $has_cpanel;

plan skip_all => 'Cpanel::JSON::XS nor JSON::XS are installed', 1
    if not $has_cpanel and not $has_json_xs;

{
    $ENV{JSON_ANY_ORDER} = 'CPANEL XS';

    JSON::Any->import();
    is(
        JSON::Any->handlerType,
        ($has_cpanel ? 'Cpanel::' : '') . 'JSON::XS',
        'got the right handlerType',
    );

    my ($json);
    ok( $json = JSON::Any->new(), 'got a JSON::Any object' );
    like(
        exception { $json->encode("dahut") },
        qr/use allow_nonref/,
        'trapped a failure because of a non-reference',
    );

    $ENV{JSON_ANY_CONFIG} = 'allow_nonref=1';
    ok( $json = JSON::Any->new(), 'got another JSON::Any object' );

    is(
        exception { ok( $json->encode("dahut"), 'got the same data back again' ) },
        undef,
        'no failure with config change',
    );

    ok( $json = JSON::Any->new(allow_nonref => 0), 'got another JSON::Any object' );

    like(
        exception { $json->encode("dahut") },
        qr/use allow_nonref/,
        'trapped a failure because the constructor option overrides the environment variable',
    );
}

done_testing;
