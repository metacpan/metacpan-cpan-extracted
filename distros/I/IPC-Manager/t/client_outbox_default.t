use Test2::V0;
use IPC::Manager::Client;

# Minimal Client subclass that only implements send_message.
package T::Blocking;
use parent -norequire, 'IPC::Manager::Client';
sub _viable { 1 }
sub init {
    my $self = shift;
    $self->{+IPC::Manager::Client::PID()}        //= $$;
    $self->{+IPC::Manager::Client::ID()}         //= 't';
    $self->{+IPC::Manager::Client::ROUTE()}      //= '/tmp';
    $self->{+IPC::Manager::Client::SERIALIZER()} //= 'JSON';
}
sub send_message {
    my ($self, $peer, $content) = @_;
    push @{$self->{_sent}} => [$peer, $content];
    return 1;
}

package main;

my $c = T::Blocking->new(id => 't');

ok($c->can('try_send_message'),   'try_send_message available on base class');
is($c->try_send_message(p1 => "x"), 1, 'default try_send_message returns 1');
is($c->pending_sends,         0,   'default pending_sends is 0');
ok(!$c->have_pending_sends,        'default have_pending_sends is false');
is($c->pending_sends_to('p1'), 0,  'default pending_sends_to is 0');
is($c->drain_pending,    0,        'default drain_pending is 0');
ok(!$c->have_writable_handles,     'default have_writable_handles is false');
is([$c->writable_handles], [],     'default writable_handles is empty');

is($c->send_blocking, 1,          'default send_blocking is 1');
ok(lives { $c->set_send_blocking(0) }, 'set_send_blocking is a no-op for clients without role');
is($c->send_blocking, 1,          'send_blocking still 1 after set_send_blocking(0) on base class');

ok($c->can_send_to('any'),         'default can_send_to returns true');

is($c->{_sent}, [['p1', 'x']],     'message reached send_message');

done_testing;
