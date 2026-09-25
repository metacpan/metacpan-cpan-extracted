package main;
use strict;
use warnings;
require 't/test.pm';

use Test::More;

BEGIN { use_ok('Lemonldap::NG::Handler::Main') }

my $h = 'Lemonldap::NG::Handler::Main';

# Rules are tested against the canonical URI: the path must be decoded and
# normalized like web servers do before routing requests to applications,
# otherwise rules can be bypassed with an encoded URL
my @tests = (

    # URI                                     Canonical URI
    [ '/',          '/' ],
    [ '/mysession', '/mysession' ],
    [ '/index.php', '/index.php' ],

    # Percent-encoded characters
    [ '/mysess%69on', '/mysession' ],
    [ '/my%73ession', '/mysession' ],
    [ '/%6dysession', '/mysession' ],
    [ '/%6Dysession', '/mysession' ],
    [ '/caf%C3%A9',   "/caf\xc3\xa9" ],

    # Encoded slashes and duplicate slashes
    [ '/x%2Fy',        '/x/y' ],
    [ '/%2Fmysession', '/mysession' ],
    [ '//mysession',   '/mysession' ],
    [ '/foo//bar',     '/foo/bar' ],

    # Dot segments
    [ '/./mysession',      '/mysession' ],
    [ '/foo/../mysession', '/mysession' ],
    [ '/a/b/./c/../d',     '/a/b/d' ],
    [ '/..',               '/' ],
    [ '/../foo',           '/foo' ],
    [ '/a/b/',             '/a/b/' ],
    [ '/a/b/..',           '/a/' ],
    [ '/a/b/.',            '/a/b/' ],

    # Query string is not decoded (rules can contain GET parameters)
    [ '/index.php?logout=1',   '/index.php?logout=1' ],
    [ '/foo?url=%2Fbar%20baz', '/foo?url=%2Fbar%20baz' ],
    [ '/f%6Fo?x=%2F',          '/foo?x=%2F' ],

    # Absolute-URI form: applications only see the path
    [ 'http://app.example.com/my%73ession?a=1', '/mysession?a=1' ],
    [ 'http://app.example.com',                 '/' ],
    [ 'http://app.example.com?a=1',             '/?a=1' ],

    # An empty path is "/"
    [ '',     '/' ],
    [ '?a=1', '/?a=1' ],
    [ undef,  '/' ],

    # Invalid escape sequences and '+' are kept as is
    [ '/100%', '/100%' ],
    [ '/a+b',  '/a+b' ],

    # Non absolute paths are not normalized
    [ '*', '*' ],
);

foreach my $t (@tests) {
    is( $h->canonicalUri( $t->[0] ),
        $t->[1],
        'canonicalUri(' . ( defined $t->[0] ? $t->[0] : 'undef' ) . ')' );
}

done_testing( scalar @tests + 1 );    # +1 for use_ok
