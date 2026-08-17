use strict;
use warnings;
use Test::More;

use HTTP::API::Core;

sub dies_like {
    my ($code, $pattern, $name) = @_;
    my $error;
    eval { $code->(); 1 } or $error = $@;
    like($error, $pattern, $name);
}

# Constructor contract

dies_like(
    sub { HTTP::API::Core->new() },
    qr/base_url is required/,
    'constructor requires base_url',
);

dies_like(
    sub { HTTP::API::Core->new(base_url => 'https://api.example.test', headers => []) },
    qr/headers must be a hash reference/,
    'constructor validates headers',
);

dies_like(
    sub { HTTP::API::Core->new(base_url => 'https://api.example.test', timeout => 0) },
    qr/timeout must be a positive number/,
    'constructor rejects zero timeout',
);

dies_like(
    sub { HTTP::API::Core->new(base_url => 'https://api.example.test', timeout => 'later') },
    qr/timeout must be a positive number/,
    'constructor rejects non-numeric timeout',
);

dies_like(
    sub { HTTP::API::Core->new(base_url => 'https://api.example.test', transport => []) },
    qr/transport must be a code reference or object with request\(\)/,
    'constructor validates transport',
);

dies_like(
    sub { HTTP::API::Core->new(base_url => 'https://api.example.test', mystery => 1) },
    qr/unknown constructor option: mystery/,
    'constructor rejects unknown options',
);

my $api = HTTP::API::Core->new(
    base_url => 'https://api.example.test///',
    retry => { attempts => 2, methods => ['GET'] },
    hooks => {
        before_request => sub { },
    },
    transport => sub {
        my ($method, $url, $options) = @_;
        return {
            status  => 200,
            reason  => 'OK',
            headers => {},
            content => '',
        };
    },
);

is($api->base_url, 'https://api.example.test', 'constructor strips trailing slashes');
is($api->timeout, 10, 'constructor default timeout is stable');

my $retry = $api->retry;
$retry->{attempts} = 99;
push @{ $retry->{methods} }, 'POST';
is($api->retry->{attempts}, 2, 'retry accessor returns a defensive copy');
is_deeply($api->retry->{methods}, ['GET'], 'retry methods are defensively copied');

my $hooks = $api->hooks;
push @{ $hooks->{before_request} }, sub { };
is(scalar @{ $api->hooks->{before_request} }, 1, 'hooks accessor returns a defensive copy');

# request() contract

my @calls;
my $request_api = HTTP::API::Core->new(
    base_url => 'https://api.example.test',
    headers  => { 'X-Default' => 'yes' },
    transport => sub {
        my ($method, $url, $options) = @_;
        push @calls, [$method, $url, $options];
        return {
            status  => 200,
            reason  => 'OK',
            headers => {},
            content => '',
        };
    },
);

$request_api->request('get', '/items', content => 'raw');
is($calls[0][0], 'GET', 'request normalizes method to uppercase');
is($calls[0][1], 'https://api.example.test/items', 'request joins relative path to base URL');
is($calls[0][2]{content}, 'raw', 'request forwards raw content');
is($calls[0][2]{headers}{'X-Default'}, 'yes', 'request includes default headers');

$request_api->post('/json', json => { ok => 1 });
is($calls[1][2]{headers}{'content-type'}, 'application/json', 'json request sets content type');
is($calls[1][2]{headers}{accept}, 'application/json', 'json request sets accept header');
like($calls[1][2]{content}, qr/"ok"\s*:\s*1/, 'json request encodes content');

dies_like(
    sub { $request_api->request('', '/x') },
    qr/method is required/,
    'request requires method',
);

dies_like(
    sub { $request_api->request('GET', undef) },
    qr/path is required/,
    'request requires path',
);

dies_like(
    sub { $request_api->get('/x', query => []) },
    qr/query must be a hash reference/,
    'request validates query',
);

dies_like(
    sub { $request_api->get('/x', mystery => 1) },
    qr/unknown request option: mystery/,
    'request rejects unknown options',
);

done_testing;
