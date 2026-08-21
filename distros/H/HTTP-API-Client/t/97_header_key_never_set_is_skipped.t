=head1 NAME

97_header_key_never_set_is_skipped.t - HAC-132: new_request()'s per-key
skip guard ('$o{skip_headers}{$key} || !exists $headers->{$key} ||
!defined $headers->{$key}') had only its "exists but undef" and
"has a value" rows tested - the "key was never in %headers at all" row
(relevant when headers_keys/add_headers_keys lists a key the caller
didn't set, expecting before_header to supply it, and it doesn't) was
never exercised. Live-verified before this test existed: such a key is
silently skipped, not a crash or a bogus empty header.

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

{
    my $api = HTTP::API::Client->new;

    my $req = $api->send(
        GET => "http://x/", {}, {},
        {
            headers_keys         => sub { return ("X-Never-Set") },
            test_request_object  => 1,
        },
    );

    ok !defined $req->header("X-Never-Set"),
        "a headers_keys-listed key never present in %headers, and not supplied by before_header, is silently skipped";
}

done_testing;
