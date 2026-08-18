=head1 NAME

14_response_decode.t - coverage for json_response()/kvp_response()'s actual
decode logic, which had never been exercised (only the "no request made
yet" guard paths added for HAC-007/HAC-009 had coverage)

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;
use HTTP::Response;

{
    my $api = HTTP::API::Client->new;
    my $r   = HTTP::Response->new(200);
    $r->content('{"a":1,"b":"hello"}');
    $api->last_response($r);

    is_deeply $api->json_response, { a => 1, b => "hello" },
        "json_response() decodes a real JSON response body";
}

{
    my $api = HTTP::API::Client->new;
    my $r   = HTTP::Response->new(200);
    $r->content('not json {{{');
    $api->last_response($r);

    my $result = $api->json_response;
    is $result->{status}, "error",
        "json_response() with an invalid body returns the error hash instead of dying";
}

{
    my $api = HTTP::API::Client->new;
    my $r   = HTTP::Response->new(200);
    $r->content('a=1&b=hello%20world');
    $api->last_response($r);

    is_deeply $api->kvp_response, { a => 1, b => "hello world" },
        "kvp_response() decodes a real query-string response body";
}

done_testing;
