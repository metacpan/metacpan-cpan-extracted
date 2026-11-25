use strict;
use warnings;
use Test::More;

use HTTP::API::Core::RateLimit;

my $mixed = HTTP::API::Core::RateLimit->from_headers({
    'RateLimit-Limit'       => '100',
    'X-RateLimit-Limit'     => '999',
    'RateLimit-Remaining'   => '5',
    'X-RateLimit-Remaining' => '1',
    'RateLimit-Reset'       => '12',
    'X-RateLimit-Reset'     => '2000',
    'Retry-After'           => '7',
});

is $mixed->limit, 100, 'standard limit takes precedence';
is $mixed->remaining, 5, 'standard remaining takes precedence';
is $mixed->reset, 12, 'standard reset is relative seconds';
is $mixed->reset_epoch, 2000, 'legacy reset is preserved as epoch';
is $mixed->retry_after, 7, 'retry-after is parsed';
is $mixed->source, 'ratelimit', 'standard family determines source';
is $mixed->wait_seconds(now => 1000), 7, 'retry-after has highest delay priority';

my $standard_reset = HTTP::API::Core::RateLimit->from_headers({
    'RateLimit-Reset' => '4.5',
});
is $standard_reset->wait_seconds(now => 1000), 4.5, 'standard reset beats epoch fallback';

my $epoch = HTTP::API::Core::RateLimit->from_headers({
    'X-RateLimit-Reset' => '1100',
});
is $epoch->source, 'x-ratelimit', 'legacy family detected';
is $epoch->wait_seconds(now => 1000), 100, 'epoch reset converted to delay';
is $epoch->wait_seconds(now => 1200), 0, 'past epoch delay clamps to zero';

my $invalid = HTTP::API::Core::RateLimit->from_headers({
    'RateLimit-Limit'     => '-1',
    'RateLimit-Remaining' => 'oops',
    'RateLimit-Reset'     => '',
    'Retry-After'         => 'tomorrow',
});
ok !defined $invalid->limit, 'negative numeric value ignored';
ok !defined $invalid->remaining, 'invalid remaining ignored';
ok !defined $invalid->reset, 'empty reset ignored';
ok !defined $invalid->retry_after, 'non-numeric retry-after ignored';
ok !defined $invalid->wait_seconds(now => 0), 'no valid delay returns undef';
ok !$invalid->exhausted, 'missing normalized remaining is not exhausted';

my $zero = HTTP::API::Core::RateLimit->from_headers({
    'ratelimit-remaining' => '0',
});
ok $zero->exhausted, 'header names are case-insensitive';

my $copy = $mixed->as_hash;
is_deeply $copy, {
    limit       => 100,
    remaining   => 5,
    used        => undef,
    reset       => 12,
    reset_epoch => 2000,
    retry_after => 7,
    resource    => undef,
    source      => 'ratelimit',
}, 'as_hash exposes normalized public metadata';
$copy->{limit} = 1;
is $mixed->limit, 100, 'as_hash returns an independent hash';

my $empty = HTTP::API::Core::RateLimit->from_headers(undef);
ok !defined $empty->source, 'missing headers have no source';
ok !defined $empty->wait_seconds(now => 0), 'missing headers have no wait';


# Standard metadata must outrank legacy metadata, even for zero values.
my $preferred = HTTP::API::Core::RateLimit->from_headers({
    'RateLimit-Used'       => '0',
    'X-RateLimit-Used'     => '9',
    'RateLimit-Resource'   => 'standard',
    'X-RateLimit-Resource' => 'legacy',
    'RateLimit-Remaining'  => ['2', '2'],
    'RateLimit-Reset'      => '10',
    'X-RateLimit-Reset'    => '2000',
    'Retry-After'          => ['0', '0'],
});
is $preferred->used, 0, 'standard zero used takes precedence';
is $preferred->resource, 'standard', 'standard resource takes precedence';
is $preferred->remaining, 2, 'identical repeated quota is accepted';
is $preferred->wait_seconds(now => 1000), 0, 'explicit repeated zero retry delay wins';

for my $case (
    [ [], 'empty array' ],
    [ [undef, undef], 'all undefined' ],
    [ [undef, '0'], 'undefined then zero' ],
    [ ['0', undef], 'zero then undefined' ],
) {
    my ($value, $label) = @$case;
    my $rate = HTTP::API::Core::RateLimit->from_headers({
        'RateLimit-Remaining' => $value,
        'X-RateLimit-Remaining' => '0',
        'Retry-After' => $value,
        'RateLimit-Reset' => '3',
    });
    is $rate->remaining, undef, "$label quota is unknown, not legacy zero";
    ok !$rate->exhausted, "$label quota does not imply exhaustion";
    is $rate->wait_seconds(now => 1000), 3, "$label retry delay falls back to valid reset";
}

for my $pair ([undef, undef], [undef, '0'], ['0', undef]) {
    my $rate = HTTP::API::Core::RateLimit->from_headers({
        'RateLimit-Remaining' => $pair->[0],
        'ratelimit-remaining' => $pair->[1],
        'X-RateLimit-Remaining' => '0',
    });
    is $rate->remaining, undef, 'case variants with undefined values do not invent a quota';
    ok !$rate->exhausted, 'ambiguous case variants do not imply exhaustion';
}

for my $case (
    [ sub { HTTP::API::Core::RateLimit->from_headers([]) },
      qr/rate-limit headers must be a hash reference/, 'invalid header map' ],
    [ sub { HTTP::API::Core::RateLimit->from_headers({ 'Retry-After' => {} }) },
      qr/rate-limit header values must be scalars/, 'reference header' ],
    [ sub { HTTP::API::Core::RateLimit->from_headers({ 'Retry-After' => [undef, {}] }) },
      qr/rate-limit header values must be scalars/, 'nested reference header' ],
    [ sub { HTTP::API::Core::RateLimit->new(remaining => []) },
      qr/rate-limit remaining must be a non-negative number/, 'reference quota' ],
    [ sub { HTTP::API::Core::RateLimit->new(resource => {}) },
      qr/rate-limit resource must be a scalar/, 'reference resource' ],
    [ sub { HTTP::API::Core::RateLimit->new(source => []) },
      qr/rate-limit source must be a scalar/, 'reference source' ],
    [ sub { $mixed->wait_seconds(now => undef) },
      qr/rate-limit now must be a non-negative number/, 'undefined clock' ],
    [ sub { $mixed->wait_seconds(now => []) },
      qr/rate-limit now must be a non-negative number/, 'reference clock' ],
) {
    my ($call, $pattern, $label) = @$case;
    my ($error, @warnings);
    {
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        eval { $call->(); 1 } or $error = $@;
    }
    like $error, $pattern, "$label rejected";
    is_deeply \@warnings, [], "$label rejected without coercion warnings";
}

done_testing;
