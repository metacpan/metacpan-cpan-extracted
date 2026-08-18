=head1 NAME

36_negative_retry_count.t - HAC-044: send()'s retry loop is
'foreach my $retry ( 0 .. $retry_count )' - if $retry_count is negative
(e.g. RETRY_FAIL_RESPONSE=-1), Perl's 0..-1 range is empty, so the loop
body never runs at all. send()/get()/etc silently returned undef - no
request attempted, no error, no warning.

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

{
    local $ENV{RETRY_FAIL_RESPONSE} = -1;

    my $api = HTTP::API::Client->new;
    my $req = $api->get( "http://example.com", {}, {}, { test_request_object => 1 } );

    ok defined $req, "a negative retry count still makes one attempt instead of silently returning undef";
    isa_ok $req, "HTTP::Request";
}

done_testing;
