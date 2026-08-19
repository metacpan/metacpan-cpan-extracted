=head1 NAME

43_kvp_response_repeated_keys.t - HAC-060: kvp_response() silently
collapsed repeated query-string keys to their last value, losing every
earlier value with no warning - decoding "tags=a&tags=b&tags=c" returned
{ tags => 'c' } instead of preserving all three. This is exactly the
shape kvp2str_each's ARRAY branch produces when encoding an array-valued
field, so round-tripping an array field through a form-urlencoded API
lost data silently. Repeated keys now collect into an arrayref; a
singleton key still decodes to a plain scalar (unchanged, existing
behavior).

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;
use HTTP::Response;

{
    my $api = HTTP::API::Client->new;
    my $r = HTTP::Response->new(200);
    $r->content('tags=a&tags=b&tags=c');
    $api->last_response($r);

    is_deeply $api->kvp_response, { tags => [qw(a b c)] },
        "repeated keys collect into an arrayref instead of losing all but the last value";
}

{
    my $api = HTTP::API::Client->new;
    my $r = HTTP::Response->new(200);
    $r->content('a=1&b=hello%20world');
    $api->last_response($r);

    is_deeply $api->kvp_response, { a => 1, b => "hello world" },
        "a singleton key still decodes to a plain scalar, unchanged";
}

done_testing;
