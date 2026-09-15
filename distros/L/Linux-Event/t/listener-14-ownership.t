use v5.36;
use strict;
use warnings;
use Test::More;
use Fcntl qw(F_GETFD F_GETFL FD_CLOEXEC O_NONBLOCK);
use Socket qw(
    AF_INET SOCK_STREAM SOL_SOCKET SO_ACCEPTCONN
    INADDR_LOOPBACK pack_sockaddr_in
);

use Linux::Event::Loop;
use Linux::Event::IO::Sock::Listener;

{
    package T::OwnedStream;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub on_data ($stream, $bytes) { }
}

sub raw_listener () {
    socket(my $fh, AF_INET, SOCK_STREAM, 0) or die "socket: $!";
    bind($fh, pack_sockaddr_in(0, INADDR_LOOPBACK)) or die "bind: $!";
    listen($fh, 16) or die "listen: $!";
    return $fh;
}

my $borrowed = raw_listener();
my $borrowed_fd = fileno($borrowed);
my $loop = Linux::Event::Loop->new;
my $listener = Linux::Event::IO::Sock::Listener->new(
    stream => { class => 'T::OwnedStream' }, loop => $loop, fh => $borrowed,
);
is($listener->fd, $borrowed_fd, 'adopted listener preserves descriptor');
ok(fcntl($borrowed, F_GETFL, 0) & O_NONBLOCK,
    'adopted listener is made nonblocking');
ok(fcntl($borrowed, F_GETFD, 0) & FD_CLOEXEC,
    'adopted listener is made close-on-exec');
$listener->close;
is($listener->state, 'closed', 'borrowed listener wrapper closes');
ok(!defined($listener->loop), 'closed Listener releases its Loop');
ok(!defined($listener->fd), 'closed wrapper releases borrowed handle reference');
ok(defined(fileno($borrowed)), 'borrowed listening handle remains open');
ok(unpack('i', getsockopt($borrowed, SOL_SOCKET, SO_ACCEPTCONN)),
    'borrowed handle remains a listener');
close $borrowed;

my $detached_source = raw_listener();
my $detached_fd = fileno($detached_source);
my $loop2 = Linux::Event::Loop->new;
my $detaching = Linux::Event::IO::Sock::Listener->new(
    stream => { class => 'T::OwnedStream' },
    loop => $loop2, fh => $detached_source, owns_socket => 1,
);
my $detached = $detaching->detach;
is($detaching->state, 'detached', 'detach ends Listener lifecycle');
ok(!defined($detaching->loop), 'detached Listener releases its Loop');
ok(!defined($detaching->fd), 'detached listener drops object handle');
is(fileno($detached), $detached_fd, 'detach returns the listening handle');
close $detached;

our $FAILURE_CALLBACK_LOOP;
{
    package T::FailureListener;
    use parent 'Linux::Event::IO::Sock::Listener';
    sub on_error ($self, $error) {
        $main::FAILURE_CALLBACK_LOOP = $self->loop;
    }
}

my $failure_source = raw_listener();
my $failure_loop = Linux::Event::Loop->new;
my $failing = T::FailureListener->new(
    stream => { class => 'T::OwnedStream' }, # required
    loop         => $failure_loop,    # optional
    fh           => $failure_source,  # required for adoption
);
$failing->_listener_error_ready;
is($failing->state, 'failed', 'terminal listener event enters failed state');
is($FAILURE_CALLBACK_LOOP, $failure_loop,
    'terminal on_error retains the Listener Loop during callback');
ok(!defined($failing->loop),
    'terminal listener error releases Loop after callback');
close $failure_source;

my $throwing_source = raw_listener();
my $throwing_loop = Linux::Event::Loop->new;
my $throwing = Linux::Event::IO::Sock::Listener->new(
    stream => { class => 'T::OwnedStream' }, # required
    loop         => $throwing_loop,   # optional
    fh           => $throwing_source, # required for adoption
);
my $failure = eval { $throwing->_listener_error_ready; undef } // $@;
like("$failure", qr/listener failed/,
    'base terminal error policy still propagates');
ok(!defined($throwing->loop),
    'throwing terminal error callback still releases Listener Loop');
close $throwing_source;

done_testing;
