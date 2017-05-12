use strict;
use warnings;
use Test::More tests => 14;

use HTTP::Headers;
use HTTP::Request::StreamingUpload;

do {
    my $req = HTTP::Request::StreamingUpload->new(
        PUT => 'http://localhost/',
        headers => {
            Foo => 'Bar',
            Bar => 'Baz',
        },
    );
    isa_ok $req, 'HTTP::Request';
    is $req->method, 'PUT', 'method';
    is $req->uri, 'http://localhost/', 'uri';
    is($req->header('Foo'), 'Bar', 'Foo header');
    is($req->header('Bar'), 'Baz', 'Bar header');
};

do {
    my $req = HTTP::Request::StreamingUpload->new(
        PUT => 'http://localhost/',
        headers => [
            Foo => 'Bar',
            Foo => 'Baz',
        ],
    );
    isa_ok $req, 'HTTP::Request';
    is $req->method, 'PUT', 'method';
    is $req->uri, 'http://localhost/', 'uri';
    is($req->header('Foo'), 'Bar, Baz', 'Foo header');
};

do {
    my $req = HTTP::Request::StreamingUpload->new(
        PUT => 'http://localhost/',
        headers => HTTP::Headers->new(
            Foo  => 'Bar',
            Foo  => 'Baz',
            Hoge => 'Huga',
        ),
    );
    isa_ok $req, 'HTTP::Request';
    is $req->method, 'PUT', 'method';
    is $req->uri, 'http://localhost/', 'uri';
    is($req->header('Foo'), 'Bar, Baz', 'Foo header');
    is($req->header('Hoge'), 'Huga', 'Hoge header');
};
