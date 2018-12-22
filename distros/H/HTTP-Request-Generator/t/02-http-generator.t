#!perl -w
use strict;
use HTTP::Request::Generator qw(generate_requests);
use Data::Dumper;

use Test::More tests => 28;

my @requests = generate_requests();
is 0+@requests, 1;

@requests = generate_requests(
    method => 'GET',
    path   => ['/','/index.html'],
);
is 0+@requests, 2, 'We get two data instances for "url" parameter';

@requests = generate_requests(
    method => ['POST','GET'],
    path   => ['/','/index.html'],
    #query_params => ['foo','bar','baz'],
    query_params => {
        foo => [1,2,3],
        bar => [4,5,6],
        baz => [7,8,9],
    },
    fixed_query_params => {
        session => 'my_session_id',
    },
);
is 0+@requests, 2*2*3*3*3, 'The amount of generated instances multiplies';
ok exists $requests[0]->{query_params}, 'Fixed get parameters get added';
my @without_session = grep { $requests[0]->{query_params}->{session} ne 'my_session_id' } @requests;
is 0+@without_session, 0, 'Fixed parameters get added everywhere'
    or diag Dumper \@without_session;

@requests = generate_requests(
    method => 'GET',
    path   => '/profiles/:name/:id',
    url_params => {
        name => ['Corion','Co-Rion'],
        id   => [1,2],
    },
    query_params => {
        foo => [2,3],
    },
    fixed_query_params => {
        session => 'my_session_id',
    },
);
is 0+@requests, 8, 'We generate parametrized URLs';
is $requests[0]->{url}, '/profiles/Corion/1?foo=2&session=my_session_id', 'The first path matches'
    or diag Dumper $requests[0];
is $requests[0]->{query_params}->{foo}, 2, 'Get parameters vary'
    or diag Dumper \@requests;
is $requests[0]->{query_params}->{session}, 'my_session_id', 'Fixed parameters get added'
    or diag Dumper $requests[0];
is_deeply $requests[0], {
    method => 'GET',
    path   => '/profiles/Corion/1',
    scheme => 'http',
    port   => 0,
    host => '',
    headers => {},
    body_params => {},
    query_params => {
        session => 'my_session_id',
        foo => 2,
    },
    url => URI->new('/profiles/Corion/1?foo=2&session=my_session_id', 'http'),
}, "The structure is as we expect"
or diag Dumper $requests[0];

@requests = generate_requests(
    method => 'POST',
    path   => '/profiles/:name/:id',
    url_params => {
        name => 'Corion',
        id   => 1,
    },
    query_params => {
        foo => [2,3],
    },
    body_params => {
        comment => ['Some comment', 'Another comment, A++'],
    },
    headers => {
        Cookie => 'my_session_id',
    },
);
is 0+@requests, 4, 'We generate parametrized POST requests';

@requests = generate_requests(
    method => 'POST',
    path   => '/profiles/:name/:id',
    body_params => {
        comment => ['Some comment', 'Another comment, A++'],
    },
    headers => [
    { "Content-Type" => 'text/plain; encoding=UTF-8', },
    { "Content-Type" => 'text/plain; encoding=Latin-1', },
    ],
);
is 0+@requests, 4, 'We generate parametrized POST requests';
is $requests[0]->{url}, '/profiles/:name/:id', "Unparametrized URLs don't get interpolated";
is_deeply $requests[0]->{headers}, {'Content-Type' => 'text/plain; encoding=UTF-8'}, "Headers get added";
is_deeply $requests[2]->{headers}, {'Content-Type' => 'text/plain; encoding=Latin-1'}, "Headers get iterated";

@requests = generate_requests(
    method => 'GET',
    url    => 'https://example.com/profiles',
    port   => [443, 8080, 8443],
);
is 0+@requests, 3, 'We generate requests parametrized across ports';
is $requests[0]->{port}, 443,  "port numbers get expanded";
is $requests[1]->{port}, 8080, "port numbers get expanded";
is $requests[2]->{port}, 8443, "port numbers get expanded";

@requests = generate_requests(
    method   => 'GET',
    url      => 'https://example.com/',
    scheme   => ['http', 'https'],
);
is 0+@requests, 2, 'We generate requests parametrized across scheme  s';
is $requests[0]->{scheme  }, 'http', "scheme   works";
is $requests[1]->{scheme  }, 'https', "scheme   works";

@requests = generate_requests(
    host     => ['example.com', 'www.example.com'],
    path     => '/foo',
);
is 0+@requests, 2, 'We generate requests parametrized across hostnames';
is $requests[0]->{host}, 'example.com', "Hostnames work";
is $requests[1]->{host}, 'www.example.com', "Hostnames work";


@requests = generate_requests(
    method   => 'GET',
    host     => ['example.com', 'www.example.com'],
    scheme   => ['http', 'https'],
    port     => [443,8443],
    url      => '/',
);
is 0+@requests, 8, 'We generate parametrized GET requests'
    or diag Dumper \@requests;

    
@requests = generate_requests(
    pattern  => '{http,https}://example.com/foo?q=test&s=bar',
);
is 0+@requests, 2, 'We generate parametrized GET requests'
    or diag Dumper \@requests;
is_deeply $requests[0], {
    method => 'GET',
    path   => '/foo',
    scheme => 'http',
    port   => 0,
    host => 'example.com',
    headers => {},
    body_params => {},
    query_params => {
        "q" => 'test',
        "s" => 'bar',
    },
    url => URI->new('http://example.com/foo?q=test&s=bar', 'http'),
}, "The structure is as we expect"
or diag Dumper $requests[0];
