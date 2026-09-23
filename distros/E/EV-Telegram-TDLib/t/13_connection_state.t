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

my (@states, @updates);
my $td = EV::Telegram::TDLib->new(
    api_id   => 1,
    api_hash => 'x',
    auto_auth => 0,
    database_directory => 't/tmp-conn',
    on_connection_state => sub { push @states, $_[0] },
);
$td->on_update(sub { push @updates, $_[0] });

is($td->connection_state, undef, 'no state before the first update');

$td->inject_raw(q({"@type":"updateConnectionState","state":{"@type":"connectionStateConnecting"}}));
is($td->connection_state, 'connectionStateConnecting', 'state tracked from updateConnectionState');
is(scalar @states, 1, 'on_connection_state fired from the constructor option');
is($states[0], 'connectionStateConnecting', 'on_connection_state got the state name');
is($updates[-1]{'@type'}, 'updateConnectionState', 'the update still reaches on_update');

$td->inject_raw(q({"@type":"updateConnectionState","state":{"@type":"connectionStateWaitingForNetwork"}}));
is($td->connection_state, 'connectionStateWaitingForNetwork', 'the state is overwritten, not accumulated');
is(scalar @states, 2, 'every change fires the handler');

my @setter_states;
my $prev = $td->on_connection_state(sub { push @setter_states, $_[0] });
ok($prev, 'the setter returns the previous handler');
$td->inject_raw(q({"@type":"updateConnectionState","state":{"@type":"connectionStateReady"}}));
is(scalar @states, 2, 'the setter replaced the constructor handler');
is($setter_states[0], 'connectionStateReady', 'the setter handler got the state');
is($td->connection_state, 'connectionStateReady', 'the ready state is tracked');

$td->inject_raw(q({"@type":"updateConnectionState"}));
is($td->connection_state, 'connectionStateReady', 'a stateless update does not clobber the state');
$td->inject_raw(q({"@type":"updateConnectionState","state":{"@type":""}}));
is($td->connection_state, 'connectionStateReady', 'an empty state name does not clobber the state');
is(scalar @setter_states, 1, 'malformed updates fire no handler');

$td->close;
$td->inject_raw(q({"@type":"updateAuthorizationState","authorization_state":{"@type":"authorizationStateClosed"}}));
is($td->connection_state, 'connectionStateReady', 'the state survives close');

done_testing;
