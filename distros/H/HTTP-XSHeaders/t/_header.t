use strict;
use warnings;

use Test::More;
plan tests => 7;

use HTTP::XSHeaders;
use t::lib::Utils;

sub j { join('|', @_) }

my $h = HTTP::XSHeaders->new;

$h->push_header('key1', 'value1-1');
$h->push_header('key2', 'value2-1');
$h->push_header('key2', 'value2-2');

is_deeply(
    [ $h->header('key0' ) ],
    [],
    'inexistent key',
);

is_deeply(
    [ $h->_header('key1') ],
    [ 'value1-1' ],
    'single-valued key',
);

is_deeply(
    [ $h->_header('key2') ],
    [ 'value2-1', 'value2-2' ],
    'multi-valued key',
);

like(
    t::lib::Utils::_try(sub { HTTP::XSHeaders::_header() }),
    qr/\QUsage: HTTP::XSHeaders::_header\E/,
    'HTTP::XSHeaders::_header() without args',
);

like(
    t::lib::Utils::_try(sub { HTTP::XSHeaders::_header(undef) }),
    qr/\Qis not an instance of HTTP::XSHeaders\E/,
    'HTTP::XSHeaders::_header() with undef',
);

like(
    t::lib::Utils::_try(sub { $h->_header() }),
    qr/\Q_header not called with one argument\E/,
    '_header() without args',
);

like(
    t::lib::Utils::_try(sub { $h->_header(undef) }),
    qr/\Q_header not called with one string argument\E/,
    '_header() with undef',
);

done_testing;
