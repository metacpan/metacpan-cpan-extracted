use strict;
use warnings;
use Test::More;
use EV;
use EV::Telegram::TDLib;

my @sent;
{
    no warnings 'redefine';
    *EV::Telegram::TDLib::_send = sub { push @sent, $_[1]; };
}

# one dying callback during close must not skip the rest of the chain:
# closed can only ever run once, so an unwound loop loses the rest
my @errors;
my $td = EV::Telegram::TDLib->new(
    api_id    => 1,
    api_hash  => 'x',
    auto_auth => 0,
    database_directory => 't/tmp-close-chain',
    on_error => sub { push @errors, $_[0] },
    on_close => sub { push @errors, 'closed-cleanly' },
);

my @fired;
$td->send({ '@type' => 'getMe' }, sub { die "boom in first\n" });
$td->send({ '@type' => 'getMe' }, sub { push @fired, 'second' });
my $closed = 0;
$td->close(sub { $closed = 1 });

eval {
    $td->inject_raw(q({"@type":"updateAuthorizationState","authorization_state":{"@type":"authorizationStateClosed"}}));
    1;
} or do {
    diag "injection died: $@" if $ENV{TEST_VERBOSE};
};

is(scalar @fired, 1, 'a dying callback does not skip the other pending request');
is($fired[0], 'second', 'the surviving pending callback fired');
ok($closed, 'the close callback still fired');
is(scalar @errors, 2, 'the die was reported and on_close still ran');
like($errors[0], qr/boom in first/, 'the trapped error reached on_error');
is($errors[1], 'closed-cleanly', 'on_close fired after the trapped die');
is($td->auth_state, 'authorizationStateClosed', 'reached the closed state');

done_testing;
