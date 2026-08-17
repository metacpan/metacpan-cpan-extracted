use strict;
use warnings;
use Test::More;
use MIME::Base64 qw(encode_base64);

use HTTP::API::Core;
use HTTP::API::Core::Auth qw(bearer_auth basic_auth api_key_auth);

sub capture_request {
    my ($hook, %request_opts) = @_;
    my $seen;
    my $api = HTTP::API::Core->new(
        base_url => 'https://api.example.test',
        hooks => { before_request => $hook },
        transport => sub {
            my ($method, $url, $opts) = @_;
            $seen = [$method, $url, $opts];
            return { status => 200, reason => 'OK', headers => {}, content => '{}' };
        },
    );
    $api->get('/items', %request_opts);
    return $seen;
}

for my $bad (undef, '', [], {}) {
    my $ok = eval { bearer_auth($bad); 1 };
    ok !$ok, 'bearer_auth rejects invalid token';
    like $@, qr/bearer token must be a non-empty scalar/, 'bearer validation is stable';
}

my $bearer = capture_request(bearer_auth('abc123'));
is $bearer->[2]{headers}{Authorization}, 'Bearer abc123', 'bearer helper adds Authorization';

my $explicit_bearer = capture_request(
    bearer_auth('ignored'),
    headers => { authorization => 'Custom explicit value' },
);
is $explicit_bearer->[2]{headers}{authorization}, 'Custom explicit value', 'existing authorization wins case-insensitively';
ok !exists $explicit_bearer->[2]{headers}{Authorization}, 'bearer helper avoids duplicate differently-cased header';

for my $case (
    [undef, 'pass', qr/username is required/],
    [[], 'pass', qr/username is required/],
    ['user', undef, qr/password is required/],
    ['user', {}, qr/password is required/],
) {
    my ($user, $pass, $re) = @$case;
    my $ok = eval { basic_auth($user, $pass); 1 };
    ok !$ok, 'basic_auth rejects non-scalar/missing credentials';
    like $@, $re, 'basic auth validation is stable';
}

my $basic = capture_request(basic_auth('', ''));
is $basic->[2]{headers}{Authorization}, 'Basic ' . encode_base64(':', ''), 'basic auth allows empty scalar credentials';

my @bad_api_keys = (
    [ [in => 'cookie', name => 'token', value => 'x'], qr/in must be header or query/ ],
    [ [name => undef, value => 'x'], qr/name must be a non-empty scalar/ ],
    [ [name => '', value => 'x'], qr/name must be a non-empty scalar/ ],
    [ [name => [], value => 'x'], qr/name must be a non-empty scalar/ ],
    [ [name => 'token', value => undef], qr/value must be a scalar/ ],
    [ [name => 'token', value => []], qr/value must be a scalar/ ],
    [ [name => 'token', value => 'x', extra => 1], qr/unknown api_key auth option: extra/ ],
);

for my $case (@bad_api_keys) {
    my ($args, $re) = @$case;
    my $ok = eval { api_key_auth(@$args); 1 };
    ok !$ok, 'api_key_auth rejects invalid configuration';
    like $@, $re, 'api key validation error is stable';
}

my $header_key = capture_request(api_key_auth(name => 'X-API-Key', value => ''));
is $header_key->[2]{headers}{'X-API-Key'}, '', 'empty scalar API key value is allowed';

my $existing_header_key = capture_request(
    api_key_auth(name => 'X-API-Key', value => 'ignored'),
    headers => { 'x-api-key' => 'explicit' },
);
is $existing_header_key->[2]{headers}{'x-api-key'}, 'explicit', 'existing API-key header wins case-insensitively';
ok !exists $existing_header_key->[2]{headers}{'X-API-Key'}, 'header helper avoids duplicate differently-cased key';

my $query_key = capture_request(
    api_key_auth(in => 'query', name => 'api key', value => "snowman \x{2603}"),
    query => { page => 2 },
);
like $query_key->[1], qr/[?&]page=2(?:&|$)/, 'normal query parameters remain present';
like $query_key->[1], qr/[?&]api%20key=snowman%20%E2%98%83(?:&|$)/, 'query API key name/value use UTF-8 percent encoding';

my $no_duplicate = capture_request(
    api_key_auth(in => 'query', name => 'api_key', value => 'new'),
    query => { api_key => 'existing', page => 1 },
);
my @matches = $no_duplicate->[1] =~ /(?:[?&])api_key=/g;
is scalar(@matches), 1, 'query helper does not duplicate an existing key';
like $no_duplicate->[1], qr/(?:[?&])api_key=existing(?:&|$)/, 'existing query credential is preserved';

my $hook = bearer_auth('token');
is ref($hook), 'CODE', 'bearer_auth returns a hook callback';
$hook = basic_auth('u', 'p');
is ref($hook), 'CODE', 'basic_auth returns a hook callback';
$hook = api_key_auth(name => 'X-Key', value => 'v');
is ref($hook), 'CODE', 'api_key_auth returns a hook callback';

done_testing;
