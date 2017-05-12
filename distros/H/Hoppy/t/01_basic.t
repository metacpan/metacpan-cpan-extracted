use strict;
use warnings;
use Hoppy;
use Test::More tests => 7;

my $server = Hoppy->new;

isa_ok( $server, 'Hoppy' );
isa_ok( $server->handler->{Connected},    'Hoppy::TCPHandler::Connected' );
isa_ok( $server->handler->{Input},        'Hoppy::TCPHandler::Input' );
isa_ok( $server->handler->{Disconnected}, 'Hoppy::TCPHandler::Disconnected' );
isa_ok( $server->handler->{Error},        'Hoppy::TCPHandler::Error' );
isa_ok( $server->formatter,               'Hoppy::Formatter::JSON' );
isa_ok( $server->room,                    'Hoppy::Room::Memory' );

POE::Session->create(
    inline_states => {
        _start => sub {
            $server->stop;
        },
    }
);

$server->start;

