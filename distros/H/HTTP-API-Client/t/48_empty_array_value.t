=head1 NAME

48_empty_array_value.t - HAC-065: kvp2str_each returned an empty string
for a top-level empty-arrayref-valued field instead of omitting it, and
kvp2str pushed that empty string in among the other encoded parts -
{ a => 1, tags => [], z => 9 } encoded to "a=1&&z=9" (a stray double
ampersand). Decoding that back through this module's own kvp_response()
produced a bogus '' => undef key and an uninitialized-value warning -
the same failure signature HAC-061 already fixed for a different
trigger (an ARRAY nested inside xCSV). An empty array has no
representation in a query string, so the field is now omitted entirely,
the same as a key mapped to undef/missing already is.

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;
use HTTP::Response;

my $api = HTTP::API::Client->new;

{
    my $str = $api->kvp2str( data => { a => 1, tags => [], z => 9 }, events => {} );
    is $str, 'a=1&z=9', "an empty-array-valued field is omitted, not left as a stray '&'";
}

{
    my $str = $api->kvp2str( data => { tags => [] }, events => {} );
    is $str, '', "an entirely-empty-array-only data hash encodes to an empty string";
}

{
    # Regression: decoding the previously-malformed output corrupted kvp_response.
    my $api2 = HTTP::API::Client->new;
    my $r = HTTP::Response->new(200);
    $r->content('a=1&z=9');
    $api2->last_response($r);

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    is_deeply $api2->kvp_response, { a => 1, z => 9 },
        "kvp_response decodes the fixed output cleanly, no bogus '' key";
    ok !( grep { /uninitialized/ } @warnings ), "no uninitialized-value warning";
}

done_testing;
