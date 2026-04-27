use Test2::V0;

use Time::HiRes qw/time sleep/;

# Build a tiny consuming class purely to exercise the role's API surface.
{
    package TestConn;
    use strict;
    use warnings;
    use Role::Tiny::With;
    sub new {
        my $class = shift;
        return bless { _conns => {}, _closed => [] }, $class;
    }
    sub _connections { $_[0]->{_conns} }
    sub _close_connection {
        my ($self, $peer) = @_;
        push @{$self->{_closed}} => $peer;
        delete $self->{_conns}->{$peer};
    }
    with 'IPC::Manager::Role::Client::Connection';
}

my $c = TestConn->new;

subtest 'empty' => sub {
    is([$c->connections], [], 'no connections');
    ok(!$c->has_connection('a'), 'no connection to a');
    is($c->last_activity('a'), undef, 'no last_activity');
    is($c->disconnect_connection('a'), 0, 'disconnect missing returns 0');
    is($c->close_idle_connections(0), 0, 'close_idle on empty returns 0');
};

subtest 'populated' => sub {
    my $now = time;
    $c->{_conns}->{alpha} = { fh => 'fakeA', last_active => $now - 10 };
    $c->{_conns}->{beta}  = { fh => 'fakeB', last_active => $now };

    is([$c->connections], ['alpha', 'beta'], 'sorted connections');
    ok($c->has_connection('alpha'), 'has alpha');
    ok($c->has_connection('beta'),  'has beta');
    ok(!$c->has_connection('gamma'), 'no gamma');

    cmp_ok($c->last_activity('alpha'), '<=', $now - 9, 'alpha last_activity');
    cmp_ok($c->last_activity('beta'),  '>=', $now - 1, 'beta last_activity');
};

subtest 'disconnect' => sub {
    my $n = $c->disconnect_connection('alpha');
    is($n, 1, 'disconnected alpha');
    ok(!$c->has_connection('alpha'), 'alpha gone');
    is($c->{_closed}->[-1], 'alpha', '_close_connection called for alpha');
};

subtest 'close_idle_connections' => sub {
    my $now = time;
    $c->{_conns}->{old}    = { fh => 'fakeO', last_active => $now - 100 };
    $c->{_conns}->{recent} = { fh => 'fakeR', last_active => $now };

    my $closed = $c->close_idle_connections(50);
    is($closed, 1, 'closed 1 idle connection');
    ok(!$c->has_connection('old'),    'old gone');
    ok($c->has_connection('recent'),  'recent kept');
};

done_testing;
