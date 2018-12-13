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

plan tests => 4;

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
