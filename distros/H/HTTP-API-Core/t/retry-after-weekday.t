use strict;
use warnings;
use Test::More;

use HTTP::API::Core;
use HTTP::API::Core::Response;
use HTTP::API::Core::Error;

my $before = 1_445_412_470;

is(
    HTTP::API::Core::_retry_after_delay(
        'Wed, 21 Oct 2015 07:28:00 GMT', $before,
    ),
    10,
    'correct weekday remains a valid HTTP-date retry delay',
);

is(
    HTTP::API::Core::_retry_after_delay(
        'Wed, 21 Oct 2015 07:28:00 GMT', $before + 20,
    ),
    0,
    'correct weekday in a past HTTP-date still means no delay',
);

for my $invalid (
    'Tue, 21 Oct 2015 07:28:00 GMT',
    'Thu, 21 Oct 2015 07:28:00 GMT',
    'Mon, 21 Oct 2099 07:28:00 GMT',
) {
    is(
        HTTP::API::Core::_retry_after_delay($invalid, $before),
        undef,
        "inconsistent HTTP-date weekday is ignored: $invalid",
    );
}

is(
    HTTP::API::Core::_retry_after_delay('2.5', $before),
    2.5,
    'numeric Retry-After continues to take precedence as seconds',
);

my $future_bad = 'Mon, 21 Oct 2099 07:28:00 GMT';
my $retry = {
    base_delay => 3,
    max_delay  => 3,
    jitter     => 0,
};

my $exhausted_response = HTTP::API::Core::Response->new(
    status => 429,
    headers => {
        'RateLimit-Remaining' => '0',
        'RateLimit-Reset'     => '2',
    },
);
my $exhausted_error = HTTP::API::Core::Error->new(
    category    => 'http',
    status      => 429,
    retryable   => 1,
    retry_after => $future_bad,
    response    => $exhausted_response,
);
is(
    HTTP::API::Core::_retry_delay($retry, 1, $exhausted_error),
    2,
    'invalid future Retry-After date falls back to exhausted rate-limit reset',
);

my $ordinary_response = HTTP::API::Core::Response->new(
    status => 503,
    headers => {},
);
my $ordinary_error = HTTP::API::Core::Error->new(
    category    => 'http',
    status      => 503,
    retryable   => 1,
    retry_after => $future_bad,
    response    => $ordinary_response,
);
is(
    HTTP::API::Core::_retry_delay($retry, 1, $ordinary_error),
    3,
    'invalid future Retry-After date falls back to capped exponential backoff',
);

done_testing;
