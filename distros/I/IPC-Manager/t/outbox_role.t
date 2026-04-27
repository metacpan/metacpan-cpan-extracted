use Test2::V0;

# A bare-bones consumer to exercise the role's defaults.
package T::Consumer;
use Role::Tiny::With;
with 'IPC::Manager::Role::Outbox';

sub new {
    my ($c, %a) = @_;
    return bless {%a, _SENT => [], _OUTBOX => {}, _BLOCKING => 1}, $c;
}

sub _outbox_try_write {
    my ($self, $peer, $payload) = @_;
    return 0 if defined $self->{_eagain_after} && @{$self->{_SENT}} >= $self->{_eagain_after};
    push @{$self->{_SENT}} => [$peer, $payload];
    return 1;
}

sub _outbox_writable_handle  { undef }
sub _outbox_set_blocking     { $_[0]->{_BLOCKING} = $_[1] }
sub _outbox_can_send         { 1 }

package main;

ok(IPC::Manager::Role::Outbox->can('try_send_message'),  'role provides try_send_message');
ok(IPC::Manager::Role::Outbox->can('drain_pending'),     'role provides drain_pending');
ok(IPC::Manager::Role::Outbox->can('pending_sends'),      'role provides pending_sends');
ok(IPC::Manager::Role::Outbox->can('have_pending_sends'), 'role provides have_pending_sends');
ok(IPC::Manager::Role::Outbox->can('pending_sends_to'),   'role provides pending_sends_to');
ok(IPC::Manager::Role::Outbox->can('have_writable_handles'), 'role provides have_writable_handles');
ok(IPC::Manager::Role::Outbox->can('send_blocking'),     'role provides send_blocking');
ok(IPC::Manager::Role::Outbox->can('set_send_blocking'), 'role provides set_send_blocking');
ok(IPC::Manager::Role::Outbox->can('can_send_to'),       'role provides can_send_to');

my $c = T::Consumer->new(_eagain_after => 2);

is($c->send_blocking, 1, 'default blocking flag is 1');

is($c->try_send_message(peer1 => "msg1"), 1, "first send delivered");
is($c->try_send_message(peer1 => "msg2"), 1, "second send delivered");
is($c->try_send_message(peer1 => "msg3"), 0, "third send queued (EAGAIN)");
is($c->pending_sends, 1, "one message pending total");
ok($c->have_pending_sends, "have_pending_sends sees the backlog");
is($c->pending_sends_to('peer1'), 1, "one message pending for peer1");
is($c->pending_sends_to('peer2'), 0, "no messages pending for peer2");

# Pretend the FIFO drained -- clear the EAGAIN floor and drain.
delete $c->{_eagain_after};
my $delivered = $c->drain_pending;
is($delivered, 1, "drain_pending delivered the queued message");
is($c->pending_sends, 0, "queue is empty after drain");
ok(!$c->have_pending_sends, "have_pending_sends false after drain");

is(scalar @{$c->{_SENT}}, 3, "all three messages reached the transport");

# Toggling blocking propagates to the consumer.
$c->set_send_blocking(0);
is($c->send_blocking, 0, 'set_send_blocking(0) flips the getter');
is($c->{_BLOCKING},   0, 'set_send_blocking propagated to consumer hook');
$c->set_send_blocking(1);
is($c->send_blocking, 1, 'set_send_blocking(1) flips back');
is($c->{_BLOCKING},   1, 'consumer hook saw the second flip');

# can_send_to: clear when no backlog and the consumer says writable.
ok($c->can_send_to('peer2'), 'can_send_to returns true when nothing queued');

# can_send_to: false while there is a backlog for that peer.
$c->{_eagain_after} = 0;
is($c->try_send_message(peer3 => 'q1'), 0, 'queued for peer3');
ok(!$c->can_send_to('peer3'), 'can_send_to returns false while queue is non-empty');

done_testing;
