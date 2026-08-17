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

done_testing;
