=head1 NAME

77_debug_retry_line.t - HAC-099: send()'s '-- RETRY $retry of $retry_count'
debug line only fires when a debug flag is on AND an actual retry attempt is
happening. Every existing debug-flag test disables retries
(RETRY_FAIL_RESPONSE=0) and every existing retry test leaves debug flags
off, so no test combined both and this line had a raw execution count of 0
in Devel::Cover. Verified live before this test existed: the line already
prints correctly ("-- RETRY 1 of 2", then "-- RETRY 2 of 2") as each retry
attempt is made - this is a coverage gap for already-correct behavior, not
a defect, the same category HAC-097 closed for new_request()'s GET branch.

=cut

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;
use HTTP::API::Client;
use FakeUA;
use CaptureStderr;

{
    local $ENV{DEBUG_SEND_OUT}      = 1;
    local $ENV{RETRY_FAIL_RESPONSE} = 2;
    local $ENV{RETRY_FAIL_STATUS}   = "500";
    local $ENV{RETRY_DELAY}         = 0;

    my $api = HTTP::API::Client->new;
    $api->ua( FakeUA->new(500) );

    my $out = capture_stderr( sub { $api->get("http://x/") } );

    like $out, qr/-- RETRY 1 of 2/, "the first retry attempt prints '-- RETRY 1 of 2'";
    like $out, qr/-- RETRY 2 of 2/, "the second retry attempt prints '-- RETRY 2 of 2'";

    my @request_dumps = $out =~ /-- REQUEST --/g;
    is scalar(@request_dumps), 3,
        "three request dumps total (the original attempt plus both retries), confirming the RETRY line only appears on the retries, not the first attempt";
}

done_testing;
