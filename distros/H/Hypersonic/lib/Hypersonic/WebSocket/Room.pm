package Hypersonic::WebSocket::Room;
use strict;
use warnings;

# Hypersonic::WebSocket::Room - XS Broadcast support for WebSocket connections
#
# All room management is done in C via XS::JIT::Builder.
# This module generates XS functions callable from Perl.

our $VERSION = '0.12';

# Maximum rooms and clients per room
use constant MAX_ROOMS => 1000;
use constant MAX_CLIENTS_PER_ROOM => 10000;

# Generate all Room XS code
sub generate_c_code {
    my ($class, $builder, $opts) = @_;
    $opts //= {};
    
    my $max_rooms = $opts->{max_rooms} // MAX_ROOMS;
    my $max_clients = $opts->{max_clients_per_room} // MAX_CLIENTS_PER_ROOM;
    
    # Generate room registry (static C)
    $class->gen_room_registry($builder, $max_rooms, $max_clients);
    
    # Generate XS functions
    $class->gen_xs_new($builder);
    $class->gen_xs_destroy($builder);
    $class->gen_xs_join($builder);
    $class->gen_xs_leave($builder);
    $class->gen_xs_has($builder);
    $class->gen_xs_broadcast($builder);
    $class->gen_xs_broadcast_binary($builder);
    $class->gen_xs_count($builder);
    $class->gen_xs_count_open($builder);
    $class->gen_xs_close_all($builder);
    $class->gen_xs_name($builder);
    $class->gen_xs_clear($builder);
    $class->gen_xs_clients($builder);
    
    return $builder;
}

# Generate room registry (C data structures)
sub gen_room_registry {
    my ($class, $builder, $max_rooms, $max_clients) = @_;
    
    $builder->comment('Room registry')
      ->line('#define ROOM_MAX_ROOMS ' . $max_rooms)
      ->line('#define ROOM_MAX_CLIENTS ' . $max_clients)
      ->blank
      ->comment('Room structure')
      ->line('typedef struct {')
      ->line('    int active;')
      ->line('    char name[256];')
      ->line('    int client_fds[ROOM_MAX_CLIENTS];')
      ->line('    int client_count;')
      ->line('} WSRoom;')
      ->blank
      ->line('static WSRoom room_registry[ROOM_MAX_ROOMS];')
      ->line('static int room_count = 0;')
      ->blank
      ->comment('Find room by name, returns index or -1')
      ->line('static int find_room_by_name(const char* name) {')
      ->line('    int i;')
      ->line('    for (i = 0; i < ROOM_MAX_ROOMS; i++) {')
        ->if('room_registry[i].active && strcmp(room_registry[i].name, name) == 0')
          ->line('return i;')
        ->endif
      ->line('    }')
      ->line('return -1;')
      ->line('}')
      ->blank
      ->comment('Find free room slot')
      ->line('static int find_free_room_slot() {')
      ->line('    int i;')
      ->line('    for (i = 0; i < ROOM_MAX_ROOMS; i++) {')
        ->if('!room_registry[i].active')
          ->line('return i;')
        ->endif
      ->line('    }')
      ->line('return -1;')
      ->line('}')
      ->blank
      ->comment('Extract fd from SV - handles both integer and WebSocket object')
      ->line('static int extract_fd(SV* sv) {')
      ->if('SvROK(sv)')
        ->comment('Reference - check if hash with fd key')
        ->line('SV* deref = SvRV(sv);')
        ->if('SvTYPE(deref) == SVt_PVHV')
          ->line('HV* hv = (HV*)deref;')
          ->line('SV** fd_sv = hv_fetchs(hv, "fd", 0);')
          ->if('fd_sv && *fd_sv')
            ->line('return SvIV(*fd_sv);')
          ->endif
        ->endif
        ->line('return -1;')
      ->else
        ->comment('Plain integer')
        ->line('return SvIV(sv);')
      ->endif
      ->line('}')
      ->blank;
    
    return $builder;
}

# XS: new(name) - returns blessed object
sub gen_xs_new {
    my ($class, $builder) = @_;
    
    $builder->xs_function('xs_room_new')
      ->xs_preamble
      ->line('STRLEN name_len;')
      ->line('const char* name;')
      ->line('int room_id;')
      ->line('WSRoom* room;')
      ->line('SV* room_sv;')
      ->line('SV* room_ref;')
      ->blank
      ->if('items != 2')
        ->line('croak("Usage: Hypersonic::WebSocket::Room->new(name)");')
      ->endif
      ->blank
      ->line('name = SvPV(ST(1), name_len);')
      ->blank
      ->comment('Check if room already exists')
      ->line('room_id = find_room_by_name(name);')
      ->if('room_id < 0')
        ->comment('Find free slot')
        ->line('room_id = find_free_room_slot();')
        ->if('room_id < 0')
          ->line('croak("Maximum rooms reached");')
        ->endif
        ->blank
        ->line('room = &room_registry[room_id];')
        ->line('room->active = 1;')
        ->if('name_len >= sizeof(room->name)')
          ->line('name_len = sizeof(room->name) - 1;')
        ->endif
        ->line('memcpy(room->name, name, name_len);')
        ->line('room->name[name_len] = \'\\0\';')
        ->line('room->client_count = 0;')
        ->line('memset(room->client_fds, -1, sizeof(room->client_fds));')
        ->line('room_count++;')
      ->endif
      ->blank
      ->comment('Create blessed object: bless \\$room_id, class')
      ->line('room_sv = newSViv(room_id);')
      ->line('room_ref = newRV_noinc(room_sv);')
      ->line('sv_bless(room_ref, gv_stashpv("Hypersonic::WebSocket::Room", GV_ADD));')
      ->line('ST(0) = sv_2mortal(room_ref);')
      ->line('XSRETURN(1);')
      ->xs_end
      ->blank;
    
    return $builder;
}

# XS: destroy() - instance method
sub gen_xs_destroy {
    my ($class, $builder) = @_;
    
    $builder->xs_function('xs_room_destroy')
      ->xs_preamble
      ->if('items != 1')
        ->line('croak("Usage: $room->destroy()");')
      ->endif
      ->blank
      ->line('int room_id = SvIV(SvRV(ST(0)));')
      ->blank
      ->if('room_id < 0 || room_id >= ROOM_MAX_ROOMS')
        ->line('XSRETURN_NO;')
      ->endif
      ->if('!room_registry[room_id].active')
        ->line('XSRETURN_NO;')
      ->endif
      ->blank
      ->line('memset(&room_registry[room_id], 0, sizeof(WSRoom));')
      ->line('room_count--;')
      ->line('XSRETURN_YES;')
      ->xs_end
      ->blank;
    
    return $builder;
}

# XS: join(fd|ws) - instance method
sub gen_xs_join {
    my ($class, $builder) = @_;
    
    $builder->xs_function('xs_room_join')
      ->xs_preamble
      ->line('int room_id;')
      ->line('int fd;')
      ->line('int i;')
      ->line('WSRoom* room;')
      ->blank
      ->if('items != 2')
        ->line('croak("Usage: $room->join(fd)");')
      ->endif
      ->blank
      ->line('room_id = SvIV(SvRV(ST(0)));')
      ->line('fd = extract_fd(ST(1));')
      ->blank
      ->if('fd < 0')
        ->line('XSRETURN_NO;')
      ->endif
      ->if('room_id < 0 || room_id >= ROOM_MAX_ROOMS')
        ->line('XSRETURN_NO;')
      ->endif
      ->if('!room_registry[room_id].active')
        ->line('XSRETURN_NO;')
      ->endif
      ->blank
      ->line('room = &room_registry[room_id];')
      ->blank
      ->comment('Check if already in room')
      ->line('for (i = 0; i < room->client_count; i++) {')
        ->if('room->client_fds[i] == fd')
          ->line('XSRETURN_YES;')
        ->endif
      ->line('}')
      ->blank
      ->comment('Add to room')
      ->if('room->client_count >= ROOM_MAX_CLIENTS')
        ->line('XSRETURN_NO;')
      ->endif
      ->blank
      ->line('room->client_fds[room->client_count++] = fd;')
      ->line('XSRETURN_YES;')
      ->xs_end
      ->blank;
    
    return $builder;
}

# XS: leave(fd|ws) - instance method
sub gen_xs_leave {
    my ($class, $builder) = @_;
    
    $builder->xs_function('xs_room_leave')
      ->xs_preamble
      ->line('int room_id;')
      ->line('int fd;')
      ->line('int i;')
      ->line('WSRoom* room;')
      ->blank
      ->if('items != 2')
        ->line('croak("Usage: $room->leave(fd)");')
      ->endif
      ->blank
      ->line('room_id = SvIV(SvRV(ST(0)));')
      ->line('fd = extract_fd(ST(1));')
      ->blank
      ->if('fd < 0')
        ->line('XSRETURN_NO;')
      ->endif
      ->if('room_id < 0 || room_id >= ROOM_MAX_ROOMS')
        ->line('XSRETURN_NO;')
      ->endif
      ->if('!room_registry[room_id].active')
        ->line('XSRETURN_NO;')
      ->endif
      ->blank
      ->line('room = &room_registry[room_id];')
      ->blank
      ->comment('Find and remove')
      ->line('for (i = 0; i < room->client_count; i++) {')
        ->if('room->client_fds[i] == fd')
          ->comment('Shift remaining down')
          ->line('memmove(&room->client_fds[i], &room->client_fds[i+1], (room->client_count - i - 1) * sizeof(int));')
          ->line('room->client_count--;')
          ->line('XSRETURN_YES;')
        ->endif
      ->line('}')
      ->blank
      ->line('XSRETURN_NO;')
      ->xs_end
      ->blank;
    
    return $builder;
}

# XS: has(fd|ws) - instance method
sub gen_xs_has {
    my ($class, $builder) = @_;
    
    $builder->xs_function('xs_room_has')
      ->xs_preamble
      ->line('int room_id;')
      ->line('int fd;')
      ->line('int i;')
      ->line('WSRoom* room;')
      ->blank
      ->if('items != 2')
        ->line('croak("Usage: $room->has(fd)");')
      ->endif
      ->blank
      ->line('room_id = SvIV(SvRV(ST(0)));')
      ->line('fd = extract_fd(ST(1));')
      ->blank
      ->if('fd < 0')
        ->line('XSRETURN_NO;')
      ->endif
      ->if('room_id < 0 || room_id >= ROOM_MAX_ROOMS')
        ->line('XSRETURN_NO;')
      ->endif
      ->if('!room_registry[room_id].active')
        ->line('XSRETURN_NO;')
      ->endif
      ->blank
      ->line('room = &room_registry[room_id];')
      ->line('for (i = 0; i < room->client_count; i++) {')
        ->if('room->client_fds[i] == fd')
          ->line('XSRETURN_YES;')
        ->endif
      ->line('}')
      ->blank
      ->line('XSRETURN_NO;')
      ->xs_end
      ->blank;
    
    return $builder;
}

# XS: broadcast(message, [exclude_fd|ws]) - instance method
sub gen_xs_broadcast {
    my ($class, $builder) = @_;
    
    $builder->xs_function('xs_room_broadcast')
      ->xs_preamble
      ->if('items < 2')
        ->line('croak("Usage: $room->broadcast(message, [exclude_fd])");')
      ->endif
      ->blank
      ->line('int room_id = SvIV(SvRV(ST(0)));')
      ->line('STRLEN msg_len;')
      ->line('const char* message = SvPV(ST(1), msg_len);')
      ->line('int exclude_fd = (items >= 3) ? extract_fd(ST(2)) : -1;')
      ->line('int i;')
      ->blank
      ->if('room_id < 0 || room_id >= ROOM_MAX_ROOMS')
        ->line('XSRETURN_IV(0);')
      ->endif
      ->if('!room_registry[room_id].active')
        ->line('XSRETURN_IV(0);')
      ->endif
      ->blank
      ->line('WSRoom* room = &room_registry[room_id];')
      ->blank
      ->comment('Encode message as WebSocket text frame')
      ->line('uint8_t frame[65546];')
      ->line('size_t frame_len = ws_encode_text(frame, sizeof(frame), message, msg_len);')
      ->if('frame_len == 0')
        ->line('XSRETURN_IV(0);')
      ->endif
      ->blank
      ->line('int sent = 0;')
      ->for('i = 0', 'i < room->client_count', 'i++')
        ->line('int fd = room->client_fds[i];')
        ->if('fd >= 0 && fd != exclude_fd')
          ->line('send(fd, frame, frame_len, 0);')
          ->line('sent++;')
        ->endif
      ->endfor
      ->blank
      ->line('XSRETURN_IV(sent);')
      ->xs_end
      ->blank;
    
    return $builder;
}

# XS: broadcast_binary(data, [exclude_fd|ws]) - instance method
sub gen_xs_broadcast_binary {
    my ($class, $builder) = @_;
    
    $builder->xs_function('xs_room_broadcast_binary')
      ->xs_preamble
      ->if('items < 2')
        ->line('croak("Usage: $room->broadcast_binary(data, [exclude_fd])");')
      ->endif
      ->blank
      ->line('int room_id = SvIV(SvRV(ST(0)));')
      ->line('STRLEN data_len;')
      ->line('const char* data = SvPV(ST(1), data_len);')
      ->line('int exclude_fd = (items >= 3) ? extract_fd(ST(2)) : -1;')
      ->line('int i;')
      ->blank
      ->if('room_id < 0 || room_id >= ROOM_MAX_ROOMS')
        ->line('XSRETURN_IV(0);')
      ->endif
      ->if('!room_registry[room_id].active')
        ->line('XSRETURN_IV(0);')
      ->endif
      ->blank
      ->line('WSRoom* room = &room_registry[room_id];')
      ->blank
      ->comment('Encode as binary frame')
      ->line('uint8_t frame[65546];')
      ->line('size_t frame_len = ws_encode_binary(frame, sizeof(frame), (const uint8_t*)data, data_len);')
      ->if('frame_len == 0')
        ->line('XSRETURN_IV(0);')
      ->endif
      ->blank
      ->line('int sent = 0;')
      ->for('i = 0', 'i < room->client_count', 'i++')
        ->line('int fd = room->client_fds[i];')
        ->if('fd >= 0 && fd != exclude_fd')
          ->line('send(fd, frame, frame_len, 0);')
          ->line('sent++;')
        ->endif
      ->endfor
      ->blank
      ->line('XSRETURN_IV(sent);')
      ->xs_end
      ->blank;
    
    return $builder;
}

# XS: count() - instance method
sub gen_xs_count {
    my ($class, $builder) = @_;
    
    $builder->xs_function('xs_room_count')
      ->xs_preamble
      ->if('items != 1')
        ->line('croak("Usage: $room->count()");')
      ->endif
      ->blank
      ->line('int room_id = SvIV(SvRV(ST(0)));')
      ->blank
      ->if('room_id < 0 || room_id >= ROOM_MAX_ROOMS')
        ->line('XSRETURN_IV(0);')
      ->endif
      ->if('!room_registry[room_id].active')
        ->line('XSRETURN_IV(0);')
      ->endif
      ->blank
      ->line('XSRETURN_IV(room_registry[room_id].client_count);')
      ->xs_end
      ->blank;
    
    return $builder;
}

# XS: count_open() - instance method, counts open connections, removes closed ones
sub gen_xs_count_open {
    my ($class, $builder) = @_;
    
    $builder->xs_function('xs_room_count_open')
      ->xs_preamble
      ->if('items != 1')
        ->line('croak("Usage: $room->count_open()");')
      ->endif
      ->blank
      ->line('int room_id = SvIV(SvRV(ST(0)));')
      ->blank
      ->if('room_id < 0 || room_id >= ROOM_MAX_ROOMS')
        ->line('XSRETURN_IV(0);')
      ->endif
      ->if('!room_registry[room_id].active')
        ->line('XSRETURN_IV(0);')
      ->endif
      ->blank
      ->line('WSRoom* room = &room_registry[room_id];')
      ->line('int open_count = 0;')
      ->line('int write_idx = 0;')
      ->line('int i;')
      ->blank
      ->comment('Compact array, removing closed connections')
      ->for('i = 0', 'i < room->client_count', 'i++')
        ->line('int fd = room->client_fds[i];')
        ->comment('Check if fd is still valid/open in handler registry')
        ->if('fd >= 0 && fd < WS_MAX_CONNECTIONS && ws_handler_registry[fd].active')
          ->line('room->client_fds[write_idx++] = fd;')
          ->line('open_count++;')
        ->endif
      ->endfor
      ->line('room->client_count = write_idx;')
      ->blank
      ->line('XSRETURN_IV(open_count);')
      ->xs_end
      ->blank;
    
    return $builder;
}

# XS: close_all([code], [reason]) - instance method
sub gen_xs_close_all {
    my ($class, $builder) = @_;
    
    $builder->xs_function('xs_room_close_all')
      ->xs_preamble
      ->if('items < 1')
        ->line('croak("Usage: $room->close_all([code], [reason])");')
      ->endif
      ->blank
      ->line('int room_id = SvIV(SvRV(ST(0)));')
      ->line('int code = (items >= 2) ? SvIV(ST(1)) : 1000;')
      ->blank
      ->if('room_id < 0 || room_id >= ROOM_MAX_ROOMS')
        ->line('XSRETURN_IV(0);')
      ->endif
      ->if('!room_registry[room_id].active')
        ->line('XSRETURN_IV(0);')
      ->endif
      ->blank
      ->line('WSRoom* room = &room_registry[room_id];')
      ->line('int closed = 0;')
      ->line('int i;')
      ->blank
      ->comment('Send close frame to all clients')
      ->line('uint8_t close_frame[4];')
      ->line('close_frame[0] = 0x88;')
      ->line('close_frame[1] = 2;')
      ->line('close_frame[2] = (code >> 8) & 0xFF;')
      ->line('close_frame[3] = code & 0xFF;')
      ->blank
      ->for('i = 0', 'i < room->client_count', 'i++')
        ->line('int fd = room->client_fds[i];')
        ->if('fd >= 0')
          ->line('send(fd, close_frame, 4, 0);')
          ->line('closed++;')
        ->endif
      ->endfor
      ->blank
      ->comment('Clear room')
      ->line('room->client_count = 0;')
      ->line('memset(room->client_fds, -1, sizeof(room->client_fds));')
      ->blank
      ->line('XSRETURN_IV(closed);')
      ->xs_end
      ->blank;
    
    return $builder;
}

# XS: name() - instance method, returns room name
sub gen_xs_name {
    my ($class, $builder) = @_;
    
    $builder->xs_function('xs_room_name')
      ->xs_preamble
      ->if('items != 1')
        ->line('croak("Usage: $room->name()");')
      ->endif
      ->blank
      ->line('int room_id = SvIV(SvRV(ST(0)));')
      ->blank
      ->if('room_id < 0 || room_id >= ROOM_MAX_ROOMS')
        ->line('XSRETURN_UNDEF;')
      ->endif
      ->if('!room_registry[room_id].active')
        ->line('XSRETURN_UNDEF;')
      ->endif
      ->blank
      ->line('ST(0) = sv_2mortal(newSVpv(room_registry[room_id].name, 0));')
      ->line('XSRETURN(1);')
      ->xs_end
      ->blank;
    
    return $builder;
}

# XS: clear() - instance method
sub gen_xs_clear {
    my ($class, $builder) = @_;
    
    $builder->xs_function('xs_room_clear')
      ->xs_preamble
      ->if('items != 1')
        ->line('croak("Usage: $room->clear()");')
      ->endif
      ->blank
      ->line('int room_id = SvIV(SvRV(ST(0)));')
      ->blank
      ->if('room_id < 0 || room_id >= ROOM_MAX_ROOMS')
        ->line('XSRETURN_NO;')
      ->endif
      ->if('!room_registry[room_id].active')
        ->line('XSRETURN_NO;')
      ->endif
      ->blank
      ->line('room_registry[room_id].client_count = 0;')
      ->line('memset(room_registry[room_id].client_fds, -1, sizeof(room_registry[room_id].client_fds));')
      ->line('XSRETURN_YES;')
      ->xs_end
      ->blank;
    
    return $builder;
}

# XS: clients() - instance method, returns list of client fds
sub gen_xs_clients {
    my ($class, $builder) = @_;
    
    $builder->xs_function('xs_room_clients')
      ->xs_preamble
      ->if('items != 1')
        ->line('croak("Usage: $room->clients()");')
      ->endif
      ->blank
      ->line('int room_id = SvIV(SvRV(ST(0)));')
      ->blank
      ->if('room_id < 0 || room_id >= ROOM_MAX_ROOMS')
        ->line('XSRETURN_EMPTY;')
      ->endif
      ->if('!room_registry[room_id].active')
        ->line('XSRETURN_EMPTY;')
      ->endif
      ->blank
      ->line('WSRoom* room = &room_registry[room_id];')
      ->line('int count = 0;')
      ->line('int i;')
      ->blank
      ->for('i = 0', 'i < room->client_count', 'i++')
        ->if('room->client_fds[i] >= 0')
          ->line('XPUSHs(sv_2mortal(newSViv(room->client_fds[i])));')
          ->line('count++;')
        ->endif
      ->endfor
      ->blank
      ->line('XSRETURN(count);')
      ->xs_end
      ->blank;
    
    return $builder;
}

# Get XS function mappings for XS::JIT->compile
sub get_xs_functions {
    return {
        'Hypersonic::WebSocket::Room::new'              => { source => 'xs_room_new', is_xs_native => 1 },
        'Hypersonic::WebSocket::Room::destroy'          => { source => 'xs_room_destroy', is_xs_native => 1 },
        'Hypersonic::WebSocket::Room::join'             => { source => 'xs_room_join', is_xs_native => 1 },
        'Hypersonic::WebSocket::Room::leave'            => { source => 'xs_room_leave', is_xs_native => 1 },
        'Hypersonic::WebSocket::Room::has'              => { source => 'xs_room_has', is_xs_native => 1 },
        'Hypersonic::WebSocket::Room::broadcast'        => { source => 'xs_room_broadcast', is_xs_native => 1 },
        'Hypersonic::WebSocket::Room::broadcast_binary' => { source => 'xs_room_broadcast_binary', is_xs_native => 1 },
        'Hypersonic::WebSocket::Room::count'            => { source => 'xs_room_count', is_xs_native => 1 },
        'Hypersonic::WebSocket::Room::count_open'       => { source => 'xs_room_count_open', is_xs_native => 1 },
        'Hypersonic::WebSocket::Room::close_all'        => { source => 'xs_room_close_all', is_xs_native => 1 },
        'Hypersonic::WebSocket::Room::name'             => { source => 'xs_room_name', is_xs_native => 1 },
        'Hypersonic::WebSocket::Room::clear'            => { source => 'xs_room_clear', is_xs_native => 1 },
        'Hypersonic::WebSocket::Room::clients'          => { source => 'xs_room_clients', is_xs_native => 1 },
    };
}

1;

__END__

=head1 NAME

Hypersonic::WebSocket::Room - XS Broadcast support for WebSocket connections

=head1 SYNOPSIS

    use Hypersonic::WebSocket::Room;
    use XS::JIT::Builder;
    use XS::JIT;
    
    my $builder = XS::JIT::Builder->new;
    Hypersonic::WebSocket::Room->generate_c_code($builder, {
        max_rooms => 1000,
        max_clients_per_room => 10000,
    });
    
    # Compile XS functions
    XS::JIT->compile(
        code      => $builder->code,
        name      => 'Hypersonic::WebSocket::Room',
        functions => Hypersonic::WebSocket::Room->get_xs_functions,
    );
    
    # Now use from Perl - object-oriented API
    my $room = Hypersonic::WebSocket::Room->new('chat');
    $room->join($fd);
    $room->broadcast('Hello!');
    $room->leave($fd);
    $room->destroy;

=head1 DESCRIPTION

Generates XS functions for WebSocket room/channel management via XS::JIT::Builder.
All hot paths (membership tracking, broadcast) are in C.

Room objects are blessed scalars containing the room_id, created entirely in XS.

=head1 INSTANCE METHODS (XS)

=over 4

=item new($name) - Create room, returns blessed room object

=item destroy() - Destroy room

=item join($fd) - Add client to room

=item leave($fd) - Remove client from room

=item has($fd) - Check if client in room

=item broadcast($message, [$exclude_fd]) - Send text to all

=item broadcast_binary($data, [$exclude_fd]) - Send binary to all

=item count() - Number of clients

=item count_open() - Open clients (cleans up closed)

=item close_all([$code], [$reason]) - Close all clients

=item name() - Get room name

=item clear($room_id) - Remove all clients without closing

=back

=cut