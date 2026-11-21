use strict;
use warnings;
use Test::More;

use HTTP::API::Core;
use HTTP::API::Core::Response;
use HTTP::API::Core::Error;

# Time::Local may interpret four-digit years below 1000 as offset years:
# 0199 -> 2099, 0999 -> 2899, 0000 -> 2000. The weekday below deliberately
# matches the incorrectly converted year, so a weekday-only check misses it.
my $now = 1_700_000_000;
for my $invalid (
    'Thu, 01 Jan 0199 00:00:00 GMT',
    'Thu, 01 Jan 0999 00:00:00 GMT',
    'Sat, 01 Jan 0000 00:00:00 GMT',
) {
    is(
        HTTP::API::Core::_retry_after_delay($invalid, $now),
        undef,
        "year-shifted Retry-After date is ignored: $invalid",
    );
}

is(
    HTTP::API::Core::_retry_after_delay(
        'Sat, 01 Jan 2000 00:00:00 GMT', 946_684_790,
    ),
    10,
    'valid year 2000 still converts to the correct delay',
);
is(
    HTTP::API::Core::_retry_after_delay(
        'Thu, 01 Jan 2099 00:00:00 GMT', 4_070_908_790,
    ),
    10,
    'valid future four-digit year still converts correctly',
);
is(
    HTTP::API::Core::_retry_after_delay(
        'Wed, 21 Oct 2015 07:28:00 GMT', 1_445_412_470,
    ),
    10,
    'ordinary valid IMF-fixdate remains accepted',
);
is(
    HTTP::API::Core::_retry_after_delay(
        'Fri, 01 Jan 2099 00:00:00 GMT', 4_070_908_790,
    ),
    undef,
    'mismatched weekday remains invalid',
);
is(
    HTTP::API::Core::_retry_after_delay('2.5', $now),
    2.5,
    'numeric Retry-After still takes precedence as seconds',
);

my $invalid_future = 'Thu, 01 Jan 0199 00:00:00 GMT';
my $policy = {
    base_delay => 3,
    max_delay  => 3,
    jitter     => 0,
};

my $quota_response = HTTP::API::Core::Response->new(
    status  => 429,
    headers => {
        'RateLimit-Remaining' => '0',
        'RateLimit-Reset'     => '2',
    },
);
my $quota_error = HTTP::API::Core::Error->new(
    category    => 'http',
    status      => 429,
    retryable   => 1,
    retry_after => $invalid_future,
    response    => $quota_response,
);
is(
    HTTP::API::Core::_retry_delay($policy, 1, $quota_error),
    2,
    'ambiguous year falls back to exhausted rate-limit reset',
);

my $ordinary_response = HTTP::API::Core::Response->new(
    status  => 503,
    headers => {},
);
my $ordinary_error = HTTP::API::Core::Error->new(
    category    => 'http',
    status      => 503,
    retryable   => 1,
    retry_after => $invalid_future,
    response    => $ordinary_response,
);
is(
    HTTP::API::Core::_retry_delay($policy, 1, $ordinary_error),
    3,
    'ambiguous year falls back to capped exponential backoff',
);

done_testing;
