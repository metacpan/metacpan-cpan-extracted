=head1 NAME

57_kvp_response_plus_space.t - HAC-074: kvp_response() only decoded %XX
percent-encoding, never the application/x-www-form-urlencoded convention
of a literal + meaning a space. A response body from any API using that
convention (extremely common - it's the traditional form-encoding space
representation) left a literal + in the decoded value instead of a
space. A genuinely percent-encoded literal + (%2B) must still decode to
a literal +, distinct from a raw + meaning space.

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;
use HTTP::Response;

{
    my $api = HTTP::API::Client->new;
    my $r = HTTP::Response->new(200);
    $r->content('q=hello+world&b=foo');
    $api->last_response($r);

    is_deeply $api->kvp_response, { q => 'hello world', b => 'foo' },
        "a raw + in the response body decodes to a space";
}

{
    my $api = HTTP::API::Client->new;
    my $r = HTTP::Response->new(200);
    $r->content('sum=1%2B1');
    $api->last_response($r);

    is_deeply $api->kvp_response, { sum => '1+1' },
        "a percent-encoded %2B still decodes to a literal +, distinct from raw + meaning space";
}

{
    my $api = HTTP::API::Client->new;
    my $r = HTTP::Response->new(200);
    $r->content('mixed=a+b%2Bc');
    $api->last_response($r);

    is_deeply $api->kvp_response, { mixed => 'a b+c' },
        "raw + (space) and %2B (literal +) are both handled correctly in the same value";
}

done_testing;
