#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use lib 't/lib';
use Test::HT;

ht_test(MultipleChoices => { location => '/test' }, {
    code    => 300,
    reason  => 'Multiple Choices',
    headers => [ Location => '/test' ],
});

ht_test(MovedPermanently => { location => '/test' }, {
    code    => 301,
    reason  => 'Moved Permanently',
    headers => [
        Location => '/test',
    ],
});

ht_test(
    Found => {
        location => '/test',
        additional_headers => [
            Expires => 'Soonish',
        ],
    },
    {
        code    => 302,
        reason  => 'Found',
        headers => [
            Location => '/test',
            Expires  => 'Soonish',
        ],
    },
);

ht_test(SeeOther => { location => '/test' }, {
    code    => 303,
    reason  => 'See Other',
    headers => [
        Location => '/test',
    ],
});

ht_test(303 => { location => '/test' }, {
    code    => 303,
    reason  => 'See Other',
    headers => [
        Location => '/test',
    ],
});

ht_test(
    NotModified => {
        additional_headers => [
            'Expires' => 'Soonish',
        ],
    },
    {
        code      => 304,
        reason    => 'Not Modified',
        as_string => '304 Not Modified',
        body      => undef,
        length    => 0,
        headers   => [
            Expires  => 'Soonish',
        ],
    },
);

ht_test(UseProxy => { location => '/proxy/test' }, {
    code    => 305,
    reason  => 'Use Proxy',
    headers => [
        Location => '/proxy/test',
    ],
});

ht_test(
    TemporaryRedirect => {
        location => '/test',
        additional_headers => [
            'Expires' => 'Soonish'
        ]
    },
    {
        code    => 307,
        reason  => 'Temporary Redirect',
        headers => [
            'Location' => '/test',
            'Expires'  => 'Soonish',
        ],
    },
);

done_testing;
