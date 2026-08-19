=head1 NAME

44_csv_nested_array_double_amp.t - HAC-061: kvp2str_each double-ampersanded
an ARRAY value nested inside an xCSV(...) list. The ARRAY branch signals
"I produced full key=value pairs, not a bare CSV-joinable scalar" to the
CSV branch by prefixing its output with a leading '&' when called with
no_key=>1; the CSV branch's own 'join "&", $csv, @parts' then adds a
second '&', producing e.g. 'e=6,7,8,15&&e=13&e=14'. That exact string was
already the literal expected value in t/05_kvp.t before this fix. Decoding
the double-amp output back through this module's own kvp_response()
produced a bogus '' => undef key and uninitialized-value warnings - a
round-trip data-integrity bug, not just a cosmetic one.

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;
use HTTP::Response;

{
    my $api = HTTP::API::Client->new(
        content_type     => "application/x-www-form-urlencoded",
        pre_defined_data => {
            e => xCSV( 6, 7, [ 13, 14 ], 15 ),
        },
    );

    my $req = $api->get( '/test', {}, {}, { test_request_object => 1 } );
    my $content = $req->uri =~ m/\?(.*)/ ? $1 : '';

    unlike $content, qr/&&/, "no double ampersand when an ARRAY is nested inside xCSV";
    is $content, 'e=6,7,15&e=13&e=14', "single '&' between the CSV scalars and the nested array's pairs";
}

{
    my $api = HTTP::API::Client->new;
    my $r = HTTP::Response->new(200);
    $r->content('e=6,7,15&e=13&e=14');
    $api->last_response($r);

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    is_deeply $api->kvp_response, { e => [ '6,7,15', '13', '14' ] },
        "round-tripping the fixed output through kvp_response() no longer produces a bogus '' key";
    ok !@warnings, "no uninitialized-value warnings decoding the fixed output"
        or diag explain \@warnings;
}

done_testing;
