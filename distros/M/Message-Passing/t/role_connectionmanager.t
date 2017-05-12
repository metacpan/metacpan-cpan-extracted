use strict;
use warnings;
use Test::More;
use AnyEvent;

{
    package Connection::Subscriber;
    use Moo;
    use namespace::clean -except => 'meta';

    has am_connected => ( is => 'rw' );

    sub connected {
        shift->am_connected(1);
    }

    sub disconnected {
        shift->am_connected(0);
    }
}
{
    package Some::Shonky::Async::Code;
    use Moo;
    use namespace::clean -except => 'meta';

}

{
    package My::Connection::Wrapper;
    use Moo;
    use Scalar::Util qw/ weaken /;
    use namespace::clean -except => 'meta';

    with 'Message::Passing::Role::ConnectionManager';

    has '+timeout' => (
        default => sub { 0.1 },
    );

    has '+reconnect_after' => (
        default => sub { 0.1 },
    );

    sub _build_connection {
        my $self = shift;
        weaken($self);
        my $client = Some::Shonky::Async::Code->new;
        # Real code now has something like:
        # $client->add_connect_callback(sub {
        #   $self->_set_connected(1);
        # });
        # instead we'll simulate that below..
        return $client;
    }
}

my $sub = Connection::Subscriber->new;
ok !exists($sub->{am_connected});

my $i = My::Connection::Wrapper->new;
ok $i;
ok $i->{connection};
isa_ok $i->{connection}, 'Some::Shonky::Async::Code';

$i->subscribe_to_connect($sub);
ok !exists($sub->{am_connected});

$i->_set_connected(1);
ok exists($sub->{am_connected});
ok $sub->{am_connected};
Scalar::Util::weaken($sub);

my $sub2 = Connection::Subscriber->new;
$i->subscribe_to_connect($sub2);
ok $sub2->{am_connected};

is_deeply $i->_connect_subscribers, [$sub2];
ok !$sub;

# Test connectiomn timeout
$i = My::Connection::Wrapper->new;
my $cv = AnyEvent->condvar;
{
    my $t; $t = AnyEvent->timer(
        after => 0.11,
        cb => sub { undef $t; $cv->send },
    );
}
ok $i->{connection};
$cv->recv;
ok !$i->{connection};

# Test reconnect
$cv = AnyEvent->condvar;
{
    my $t; $t = AnyEvent->timer(
        after => 0.11,
        cb => sub { undef $t; $cv->send },
    );
}
$cv->recv;
$i->_set_connected(1);
ok $i->{connection};
my ($c, $d) = (0,0);
no warnings 'redefine';
*My::Connection::Wrapper::_build_timeout_timer = sub { $c++; shift->next::method(@_) };
*My::Connection::Wrapper::_build_reconnect_timer = sub { $d++; shift->next::method(@_) };
$cv = AnyEvent->condvar;
{
    my $t; $t = AnyEvent->timer(
        after => 0.5,
        cb => sub { undef $t; $cv->send },
    );
}
$cv->recv;
is $c, 0;
is $d, 0;

done_testing;

