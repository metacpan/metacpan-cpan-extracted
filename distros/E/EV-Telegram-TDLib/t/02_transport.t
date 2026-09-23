use strict;
use warnings;
use Test::More;
use EV;
use EV::Telegram::TDLib;

my @seen;
EV::Telegram::TDLib::_set_dispatch(sub {
    my ($client_id, $json) = @_;
    push @seen, [$client_id, $json];
    my $joined = join '', map { $_->[1] } @seen;
    EV::break if $joined =~ /updateAuthorizationState/
              && $joined =~ /"\@extra":"probe-1"/;
});

my $id = EV::Telegram::TDLib::_create_client_id();
ok $id > 0, "got a client id ($id)";

EV::Telegram::TDLib::_send($id, '{"@type":"getMe","@extra":"probe-1"}');

# the loop has not run yet, so ev_now is still the time EV was loaded
EV::now_update();
my $watchdog = EV::timer 15, 0, sub { fail('timed out waiting for TDLib'); EV::break };
EV::run;
$watchdog->stop;

ok scalar @seen, 'the loop was woken by the reader thread';
is $seen[0][0], $id, 'messages are tagged with the originating client id';

my $joined = join '', map { $_->[1] } @seen;
like $joined, qr/updateAuthorizationState/, 'got the authorization state update';
like $joined, qr/"\@extra":"probe-1"/, 'our @extra came back verbatim';

# this test drives the raw client id directly, so the END-block shutdown --
# which only knows about clients made through new() -- will not close it.
# Leaving TDLib a live client at exit aborts while its statics tear down,
# rarely on a fast build and reliably under a sanitizer.
my $closed = 0;
EV::Telegram::TDLib::_set_dispatch(sub {
    my (undef, $json) = @_;
    $closed = 1 if $json =~ /authorizationStateClosed/;
    EV::break if $closed;
});
EV::Telegram::TDLib::_send($id, '{"@type":"close"}');
# bound on the flag, never the clock: a re-entered RUN_ONCE with no events
# left blocks forever, and EV::run with no watchers returns at once
my $gave_up = 0;
my $shut = EV::timer 15, 0, sub { $gave_up = 1; EV::break };
EV::run(EV::RUN_ONCE) while !$closed && !$gave_up;
$shut->stop;
ok $closed, 'the raw client closed before exit';

done_testing;
