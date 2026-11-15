use strict;
use warnings;
use Test::More;

use HTTP::API::Core;
use HTTP::API::Core::RateLimit;
use HTTP::API::Core::Response;
use HTTP::API::Core::Error;

sub make_response {
    my ($headers) = @_;
    return HTTP::API::Core::Response->new(
        status => 403,
        headers => $headers,
    );
}

my $agree = make_response({
    'RateLimit-Remaining' => '0',
    'ratelimit-remaining' => '0',
    'X-Request-Id' => 'abc',
    'x-request-id' => 'abc',
});
is $agree->header('ratelimit-remaining'), '0',
    'case-insensitive duplicates with matching values are retained';
is $agree->request_id, 'abc',
    'other matching duplicate headers are preserved';
ok $agree->rate_limit->exhausted,
    'matching zero-remaining quota still means exhausted';

my $conflict = make_response({
    'RateLimit-Remaining' => '0',
    'ratelimit-remaining' => '5',
    'X-RateLimit-Remaining' => '0',
    'Retry-After' => '999999999',
    'retry-after' => '0',
});
ok !defined($conflict->header('ratelimit-remaining')),
    'conflicting quota header has no arbitrary chosen value';
ok !defined($conflict->header('retry-after')),
    'conflicting retry-after header has no arbitrary chosen value';
ok !defined($conflict->rate_limit->remaining),
    'conflicting standard quota cannot fall through to legacy zero quota';
ok !$conflict->rate_limit->exhausted,
    'ambiguous quota does not imply exhaustion';

my $mixed = HTTP::API::Core::RateLimit->from_headers({
    'RateLimit-Remaining' => '0',
    'ratelimit-remaining' => '5',
    'RATELIMIT-REMAINING' => '0',
    'X-RateLimit-Remaining' => '0',
    'RateLimit-Reset' => '2',
});
ok !defined($mixed->remaining),
    'direct rate-limit parser rejects conflicting three-way case variants';
ok !$mixed->exhausted,
    'direct parser does not infer exhaustion from a legacy fallback';
is $mixed->source, 'ratelimit',
    'standard header family still determines source';
is $mixed->wait_seconds(now => 1_000), 2,
    'independent valid rate-limit delay remains available';

my $direct_agree = HTTP::API::Core::RateLimit->from_headers({
    'RateLimit-Remaining' => '0',
    'ratelimit-remaining' => '0',
});
is $direct_agree->remaining, 0,
    'direct parser accepts case-insensitive equal values';

my $direct_conflict = HTTP::API::Core::RateLimit->from_headers({
    'Retry-After' => '10',
    'retry-after' => '1',
    'RateLimit-Reset' => '3',
});
ok !defined $direct_conflict->retry_after,
    'direct parser does not choose between contradictory retry-after values';
is $direct_conflict->wait_seconds(now => 1_000), 3,
    'ambiguous retry-after falls back to valid relative reset';

my $undefined = make_response({
    'X-Request-Id' => undef,
    'x-request-id' => 'abc',
});
ok !defined $undefined->header('x-request-id'),
    'defined and undefined duplicates are also treated as conflicting';

my $valid_precedence = HTTP::API::Core::RateLimit->from_headers({
    'RateLimit-Remaining' => '5',
    'X-RateLimit-Remaining' => '0',
});
is $valid_precedence->remaining, 5,
    'valid standard-style quota continues to outrank legacy quota';

my $invalid_precedence = HTTP::API::Core::RateLimit->from_headers({
    'RateLimit-Remaining' => 'invalid',
    'X-RateLimit-Remaining' => '0',
});
ok !defined($invalid_precedence->remaining),
    'present invalid standard-style quota is not overridden by legacy zero';

my $calls = 0;
my $api = HTTP::API::Core->new(
    base_url => 'https://api.example.test',
    retry => {
        attempts   => 3,
        base_delay => 0,
        max_delay  => 0,
        jitter     => 0,
    },
    transport => sub {
        $calls++;
        return {
            status => 403,
            reason => 'Forbidden',
            headers => {
                'RateLimit-Remaining' => '0',
                'ratelimit-remaining' => '5',
                'X-RateLimit-Remaining' => '0',
            },
            content => '',
        };
    },
);
my $error;
eval { $api->get('/forbidden'); 1 } or $error = $@;
isa_ok $error, 'HTTP::API::Core::Error';
is $error->category, 'http', 'conflicting quota retains HTTP error category';
ok !$error->retryable, 'conflicting 403 quota is not retryable';
is $calls, 1, 'ambiguous 403 quota does not trigger an extra request';

my $matching_calls = 0;
my $matching_api = HTTP::API::Core->new(
    base_url => 'https://api.example.test',
    retry => {
        attempts   => 2,
        base_delay => 0,
        max_delay  => 0,
        jitter     => 0,
    },
    transport => sub {
        $matching_calls++;
        return { status => 200, headers => {}, content => '' }
            if $matching_calls == 2;
        return {
            status => 403,
            headers => {
                'RateLimit-Remaining' => '0',
                'ratelimit-remaining' => '0',
                'RateLimit-Reset' => '0',
            },
            content => '',
        };
    },
);
is $matching_api->get('/quota')->status, 200,
    'matching case-insensitive quota still permits a successful retry';
is $matching_calls, 2,
    'matching zero-remaining metadata triggers exactly one retry';

done_testing;
