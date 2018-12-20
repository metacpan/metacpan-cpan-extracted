#!perl -w
use strict;
use HTTP::Request::Generator qw(generate_requests);
use Data::Dumper;
use Test::More;

my $ok = eval {
    require HTTP::Headers;
    HTTP::Headers->VERSION(6.07); # for ->flatten()
    require HTTP::Request;
    require HTTP::Request::Common;
    require URI;
    1;
};
my $err = $@;
if( !$ok) {
    plan skip_all => "Couldn't load test prerequiste modules: $err";
    exit;
};

plan tests => 7;

my @requests = generate_requests(
    method => 'POST',
    url    => '/feedback/:item',
    body_params => {
        comment => ['Some comment', 'Another comment, A++'],
    },
    query_params => {
        item => [1,2],
    },
    headers => [
    { "Content-Type" => 'text/plain; encoding=UTF-8', },
    ],
    wrap => \&HTTP::Request::Generator::as_http_request,
);
is 0+@requests, 4, 'We generate parametrized POST requests';
isa_ok $requests[0], 'HTTP::Request', 'Returned data';

# Really bad HTTP parameter decoder:
my %payload = map {s/\+/ /g; $_ } split /[=&]/, $requests[0]->decoded_content;
is $payload{'comment'}, 'Some comment', "We retrieve the body";

is $requests[0]->url->query_param('item'), '1', "We fetch the correct query parameter";

@requests = generate_requests(
    method   => 'GET',
    host     => ['example.com', 'www.example.com'],
    scheme   => ['http', 'https'],
    port     => [443,8443],
    url      => '/',
    wrap => \&HTTP::Request::Generator::as_http_request,
);
is 0+@requests, 8, 'We generate parametrized GET requests';
isa_ok $requests[0], 'HTTP::Request', 'Returned data';

my @urls = sort { $a cmp $b } map { $_->uri } @requests;

is_deeply \@urls, [
    'http://example.com:443/',
    'http://example.com:8443/',
    'http://www.example.com:443/',
    'http://www.example.com:8443/',
    'https://example.com/',
    'https://example.com:8443/',
    'https://www.example.com/',
    'https://www.example.com:8443/',
], "scheme  s, hostnames and ports get iterated correctly"
    or diag Dumper \@urls;
