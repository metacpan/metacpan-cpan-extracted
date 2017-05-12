use strict;
use warnings;
use Hoppy;
use Hoppy::Room::Memory;
use Test::More tests => 18;

{
    my $room = Hoppy::Room::Memory->new;
    isa_ok( $room, 'Hoppy::Room::Memory' );
    can_ok( $room, 'new' );
    can_ok( $room, 'login' );
    can_ok( $room, 'logout' );
    can_ok( $room, 'create_room' );
    can_ok( $room, 'delete_room' );
    can_ok( $room, 'fetch_user_from_user_id' );
    can_ok( $room, 'fetch_user_from_session_id' );
    can_ok( $room, 'fetch_users_from_room_id' );
}

{
    my $server = Hoppy->new;
    my $room   = $server->room;
    $room->create_room('room1');
    $room->create_room('room2');

    my @room_list = keys %{ $room->{rooms} };
    is_deeply(
        \@room_list,
        [ 'global', 'room1', 'room2' ],
        'create_room() method ok'
    );

    $room->delete_room('room2');
    @room_list = keys %{ $room->{rooms} };
    is_deeply( \@room_list, [ 'global', 'room1' ], 'delete_room() method ok' );

    &finish($server);
}

{
    my $server = Hoppy->new;
    my $room   = $server->room;
    $room->create_room('room1');
    $room->create_room('room2');

    $room->login( { user_id => 'hoge', session_id => 1 } );
    $room->login( { user_id => 'fuga', session_id => 2 } );
    $room->login( { user_id => 'foo',  session_id => 3, room_id => 'room1' } );
    $room->login( { user_id => 'bar',  session_id => 4, room_id => 'room2' } );

    is_deeply(
        $room->{where_in},
        {
            'bar'  => 'room2',
            'fuga' => 'global',
            'foo'  => 'room1',
            'hoge' => 'global'
        },
        'login() method ok'
    );

    my $correct = bless(
        {
            'session_id' => 1,
            'user_id'    => 'hoge'
        },
        'Hoppy::User'
    );

    my $user = $room->fetch_user_from_user_id('hoge');
    is_deeply( $user, $correct, 'fetch_user_from_user_id() method ok' );

    $user = $room->fetch_user_from_session_id(1);
    is_deeply( $user, $correct, 'fetch_user_from_session_id() method ok' );

    my $users = $room->fetch_users_from_room_id('global');
    is_deeply(
        $users,
        [
            bless(
                {
                    'session_id' => 2,
                    'user_id'    => 'fuga'
                },
                'Hoppy::User'
            ),
            bless(
                {
                    'session_id' => 1,
                    'user_id'    => 'hoge'
                },
                'Hoppy::User'
            )
        ],
        'fetch_users_from_room_id() method ok'
    );

    $room->logout( { user_id => 'foo' } );
    my $num = keys %{ $room->{rooms}->{room1} };
    is( $num, 0, 'logout() method 1/3 ok' );
    my $foo = $room->{what_room}->{foo};
    is( !defined($foo), 1, 'logout() method 2/3 ok' );
    my ($not_authorized) =
      keys %{ $room->context->{not_authorized} };
    is( $not_authorized, 3, 'logout() method 3/3 ok' );

    &finish($server);
}

sub finish {
    my $server = shift;
    POE::Session->create(
        inline_states => {
            _start => sub {
                $server->stop;
            },
        }
    );
    $server->start;
}
