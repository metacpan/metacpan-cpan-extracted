#!perl
use strict;
use warnings;

use Geonode::Free::Proxy;

use Test::More tests => 13;
use Test::Exception;

my $proxy;

$proxy = Geonode::Free::Proxy->new(
    'foobar',
    '127.0.0.1',
    '3128',
    [ 'socks4', 'http', 'socks5', 'https' ]
);

is $proxy->get_id, 'foobar',
'Can get id';

is $proxy->get_host, '127.0.0.1',
'Can get host';

is $proxy->get_port, '3128',
'Can get port';

is_deeply [ $proxy->get_methods ], [ 'socks4', 'http', 'socks5', 'https' ],
'Can get methods';

ok $proxy->can_use_http,
'proxy can use http';

ok $proxy->can_use_socks,
'proxy can use socks';

throws_ok {
    $proxy = Geonode::Free::Proxy->new(
        'foobar',
        q( ),
        '3128',
        [ 'socks4', 'http', 'socks5', 'https' ]
    );
} qr/ERROR/sxm,
'cannot use empty host';

throws_ok {
    $proxy = Geonode::Free::Proxy->new(
        'foobar',
        '127.0.0.1',
        '3128-',
        [ 'socks4', 'http', 'socks5', 'https' ]
    );
} qr/ERROR/sxm,
'port must be a number';

throws_ok {
    $proxy = Geonode::Free::Proxy->new(
        'foobar',
        '127.0.0.1',
        '3128',
        q()
    );
} qr/ERROR/sxm,
'methods must be an array reference';

throws_ok {
    $proxy = Geonode::Free::Proxy->new(
        'foobar',
        '127.0.0.1',
        '3128',
        [ 'http', 'https', 'socks4', 'socks5', 'foo' ]
    );
} qr/ERROR/sxm,
'foo is not a valid method';

throws_ok {
    $proxy = Geonode::Free::Proxy->new(
        'foobar',
        '127.0.0.1',
        '3128',
        [ ]
    );
} qr/ERROR/sxm,
'methods cannot be an empty array';

$proxy = Geonode::Free::Proxy->new(
    'foobar',
    '127.0.0.1',
    '3128',
    [ 'socks4', 'http', 'socks5', 'https' ]
);

Geonode::Free::Proxy::prefer_http();
is $proxy->get_url, 'http://127.0.0.1:3128',
'gets url with preferred http method';

Geonode::Free::Proxy::prefer_socks();
is $proxy->get_url, 'socks://127.0.0.1:3128',
'gets url with preferred socks method';
