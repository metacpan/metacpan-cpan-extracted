use strict;
use warnings;
use utf8;
use Test::More;

use HTTP::API::Core;
use HTTP::API::Core::Response;
use HTTP::API::Core::RateLimit;
use HTTP::API::Core::Error;

sub without_warnings {
    my ($code, $label) = @_;
    my (@warnings, $result, $error);
    {
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        eval { $result = $code->(); 1 } or $error = $@;
    }
    is_deeply \@warnings, [], "$label emits no Perl numeric warnings";
    return ($result, $error);
}

my $now = 1_700_000_000;

for my $value (
    [ '٢',  'Arabic-Indic two' ],
    [ '２', 'fullwidth two' ],
    [ '٢.٥', 'Arabic-Indic decimal' ],
) {
    my ($digits, $label) = @$value;
    my ($delay, $error) = without_warnings(
        sub { HTTP::API::Core::_retry_after_delay($digits, $now) },
        "$label Retry-After",
    );
    ok !defined($error), "$label is not a parser exception";
    is $delay, undef, "$label is not coerced to a zero-second retry";
}

my ($invalid_date, $date_error) = without_warnings(
    sub {
        HTTP::API::Core::_retry_after_delay(
            'Wed, ٢١ Oct 2015 07:28:00 GMT', 1_445_412_470,
        );
    },
    'Unicode day in IMF-fixdate',
);
ok !defined($date_error), 'Unicode HTTP-date digits do not throw';
is $invalid_date, undef, 'Unicode HTTP-date digits are invalid';

is HTTP::API::Core::_retry_after_delay('2.5', $now), 2.5,
    'ASCII numeric Retry-After retains decimal delay';
is HTTP::API::Core::_retry_after_delay(
    'Wed, 21 Oct 2015 07:28:00 GMT', 1_445_412_470,
), 10, 'ASCII IMF-fixdate still converts correctly';

my $quota_response = HTTP::API::Core::Response->new(
    status => 429,
    headers => {
        'RateLimit-Remaining' => '0',
        'RateLimit-Reset' => '2',
    },
);
my $quota_error = HTTP::API::Core::Error->new(
    category => 'http',
    status => 429,
    retryable => 1,
    retry_after => '٢',
    response => $quota_response,
);
my $ordinary_error = HTTP::API::Core::Error->new(
    category => 'http',
    status => 503,
    retryable => 1,
    retry_after => '２',
    response => HTTP::API::Core::Response->new(status => 503),
);
my $policy = { base_delay => 3, max_delay => 3, jitter => 0 };
my ($quota_delay, $quota_warning) = without_warnings(
    sub { HTTP::API::Core::_retry_delay($policy, 1, $quota_error) },
    'malformed Retry-After with exhausted quota',
);
ok !defined($quota_warning), 'quota fallback does not throw';
is $quota_delay, 2, 'invalid Retry-After falls back to quota reset';
my ($backoff_delay, $backoff_error) = without_warnings(
    sub { HTTP::API::Core::_retry_delay($policy, 1, $ordinary_error) },
    'malformed Retry-After without quota reset',
);
ok !defined($backoff_error), 'backoff fallback does not throw';
is $backoff_delay, 3, 'invalid Retry-After falls back to exponential backoff';

for my $raw_status ('٢٠٠', '２００') {
    my ($response, $error) = without_warnings(
        sub { HTTP::API::Core::Response->new(status => $raw_status) },
        'direct Response with Unicode status digits',
    );
    ok !defined($response), 'invalid Response status does not create a response';
    like $error, qr/response status must be a valid HTTP status/,
        'invalid direct Response status raises validation error';
}

{
    my $calls = 0;
    my $api = HTTP::API::Core->new(
        base_url => 'https://api.example.test',
        retry => { attempts => 1 },
        transport => sub {
            ++$calls;
            return { status => '٢٠٠', headers => {}, content => '{}' };
        },
    );
    my ($response, $error) = without_warnings(
        sub { $api->get('/malformed-status') },
        'transport with Unicode status digits',
    );
    ok !defined($response), 'malformed transport status is never accepted as success';
    isa_ok $error, 'HTTP::API::Core::Error';
    is $error->category, 'transport', 'malformed status retains transport error category';
    is $calls, 1, 'invalid response with one attempt dispatches only once';
}

for my $bad_remaining ('٠', '０') {
    my ($rate, $error) = without_warnings(
        sub {
            HTTP::API::Core::RateLimit->from_headers({
                'RateLimit-Remaining' => $bad_remaining,
            });
        },
        'Unicode rate-limit remaining',
    );
    ok !defined($error), 'invalid quota value is ignored rather than thrown';
    is $rate->remaining, undef, 'Unicode remaining is not coerced to zero';
    ok !$rate->exhausted, 'invalid quota does not mark quota exhausted';
}

{
    my $calls = 0;
    my $api = HTTP::API::Core->new(
        base_url => 'https://api.example.test',
        retry => { attempts => 3, base_delay => 0, jitter => 0 },
        transport => sub {
            ++$calls;
            return {
                status => 403,
                headers => { 'RateLimit-Remaining' => '٠' },
                content => '',
            };
        },
    );
    my ($response, $error) = without_warnings(
        sub { $api->get('/not-exhausted') },
        '403 response with invalid Unicode remaining',
    );
    ok !defined($response), '403 is not accepted as success';
    isa_ok $error, 'HTTP::API::Core::Error';
    is $error->status, 403, 'original 403 status is preserved';
    ok !$error->retryable, 'invalid quota cannot turn ordinary 403 into retryable 403';
    is $calls, 1, 'invalid quota never causes an extra 403 request';
}

{
    my $calls = 0;
    my $api = HTTP::API::Core->new(
        base_url => 'https://api.example.test',
        retry => { attempts => 2, base_delay => 0, jitter => 0 },
        transport => sub {
            ++$calls;
            return $calls == 1
                ? { status => 403, headers => { 'RateLimit-Remaining' => '0' }, content => '' }
                : { status => 200, headers => {}, content => '{}' };
        },
    );
    is $api->get('/ascii-quota')->status, 200,
        'ASCII zero remaining still permits exhausted 403 retry';
    is $calls, 2, 'valid ASCII zero triggers the intended single retry';
}

{
    my ($rate, $error) = without_warnings(
        sub { HTTP::API::Core::RateLimit->new(remaining => '٠') },
        'direct RateLimit constructor with Unicode numeric value',
    );
    ok !defined($rate), 'invalid constructor input creates no rate-limit object';
    like $error, qr/rate-limit remaining must be a non-negative number or undef/,
        'RateLimit constructor validates ASCII numbers';
}

{
    my $rate = HTTP::API::Core::RateLimit->new(reset_epoch => 2000);
    my ($delay, $error) = without_warnings(
        sub { $rate->wait_seconds(now => '١٠٠٠') },
        'RateLimit wait_seconds with Unicode current time',
    );
    ok !defined($delay), 'invalid current time produces no wait result';
    like $error, qr/rate-limit now must be a non-negative number/,
        'RateLimit current-time validation rejects Unicode digits';
}

done_testing;
