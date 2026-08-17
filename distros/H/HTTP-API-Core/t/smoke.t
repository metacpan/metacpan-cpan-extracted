use strict;
use warnings;
use Test::More;

use HTTP::API::Core;
use HTTP::API::Core::Auth qw(bearer_auth);

my @seen;
my $api = HTTP::API::Core->new(
    base_url => 'https://api.example.test',
    hooks => {
        before_request => bearer_auth('token'),
    },
    transport => sub {
        my ($method, $url, $opts) = @_;
        push @seen, [$method, $url, $opts];
        return {
            status  => 200,
            reason  => 'OK',
            headers => { 'Content-Type' => 'application/json' },
            content => '{"ok":true}',
        };
    },
);

my $response = $api->get('/users', query => { page => 2 });

is $response->status, 200, 'status';
ok $response->json->{ok}, 'json';
is $seen[0][0], 'GET', 'method';
like $seen[0][1], qr/page=2/, 'query';
is $seen[0][2]{headers}{Authorization}, 'Bearer token', 'auth';

done_testing;
