use v5.36;
use strict;
use warnings;

use Test::More;
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC);

use Linux::Event::WebSocket::Server::Connection;
use Linux::Event::WebSocket::_State;

{
    package T::WebSocketConfigFailure;
    use parent 'Linux::Event::WebSocket::Server::Connection';

    our $CLOSE_CALLS = 0;

    sub configure_socket ($self, $fh, $role, $peer) {
        die "synthetic WebSocket socket configuration failure\n";
    }

    sub close ($self, @argument) {
        ++$CLOSE_CALLS;
        return $self->SUPER::close(@argument);
    }
}

my $state = Linux::Event::WebSocket::_State->new(
    endpoint_type    => 'server',
    callbacks        => {},
    close_timeout    => 0,
    max_message_size => 1024,
);

socketpair(my $left, my $right, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
    or die "socketpair: $!";

my $error = do {
    local $@;
    eval {
        T::WebSocketConfigFailure->new(
            fh   => $left,
            data => $state,
        );
        1;
    } ? '' : "$@";
};

like($error, qr/synthetic WebSocket socket configuration failure/,
    'socket configuration failure is preserved');
is($T::WebSocketConfigFailure::CLOSE_CALLS, 0,
    'forced Stream cleanup bypasses WebSocket public close');
ok(!$state->{open},
    'forced cleanup does not mark WebSocket open');
ok(!$state->{closing},
    'forced cleanup does not start graceful WebSocket close');
ok(!defined($state->{engine}),
    'forced cleanup does not initialize the WebSocket engine');
ok(!defined(fileno($left)),
    'forced cleanup still closes the adopted descriptor');

close $right;

done_testing;
