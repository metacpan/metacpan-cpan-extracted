=head1 NAME

96_retry_count_non_numeric_passthrough.t - HAC-131: _build_retry()'s count
clamp ('$count = 0 if looks_like_number($count) && $count < 0;') only had
its numeric branches tested (t/36, t/88) - the non-numeric-count row was
never exercised. Live-verified before this test existed: a non-numeric
count passes through unchanged, the same "pass through non-numeric
unchanged" behavior HAC-122/t/88 already covers for delay.

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

{
    my $api = HTTP::API::Client->new( retry_config => { fail_response => "not-a-number" } );

    is $api->retry->{count}, "not-a-number",
        "a non-numeric retry count passes through unchanged, not zeroed or coerced";
}

done_testing;
