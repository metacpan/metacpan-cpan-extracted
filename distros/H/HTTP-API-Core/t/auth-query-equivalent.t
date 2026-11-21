use strict;
use warnings;
use utf8;
use Test::More;

use HTTP::API::Core;
use HTTP::API::Core::Auth qw(api_key_auth);

sub attach_key {
    my ($name, $url) = @_;
    my $hook = api_key_auth(
        in    => 'query',
        name  => $name,
        value => 'new secret',
    );
    my $ctx = { url => $url, headers => {} };
    $hook->($ctx);
    return $ctx->{url};
}

for my $case (
    ['api/key', '/items?api%2fkey=existing#section',
        'lowercase hex escape matches canonical encoded name'],
    ['api/key', '/items?api%2Fkey=existing',
        'uppercase hex escape matches canonical encoded name'],
    ['api_key', '/items?%61pi_key=existing',
        'percent-encoded unreserved ASCII matches raw name'],
    ['api_key', '/items?api%5fkey=existing',
        'encoded underscore matches the literal underscore'],
    ['api_key', '/items?api_key',
        'bare query parameter without equals is already present'],
    ['api_key', '/items?other=1&api_key#section',
        'bare query parameter after another parameter is recognized'],
    ['api_key', '/items?api_key=existing=with-equals#section',
        'equals signs inside a value do not change the key'],
    ['api_é', '/items?api_%c3%a9=existing#section',
        'lowercase UTF-8 escapes match an encoded non-ASCII name'],
) {
    my ($name, $url, $description) = @$case;
    is attach_key($name, $url), $url,
        "$description; existing URL is unchanged";
}

is(
    attach_key('api_key', '/items?API_KEY=existing'),
    '/items?API_KEY=existing&api_key=new%20secret',
    'query parameter names remain case-sensitive',
);
is(
    attach_key('api_key', '/items?api_key_extra=existing'),
    '/items?api_key_extra=existing&api_key=new%20secret',
    'a longer parameter name is not an existing credential',
);
is(
    attach_key('api_key', '/items?other=api_key%3Dexisting#api_key=fragment'),
    '/items?other=api_key%3Dexisting&api_key=new%20secret#api_key=fragment',
    'matching text in values or fragment is not mistaken for a key',
);
is(
    attach_key('api_key', '/api_key#api_key=fragment'),
    '/api_key?api_key=new%20secret#api_key=fragment',
    'matching text in path or fragment is not a query parameter',
);
is(
    attach_key('api/key', '/items?other=1#section'),
    '/items?other=1&api%2Fkey=new%20secret#section',
    'missing key still appends the canonical percent-encoded name',
);

my @seen;
my $api = HTTP::API::Core->new(
    base_url => 'https://api.example.test',
    hooks => {
        before_request => api_key_auth(
            in => 'query', name => 'api/key', value => 'new secret',
        ),
    },
    transport => sub {
        my ($method, $url) = @_;
        push @seen, [$method, $url];
        return { status => 200, headers => {}, content => '{}' };
    },
);
is(
    $api->get('/items?api%2fkey=explicit#section')->status,
    200,
    'core request succeeds with already encoded explicit API-key name',
);
is(
    $seen[0][1],
    'https://api.example.test/items?api%2fkey=explicit#section',
    'transport receives the original explicit credential exactly once',
);
is(
    $api->get('/items?other=1')->status,
    200,
    'subsequent requests without an explicit key succeed',
);
is(
    $seen[1][1],
    'https://api.example.test/items?other=1&api%2Fkey=new%20secret',
    'subsequent request appends the configured key without stale URL state',
);

done_testing;
