=head1 NAME

88_negative_retry_delay_clamped_in_retry_attribute.t - HAC-122: _build_retry()
clamped a negative retry count to 0 ('$count = 0 if looks_like_number($count)
&& $count < 0;') but had no equivalent clamp for delay, so a negative delay
passed straight through into the public 'retry' attribute unclamped.
send() itself never actually sleeps a negative amount - it re-clamps delay
locally at its own point of use (HAC-045/t/37) - but $api->retry (kept
specifically so external callers can read the configured retry settings
directly, per the comment on the 'retry' attribute) disagreed with what
send() actually does: $api->retry->{count} was 0 for a negative count, while
$api->retry->{delay} stayed negative for a negative delay.

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

{
    my $api = HTTP::API::Client->new( retry_config => { delay => -5 } );

    is $api->retry->{delay}, 0,
        "a negative retry_config delay is clamped to 0 in the retry attribute, matching count's existing clamp";
}

{
    local $ENV{RETRY_DELAY} = -7;
    my $api = HTTP::API::Client->new;

    is $api->retry->{delay}, 0,
        "a negative RETRY_DELAY env var is likewise clamped to 0";
}

{
    # a non-negative delay is untouched - only the negative case is clamped
    my $api = HTTP::API::Client->new( retry_config => { delay => 3 } );

    is $api->retry->{delay}, 3, "a non-negative delay passes through unchanged";
}

{
    # a non-numeric delay isn't a candidate for the < 0 clamp at all -
    # looks_like_number() guards it, same as the existing count clamp does
    my $api = HTTP::API::Client->new( retry_config => { delay => "not-a-number" } );

    is $api->retry->{delay}, "not-a-number",
        "a non-numeric delay passes through unchanged, not zeroed";
}

done_testing;
