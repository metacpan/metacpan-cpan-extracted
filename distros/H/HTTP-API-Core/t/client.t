use strict;
use warnings;
use Test::More;
use JSON::PP qw(decode_json);
use HTTP::API::Core;

my @calls;
my $api = HTTP::API::Core->new(
    base_url => 'https://api.example.test/',
    headers  => { Authorization => 'Bearer token' },
    timeout  => 5,
    transport => sub {
        my ($method, $url, $opts) = @_;
        push @calls, [$method, $url, $opts];
        return {
            status => 200,
            reason => 'OK',
            headers => { 'Content-Type' => 'application/json', 'X-Request-Id' => 'req-1' },
            content => '{"ok":true,"items":[1,2]}',
        };
    },
);

is $api->base_url, 'https://api.example.test', 'normalizes base url';
is $api->timeout, 5, 'timeout retained';

my $res = $api->post('/items', json => { name => 'Alice' }, headers => { 'X-Test' => 'yes' });
is $res->status, 200, 'status';
ok $res->is_success, 'success';
is_deeply $res->json, { ok => JSON::PP::true, items => [1,2] }, 'JSON decoded';

is $calls[0][0], 'POST', 'method sent';
is $calls[0][1], 'https://api.example.test/items', 'URL joined';
is $calls[0][2]{headers}{Authorization}, 'Bearer token', 'default header';
is $calls[0][2]{headers}{'X-Test'}, 'yes', 'request header';
is $calls[0][2]{headers}{'content-type'}, 'application/json', 'JSON content type';
is_deeply decode_json($calls[0][2]{content}), { name => 'Alice' }, 'JSON encoded';

my $absolute = $api->get('https://other.example.test/status');
is $calls[1][1], 'https://other.example.test/status', 'absolute URL accepted';

my $bad_json_api = HTTP::API::Core->new(
    base_url => 'https://api.example.test',
    retry => { attempts => 1 },
    transport => sub { +{ status => 200, reason => 'OK', headers => {}, content => 'not-json' } },
);
my $decode_error;
eval { $bad_json_api->get('/bad')->json; 1 } or $decode_error = $@;
isa_ok $decode_error, 'HTTP::API::Core::Error';
is $decode_error->category, 'decode', 'decode category';

my $error_api = HTTP::API::Core->new(
    base_url => 'https://api.example.test',
    retry => { attempts => 1 },
    transport => sub {
        return {
            status => 429,
            reason => 'Too Many Requests',
            headers => { 'Retry-After' => '2', 'X-Request-Id' => 'req-429' },
            content => '{"error":"slow down"}',
        };
    },
);
my $http_error;
eval { $error_api->get('/limited'); 1 } or $http_error = $@;
isa_ok $http_error, 'HTTP::API::Core::Error';
is $http_error->category, 'http', 'http category';
is $http_error->status, 429, 'status retained';
ok $http_error->retryable, '429 retryable';
is $http_error->retry_after, '2', 'retry-after retained';
is $http_error->request_id, 'req-429', 'request id retained';
like "$http_error", qr/^HTTP 429/, 'stringifies to useful message';

my $transport_error_api = HTTP::API::Core->new(
    base_url => 'https://api.example.test',
    retry => { attempts => 1 },
    transport => sub { die "socket exploded\n" },
);
my $transport_error;
eval { $transport_error_api->get('/boom'); 1 } or $transport_error = $@;
isa_ok $transport_error, 'HTTP::API::Core::Error';
is $transport_error->category, 'transport', 'transport category';
ok $transport_error->retryable, 'transport errors retryable';

done_testing;
