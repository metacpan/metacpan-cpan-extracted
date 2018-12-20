#!perl -w
use strict;
use HTTP::Request::Generator qw(generate_requests);
use Data::Dumper;
use Test::More;

# Skip if unavailable
my $ok = eval {
    require Plack::Request;
    Plack::Request->VERSION(1.0047); # for ->parameters to work correctly
    require HTTP::Headers;
    HTTP::Headers->VERSION(6.07); # for ->flatten()
    require Hash::MultiValue;
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
    wrap => \&HTTP::Request::Generator::as_plack,
);
is 0+@requests, 4, 'We generate parametrized POST requests';
isa_ok $requests[0], 'Plack::Request', 'Returned data';
is $requests[0]->parameters->{'comment'}, 'Some comment', "We fetch the correct body parameter"
    or diag "Plack::Request version " . Plack::Request->VERSION;
is $requests[0]->parameters->{'item'}, '1', "We fetch the correct query parameter";

@requests = generate_requests(
    method   => 'GET',
    host     => ['example.com', 'www.example.com'],
    scheme   => ['http', 'https'],
    port     => [443,8443],
    url      => '/',
    wrap => \&HTTP::Request::Generator::as_plack,
);
is 0+@requests, 8, 'We generate parametrized GET requests';
isa_ok $requests[0], 'Plack::Request', 'Returned data';

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
