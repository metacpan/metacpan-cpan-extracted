#!perl -w
use strict;
use HTTP::Request::Generator qw(generate_requests);
use Data::Dumper;
use Test::More;

my $ok = eval {
    require HTTP::Headers;
    HTTP::Headers->VERSION(6.07); # for ->flatten()
    require HTTP::Request::Common;
    require Dancer::Request;
    require Hash::MultiValue;
    1;
};
my $err = $@;
if( !$ok) {
    plan skip_all => "Couldn't load test prerequiste modules: $err";
    exit;
};

plan tests => 8;

my @requests = generate_requests(
    method => 'POST',
    url    => '/feedback',
    body_params => {
        comment => ['Some comment', 'Another comment, A++'],
    },
    headers => [
    { "Content-Type" => 'text/plain; encoding=UTF-8', },
    ],
    wrap => \&HTTP::Request::Generator::as_dancer,
);
is 0+@requests, 2, 'We generate parametrized POST requests';
isa_ok $requests[0], 'Dancer::Request', 'Returned data';
is $requests[0]->params('body')->{'comment'}, 'Some comment', "Body parameter value";

@requests = generate_requests(
    method   => 'GET',
    host     => ['example.com', 'www.example.com'],
    scheme   => ['http', 'https'],
    port     => [443,8443],
    url      => '/',
    wrap => \&HTTP::Request::Generator::as_dancer,
);
is 0+@requests, 8, 'We generate parametrized GET requests'
    or diag Dumper \@requests;
isa_ok $requests[0], 'Dancer::Request', 'Returned data';

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
], "Protocols, hostnames and ports get iterated correctly"
    or diag Dumper \@urls;

@requests = generate_requests(
    method => 'POST',
    url    => '/feedback',
    body_params => {
        comment => ['Some comment', 'Another comment, A++'],
    },
    headers => [
    { "Content-Type" => 'text/plain; encoding=UTF-8', },
    ],
    wrap => sub { File::Spec->tmpdir },
);
is 0+@requests, 2, 'We generate parametrized POST requests';
is $requests[0], File::Spec->tmpdir, 'File::Temp->tempdir is the same';
