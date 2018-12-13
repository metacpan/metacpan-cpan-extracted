#!perl -w
use strict;
use HTTP::Request::Generator qw(generate_requests);
use Data::Dumper;

use Test::More tests => 15;

my @requests = generate_requests();
is 0+@requests, 1;

@requests = generate_requests(
    method => 'GET',
    url    => ['/','/index.html'],
);
is 0+@requests, 2, 'We get two data instances for "url" parameter';

@requests = generate_requests(
    method => ['POST','GET'],
    url    => ['/','/index.html'],
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
    url    => '/profiles/:name/:id',
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
is $requests[0]->{url}, '/profiles/Corion/1', 'The first URL matches'
    or diag Dumper $requests[0];
is $requests[0]->{query_params}->{foo}, 2, 'Get parameters vary'
    or diag Dumper \@requests;
is $requests[0]->{query_params}->{session}, 'my_session_id', 'Fixed parameters get added'
    or diag Dumper $requests[0];
is_deeply $requests[0], {
    method => 'GET',
    url => '/profiles/Corion/1',
    protocol => 'http',
    port => 80,
    headers => {},
    body_params => {},
    query_params => {
        session => 'my_session_id',
        foo => 2,
    },
}, "The structure is as we expect";

@requests = generate_requests(
    method => 'POST',
    url    => '/profiles/:name/:id',
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
    url    => '/profiles/:name/:id',
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
