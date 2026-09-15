use v5.36;
use strict;
use warnings;

use Test::More;
use Scalar::Util qw(refaddr);
use Socket qw(AF_INET AF_INET6);

use Linux::Event::Loop;
use Linux::Event::IO::Sock::Listener;
use Linux::Event::IO::Sock::Stream;
use Linux::Event::IO::Sock::Stream;
use Linux::Event::_Resolver ();
use Linux::Event::Kernel::Timer;

our ($RESOLVED, $READY, $ERROR, $LOOP);

{
    package T::ResolverTarget;
    sub new ($class, $loop) { bless { loop => $loop }, $class }
    sub _resolver_completed ($self, $result) {
        $main::RESOLVED = $result;
        $self->{loop}->stop;
    }
}

{
    package T::ResolverStop;
    use parent 'Linux::Event::Kernel::Timer';
    sub on_timer ($timer) { $timer->data->stop }
}

{
    package T::ResolverServer;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub on_data ($stream, $bytes) { }
}

{
    package T::ResolverClient;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub on_data ($stream, $bytes) { }
    sub on_ready ($stream) {
        $main::READY++;
        $stream->close;
        $main::LOOP->stop;
    }
    sub on_error ($stream, $error) {
        $main::ERROR = $error;
        $main::LOOP->stop;
    }
}

my $order = Linux::Event::_Socket::Connection::_happy_eyeballs_order([
    { family => AF_INET6, sockaddr => 'v6-a' },
    { family => AF_INET6, sockaddr => 'v6-b' },
    { family => AF_INET,  sockaddr => 'v4-a' },
    { family => AF_INET,  sockaddr => 'v4-b' },
]);
is_deeply([ map { $_->{sockaddr} } @$order ],
    [qw(v6-a v4-a v6-b v4-b)],
    'resolved IPv6 and IPv4 candidates are interleaved');

my $resolver_loop = Linux::Event::Loop->new;
my $resolver = Linux::Event::_Resolver->for_loop($resolver_loop);
my $target = T::ResolverTarget->new($resolver_loop);
my $request = $resolver->submit($target, 'localhost', 80);
ok($request, 'private resolver accepts a hostname request');
$resolver_loop->add(T::ResolverStop->new(after => 2, data => $resolver_loop));
$resolver_loop->run;
is($RESOLVED->{error_code}, 0, 'native worker resolves localhost');
ok(@{ $RESOLVED->{candidates} } >= 1,
    'eventfd completion carries packed address candidates');

$RESOLVED = undef;
$request = $resolver->submit($target, 'localhost', 80);
ok($resolver->cancel($request), 'pending delivery can be cancelled');
$resolver_loop->add(T::ResolverStop->new(after => 0.05, data => $resolver_loop));
$resolver_loop->run;
ok(!defined $RESOLVED, 'late resolver completion is discarded after cancellation');

$LOOP = Linux::Event::Loop->new;
my $listener = Linux::Event::IO::Sock::Listener->new(
    stream => { class => 'T::ResolverServer' }, host => '127.0.0.1', port => 0,
);
$LOOP->add($listener);
my $client = T::ResolverClient->connect(
    host => 'localhost', port => $listener->port, timeout => 2,
);
is($client->state, 'unattached',
    'hostname Stream construction does not synchronously resolve');
$LOOP->add($client);
$LOOP->run;
is($ERROR, undef, 'hostname connection has no error');
is($READY, 1, 'async resolution continues into a connected Stream');
$listener->close;

done_testing;
