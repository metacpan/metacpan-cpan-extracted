use strict;
use warnings;
package MIDI::RtMidi::FFI::Device;

# ABSTRACT: OO interface for MIDI::RtMidi::FFI


use MIDI::RtMidi::FFI ':all';
use MIDI::Event;
use Time::HiRes qw/ time /;
use Carp qw/ carp croak /;

our $VERSION = '0.06';

my $rtmidi_api_names = {
    unspecified => [ "Unknown",            RTMIDI_API_UNSPECIFIED ],
    core        => [ "CoreMidi",           RTMIDI_API_MACOSX_CORE ],
    alsa        => [ "ALSA",               RTMIDI_API_LINUX_ALSA ],
    jack        => [ "Jack",               RTMIDI_API_UNIX_JACK ],
    winmm       => [ "Windows MultiMedia", RTMIDI_API_WINDOWS_MM ],
    dummy       => [ "Dummy",              RTMIDI_API_RTMIDI_DUMMY ],
    web         => [ "Web MIDI API",       RTMIDI_API_WEB_MIDI_API ],
    winuwp      => [ "Windows UWP",        RTMIDI_API_WINDOWS_UWP ],
    amidi       => [ "Android MIDI API",   RTMIDI_API_ANDROID ],
};

my $byte_lookup = {
    0xF1 => 'timecode',
    0xF8 => 'clock',
    0xFA => 'start',
    0xFB => 'continue',
    0xFC => 'stop',
    0xFE => 'active_sensing',
    0xFF => 'system_reset',
};

my $function_lookup = { reverse %{ $byte_lookup } };

# Only send MSB when it changes, according to option in MIDI 1.0 detailed spec.
sub _midi_1_0_encode_cc {
    my ( $self, $channel, $controller, $value ) = @_;
    my $msb = $value >> 7 & 0x7F;
    my $lsb = $value & 0x7F;
    my $last = $self->get_last( control_change => $channel, $controller );
    my $last_msb = $last->{ val };
    $self->send_message_encoded_cb( control_change => $channel, $controller, $msb )
        if ( !defined $last_msb || $last_msb != $msb );
    $self->send_message_encoded_cb( control_change => $channel, $controller | 0x20, $lsb );
}

# Send MSB/LSB pair each time
sub _pair_encode_cc {
    my ( $self, $channel, $controller, $value ) = @_;
    $self->send_message_encoded_cb( control_change => $channel, $controller, $value >> 7 & 0x7F );
    $self->send_message_encoded_cb( control_change => $channel, $controller | 0x20, $value & 0x7F );
}

# Send MSB/LSB pair each time, LSB first
sub _backwards_encode_cc {
    my ( $self, $channel, $controller, $value ) = @_;
    $self->send_message_encoded_cb( control_change => $channel, $controller | 0x20, $value & 0x7F );
    $self->send_message_encoded_cb( control_change => $channel, $controller, $value >> 7 & 0x7F );
}

sub _backwait_encode_cc {
    my ( $self, $channel, $controller, $value ) = @_;
    my $msb = $value >> 7 & 0x7F;
    my $lsb = $value & 0x7F;
    my $last = $self->get_last( control_change => $channel, $controller );
    my $last_msb = $last->{ val };
    $self->send_message_encoded_cb( control_change => $channel, $controller | 0x20 , $lsb );
    $self->send_message_encoded_cb( control_change => $channel, $controller, $msb )
        if ( !defined $last_msb || $last_msb != $msb );
}

# Send MSB/LSB pair each time, MSB first on high controller no.
sub _doubleback_encode_cc {
    my ( $self, $channel, $controller, $value ) = @_;
    $self->send_message_encoded_cb( control_change => $channel, $controller | 0x20, $value >> 7 & 0x7F );
    $self->send_message_encoded_cb( control_change => $channel, $controller, $value & 0x7F );
}

# Send MSB/LSB pair each time, MSB last on high controller no.
sub _bassack_encode_cc {
    my ( $self, $channel, $controller, $value ) = @_;
    $self->send_message_encoded_cb( control_change => $channel, $controller, $value & 0x7F );
    $self->send_message_encoded_cb( control_change => $channel, $controller | 0x20, $value >> 7 & 0x7F );
}

my $cc_encode = {
    midi       => \&_midi_1_0_encode_cc,
    await      => \&_midi_1_0_encode_cc,
    pair       => \&_pair_encode_cc,
    backwards  => \&_backwards_encode_cc,
    backwait   => \&_backwait_encode_cc,
    doubleback => \&_doubleback_encode_cc,
    bassack    => \&_bassack_encode_cc,
};

# MSB, then LSB. Do not wait for LSB - LSB = 0 when MSB changes
sub _midi_1_0_decode_cc {
    my ( $self, $channel, $controller, $value ) = @_;
    my $lowcon = $controller & ~0x20;
    my $last = $self->get_last( control_change => $channel, $lowcon );
    return unless $last;
    return [ control_change => $channel, $lowcon, $last->{ val } << 7 | $value & 0x7F ]
        if $controller & 0x20;
    return [ control_change => $channel, $controller, $value << 7 ]
        if defined $last && $last->{ val } != $value;
}

# Decode response for each LSB + last sent MSB - always wait for LSB.
sub _await_decode_cc {
    my ( $self, $channel, $controller, $value ) = @_;
    my $lowcon = $controller & ~0x20;
    my $last = $self->get_last( control_change => $channel, $lowcon );
    return unless $last;
    return [ control_change => $channel, $lowcon, $last->{ val } << 7 | $value & 0x7F ]
        if $controller & 0x20;
}

# Get last sent LSB, combine with new MSB messages
sub _backwards_decode_cc {
    my ( $self, $channel, $controller, $value ) = @_;
    my $highcon = $controller | 0x20;
    my $lowcon = $controller & ~0x20;
    my $last = $self->get_last( control_change => $channel, $highcon );
    return unless $last;
    return [ control_change => $channel, $lowcon, $value << 7 | $last->{ val } & 0x7F ]
        if ! ( $controller & 0x20 );
}

# Get last sent LSB, combine with new MSB messages.
# Accept further LSB messages for fine control.
# Attempt to detect when a LSB should be associated with a yet-to-arrive MSB.
# I think the worst case in erroneous detection is that we skip some fine
# control messages.
sub _backwait_decode_cc {
    my ( $self, $channel, $controller, $value ) = @_;
    my $highcon = $controller | 0x20;
    my $lowcon = $controller & ~0x20;
    my $last = $self->get_last( control_change => $channel, $highcon );
    return unless $last;
    return [ control_change => $channel, $lowcon, $value << 7 | $last->{ val } & 0x7F ]
        if ! ( $controller & 0x20 );
    my $last_msb = $self->get_last( control_change => $channel, $lowcon );
    return [ control_change => $channel, $lowcon, $last_msb->{ val }  << 7 | $value & 0x7F ]
        if abs( $last->{val} - $value ) < 100; # magic number, possibly bullshit !!!
}

# Store last sent MSB, combine with new LSB messages
# MSB is on the high controller (target controller + 32)
sub _doubleback_decode_cc {
    my ( $self, $channel, $controller, $value ) = @_;
    my $highcon = $controller | 0x20;
    my $lowcon = $controller & ~0x20;
    my $last_msb = $self->get_last( control_change => $channel, $highcon );
    return unless $last_msb;
    return [ control_change => $channel, $lowcon, $last_msb->{ val } << 7 | $value & 0x7F ]
        if ! ( $controller & 0x20 );
}

# Store last sent LSB, combine with new MSB messages
# MSB is on the high controller (target controller + 32)
sub _bassack_decode_cc {
    my ( $self, $channel, $controller, $value ) = @_;
    my $lowcon = $controller & ~0x20;
    my $last_lsb = $self->get_last( control_change => $channel, $lowcon );
    return unless $last_lsb;
    return [ control_change => $channel, $lowcon, $value << 7 | $last_lsb->{ val } & 0x7F ]
        if $controller & 0x20;
}

my $cc_decode = {
    midi       => \&_midi_1_0_decode_cc,
    await      => \&_await_decode_cc,
    pair       => \&_await_decode_cc,
    backwards  => \&_backwards_decode_cc,
    backwait   => \&_backwait_decode_cc,
    doubleback => \&_doubleback_decode_cc,
    bassack    => \&_bassack_decode_cc,
};


sub new {
    my ( $class, @args ) = @_;
    my $self = ( @args == 1 and ref $args[0] eq 'HASH' )
        ? bless( $args[0], $class )
        : bless( { @args }, $class );
    $self->{type} //= 'out';
    $self->{ '14bit_mode' } = $self->{ '14bit_mode' } || $self->{ '14bit_callback' };
    $self->{ rpn_14bit_mode } = $self->{ rpn_14bit_mode } || $self->{ rpn_14bit_callback };
    $self->{ nrpn_14bit_mode } = $self->{ nrpn_14bit_mode } || $self->{ nrpn_14bit_callback };
    $self->{ignore_sysex} //= 1;
    $self->{ignore_timing} //= 1;
    $self->{ignore_sensing} //= 1;
    croak "Unknown type : $self->{type}" unless $self->{type} eq 'in' || $self->{type} eq 'out';
    $self->_create_device;
    return $self;
}


sub ok   { $_[0]->{device}->ok }
sub msg  { $_[0]->{device}->msg }
sub data { $_[0]->{device}->data }
sub ptr  { $_[0]->{device}->ptr }


sub open_virtual_port {
    my ( $self, $port_name ) = @_;
    rtmidi_open_virtual_port( $self->{device}, $port_name );
}


sub open_port {
    my ( $self, $port_number, $port_name ) = @_;
    $self->{port_name} = $port_name;
    rtmidi_open_port( $self->{device}, $port_number, $port_name );
}


sub get_ports_by_name {
    my ( $self, $name ) = @_;
    my @ports = grep {
        my $pn = $self->get_port_name( $_ );
        ref $name eq 'Regexp'
            ? $pn =~ $name
            : $pn eq $name
    } 0..($self->get_port_count-1);
    return @ports;
}


sub open_port_by_name {
    my ( $self, $name, $portname ) = @_;
    $portname //= $self->{type} . '-' . time();
    if ( ref $name eq 'ARRAY' ) {
        for ( @{ $name } ) {
            return if $self->open_port_by_name( $_ );
        }
    }
    else {
        my @ports = $self->get_ports_by_name( $name );
        return 0 unless @ports;
        return !$self->open_port( $ports[0], $portname );
    }
}


sub get_all_port_nums {
    my ( $self ) = @_;
    +{
        map { $_ => $self->get_port_name( $_ ) }
        0..$self->get_port_count-1
    };
}


sub get_all_port_names {
    my ( $self ) = @_;
    +{
        reverse %{ $self->get_all_port_nums }
    }
}


sub close_port {
    my ( $self ) = @_;
    rtmidi_close_port( $self->{device} );
}


sub get_port_count {
    my ( $self ) = @_;
    rtmidi_get_port_count( $self->{device} );
}


sub get_port_name {
    my ( $self, $port_number ) = @_;
    my $name = rtmidi_get_port_name( $self->{device}, $port_number );
    $name =~ s/\0$//;
    return $name;
}


sub get_current_api {
    my ( $self ) = @_;
    my $api_dispatch = {
        rtmidi_in_get_current_api => \&rtmidi_in_get_current_api,
        rtmidi_out_get_current_api => \&rtmidi_out_get_current_api,
    };
    my $fn = "rtmidi_$self->{type}_get_current_api";
    croak "Unknown device type : $self->{type}" unless $api_dispatch->{ $fn };
    $api_dispatch->{ $fn }->( $self->{device} );
}


sub set_callback {
    my ( $self, $cb, $data ) = @_;
    croak "Unable to set_callback for device type : $self->{type}" unless $self->{type} eq 'in';
    $self->{callback} = rtmidi_in_set_callback( $self->{device}, $cb, $data );
}


sub set_callback_decoded {
    my ( $self, $cb, $data ) = @_;
    my $event_cb = sub {
        my ( $ts, $msg, $data ) = @_;
        my $decoded = $self->decode_message( $msg );
        return unless $decoded;
        $cb->( $ts, $msg, $decoded, $data );
    };
    $self->set_callback( $event_cb, $data );
}

sub cancel_callback {
    my ( $self ) = @_;
    return unless $self->{callback};
    croak "Unable to cancel_callback for device type : $self->{type}" unless $self->{type} eq 'in';
    delete $self->{callback};
    rtmidi_in_cancel_callback( $self->{device} );
}


sub ignore_types {
    my ( $self, $sysex, $timing, $sensing ) = @_;
    @{ $self }{ qw/ ignore_sysex ignore_timing ignore_sensing / } = ( $sysex, $timing, $sensing );
    croak "Unable to ignore_types for device type : $self->{type}" unless $self->{type} eq 'in';
    rtmidi_in_ignore_types( $self->{device}, $sysex, $timing, $sensing );
}


sub ignore_sysex {
    my ( $self, $ignore_sysex ) = @_;
    $self->{ignore_sysex} = $ignore_sysex;
    $self->ignore_types( @{ $self }{ qw/ ignore_sysex ignore_timing ignore_sensing / } )
}


sub ignore_timing {
    my ( $self, $ignore_timing ) = @_;
    $self->{ignore_timing} = $ignore_timing;
    $self->ignore_types( @{ $self }{ qw/ ignore_sysex ignore_timing ignore_sensing / } )
}


sub ignore_sensing {
    my ( $self, $ignore_sensing ) = @_;
    $self->{ignore_sensing} = $ignore_sensing;
    $self->ignore_types( @{ $self }{ qw/ ignore_sysex ignore_timing ignore_sensing / } )
}


sub get_message {
    my ( $self ) = @_;
    croak "Unable to get_message for device type : $self->{type}" unless $self->{type} eq 'in';
    $self->_init_timestamp;
    rtmidi_in_get_message( $self->{device}, $self->{queue_size_limit} );
}


sub get_message_decoded {
    my ( $self ) = @_;
    $self->decode_message( $self->get_message );
}


*get_event = \&get_message_decoded;


sub decode_message {
    my ( $self, $msg ) = @_;
    return unless $msg;

    my $decoded;
    my @bytes = unpack 'C*', $msg;
    my $function = shift @bytes;
    if ( my $function_name = $byte_lookup->{ $function } ) {
        if ( $function_name eq 'timecode' ) {
            my $rate    = ( $bytes[0] & 0b1100000 ) >> 5;
            my $hour    = $bytes[0] & 0b11111;
            my $minute  = $bytes[1] & 0b111111;
            my $second  = $bytes[2] & 0b111111;
            my $frame   = $bytes[3] & 0b11111;
            $decoded = [ $function_name, $rate, $hour, $minute, $second, $frame ];
        }
        else  {
            $decoded = [ $function_name, @bytes ];
        }
        goto return_decoded;
    }

    # Work around MIDI::Event failure to decode short messages
    $msg .= chr(0) if length $msg < 3;

    # Real-time messages don't have 'dtime', but MIDI::Event expects it:
    $msg = chr(0) . $msg;

    $decoded = MIDI::Event::decode( \$msg )->[0];

    if ( ref $decoded ne 'ARRAY' ) {
        carp "Could not decode message " . unpack( 'H*', $msg );
        return [ $function, @bytes ];
    }

    # Delete dtime
    splice( @{ $decoded }, 1, 1 );

    if ( $self->{ '14bit_mode' } && $decoded->[0] eq 'control_change' && $decoded->[2] < 64 ) {
        my $method = $self->resolve_cc_decoder( $self->{ '14bit_mode' } )
            // croak "Unknown 14 bit midi mode: $self->{ '14bit_mode' }";
        my @cc = @{ $decoded };
        $decoded = $self->$method( @cc[ 1..$#cc ] );
        $self->set_last( @cc );
        return unless $decoded;
    }

return_decoded:
    $decoded->[0] = 'note_off' if ( $decoded->[0] eq 'note_on' && $decoded->[-1] == 0 );
    return wantarray
        ? @{ $decoded }
        : $decoded;
}


sub send_message {
    my ( $self, $msg ) = @_;
    $self->_init_timestamp;
    croak "Unable to send_message for device type : $self->{type}" unless $self->{type} eq 'out';
    rtmidi_out_send_message( $self->{device}, $msg );
}


sub encode_message {
    my ( $self, @event ) = @_;

    $event[0] = 'sysex_f0' if $event[0] eq 'sysex';

    my $msg;
    if ( $function_lookup->{ $event[0] } ) {
        my $ev = $function_lookup->{ shift @event };
        if ( $ev == 0xF1 ) { # timecode
            my $rate = shift @event;
            $event[0] = ( $rate << 5 ) | $event[0];
        }
        $msg = \pack( 'C*', $ev, @event );
        goto return_msg;
    }

    # Insert 0 dtime
    splice @event, 1, 0, 0;

    $msg = MIDI::Event::encode( [\@event], { never_add_eot => 1 } );

    # Strip dtime before send
    substr( $$msg, 0, 1 ) = '';

    # Terminate SysEx messages (hax hax hax, probably fragile...)
    my $first = substr( $$msg, 0, 1 );
    if ( ( $first eq chr( 0xf0 ) || $first eq chr( 0xf7 ) ) && substr( $$msg, -1, 1 ) ne chr( 0xf7 ) ) {
        $$msg .= chr( 0xf7 );
    }

return_msg:
    return $$msg;
}


sub send_message_encoded {
    my ( $self, @event ) = @_;
    if ( $event[0] eq 'control_change' ) {
        my $rpn = $self->get_rpn( $event[1] );
        my $nrpn = $self->get_nrpn( $event[1] );
        if ( ( $rpn || $nrpn ) && $event[2] == 6 ) {
            if ( $rpn && $self->get_rpn_14bit_mode ) {
                my $method = $self->resolve_cc_encoder( $self->{ 'rpn_14bit_mode' } )
                    // croak "Unknown RPN 14 bit midi mode: $self->{ 'rpn_14bit_mode' }";
                return $method->( $self, @event[1..$#event ] );
            }
            elsif ( $nrpn && $self->get_nrpn_14bit_mode ) {
                my $method = $self->resolve_cc_encoder( $self->{ 'nrpn_14bit_mode' } )
                    // croak "Unknown NRPN 14 bit midi mode: $self->{ 'nrpn_14bit_mode' }";
                return $method->( $self, @event[1..$#event ] );
            }
        }
        elsif ( $event[2] < 32 && $self->{ '14bit_mode' } ) {
            my $method = $self->resolve_cc_encoder( $self->{ '14bit_mode' } )
                 // croak "Unknown 14 bit midi mode: $self->{ '14bit_mode' }";
            return $method->( $self, @event[1..$#event ] );
        }
    }
    $self->send_message_encoded_cb( @event );
}


sub send_message_encoded_cb {
    my ( $self, @event ) = @_;
    my $ret = $self->send_message( $self->encode_message( @event ) );
    $self->set_last( @event ); # Limit when this is applied?
    $ret;
}


*send_event = \&send_message_encoded;


sub panic {
    my ( $self, $channel ) = @_;
    my @channels = defined $channel
        ? ( $channel )
        : ( 0..15 );
    $self->cc( 123, $_, 0 ) for @channels;
}


sub PANIC {
    my ( $self, $channel ) = @_;
    my @channels = defined $channel
        ? ( $channel )
        : ( 0..15 );
    for my $ch ( @channels ) {
        $self->note_off( $ch, $_ ) for 0..127;
    }
}


sub get_14bit_mode { $_[0]->{ '14bit_mode' } }
*get_14bit_callback = \&get_14bit_mode;


sub set_14bit_mode {
    my ( $self, $mode, $nopurge ) = @_;
    $self->purge_last_events( 'control_change' ) unless $nopurge;
    $self->{ '14bit_mode' } = $mode;
}
*set_14bit_callback = \&set_14bit_mode;


sub disable_14bit_mode {
    my ( $self, $nopurge ) = @_;
    $self->purge_last_events( 'control_change' ) unless $nopurge;
    delete $self->{ '14bit_mode' };
}
*disable_14bit_callback = \&disable_14bit_mode;


sub resolve_cc_encoder {
    my ( $self, $encoder ) = @_;
    return $encoder if ref $encoder eq 'CODE';
    return $cc_encode->{ $encoder };
}


sub resolve_cc_decoder {
    my ( $self, $decoder ) = @_;
    return $decoder if ref $decoder eq 'CODE';
    return $cc_decode->{ $decoder };
}


sub get_timestamp {
    time - shift->{ initial_ts };
}

sub _init_timestamp {
    shift->{ initial_ts } //= time;
}


sub set_last_event {
    my ( $self, @event ) = @_;
    return if @event < 2;
    my $value = pop @event;
    my $event = shift @event;
    my $event_spec = join '-', @event;
    $self->{ last_event }->{ $event }->{ $event_spec } = { val => $value, ts => $self->get_timestamp };
}


*set_last = \&set_last_event;


sub get_last_event {
    my ( $self, $event, @spec ) = @_;
    $self->{ last_event }->{ $event }->{ join '-', @spec };
}


*get_last = \&get_last_event;


sub purge_last_events {
    my ( $self, $event ) = @_;
    return unless $event;
    delete $self->{last_event}->{ $event };
}

sub port_name { $_[0]->{port_name}; }
sub name { $_[0]->{name}; }

sub _create_device {
    my ( $self ) = @_;
    my $create_dispatch = {
        rtmidi_out_create_default => \&rtmidi_out_create_default,
        rtmidi_out_create => \&rtmidi_out_create,
        rtmidi_in_create_default => \&rtmidi_in_create_default,
        rtmidi_in_create => \&rtmidi_in_create,
    };
    my $fn = "rtmidi_$self->{type}_create";
    $fn = "${fn}_default" if !$self->{api} && !$self->{name} && !$self->{queue_size_limit};
    croak "Unknown type : $self->{type}" unless $create_dispatch->{ $fn };

    $self->{queue_size_limit} //= $self->{bufsize} //= 1024;
    my $api_by_name;
    $api_by_name = $rtmidi_api_names->{ $self->{api_str} } if $self->{api_str};
    $self->{api} //= $api_by_name->[1] if $api_by_name;
    $self->{api} //= $rtmidi_api_names->{ unspecified }->[1];
    $self->{device} = $create_dispatch->{ $fn }->( $self->{api}, $self->{name}, $self->{queue_size_limit} );
    $self->{type} eq 'in' && $self->ignore_types(
        $self->{ignore_sysex},
        $self->{ignore_timing},
        $self->{ignore_sensing},
    );
}


sub open_rpn {
    my ( $self, $channel, $msb, $lsb ) = @_;
    $self->close_rpn( $channel );
    $self->{ open_rpn }->{ $channel } = [ $msb, $lsb ];
    $self->cc( $channel, 101, $msb );
    $self->cc( $channel, 100, $lsb );
}


sub open_nrpn {
    my ( $self, $channel, $msb, $lsb ) = @_;
    $self->close_nrpn( $channel );
    $self->{ open_nrpn }->{ $channel } = [ $msb, $lsb ];
    $self->cc( $channel, 99, $msb );
    $self->cc( $channel, 98, $lsb );
}


sub close_rpn {
    my ( $self, $channel ) = @_;
    delete $self->{ open_rpn }->{ $channel };
    delete $self->{ open_nrpn }->{ $channel };
    $self->cc( $channel, 101, 127 );
    $self->cc( $channel, 100, 127 );
}


*close_nrpn = \&close_rpn;


sub get_rpn {
    my ( $self, $channel ) = @_;
    $self->{ open_rpn }->{ $channel };
}


sub get_nrpn {
    my ( $self, $channel ) = @_;
    $self->{ open_nrpn }->{ $channel };
}


sub send_rpn {
    my ( $self, $channel, $msb, $lsb, $value ) = @_;
    $self->open_rpn( $channel, $msb, $lsb );
    $self->cc( $channel, 0x06, $value );
    $self->close_rpn( $channel );
}


*rpn = \&send_rpn;


sub send_nrpn {
    my ( $self, $channel, $msb, $lsb, $value ) = @_;
    $self->open_nrpn( $channel, $msb, $lsb );
    $self->cc( $channel, 0x06, $value );
    $self->close_nrpn( $channel );
}


*nrpn = \&send_nrpn;


sub get_rpn_14bit_mode { $_[0]->{ 'rpn_14bit_mode' } }
*get_rpn_14bit_callback = \&get_rpn_14bit_mode;


sub get_nrpn_14bit_mode { $_[0]->{ 'nrpn_14bit_mode' } }
*get_nrpn_14bit_callback = \&get_nrpn_14bit_mode;


sub set_rpn_14bit_mode {
    my ( $self, $mode, $nopurge ) = @_;
    $self->purge_last_events( 'control_change' ) unless $nopurge;
    $self->{ 'rpn_14bit_mode' } = $mode;
}
*set_rpn_14bit_callback = \&set_rpn_14bit_mode;


sub set_nrpn_14bit_mode {
    my ( $self, $mode, $nopurge ) = @_;
    $self->purge_last_events( 'control_change' ) unless $nopurge;
    $self->{ 'nrpn_14bit_mode' } = $mode;
}
*set_nrpn_14bit_callback = \&set_nrpn_14bit_mode;


sub disable_rpn_14bit_mode {
    my ( $self, $nopurge ) = @_;
    $self->purge_last_events( 'control_change' ) unless $nopurge;
    delete $self->{ 'rpn_14bit_mode' };
}
*disable_rpn_14bit_callback = \&disable_rpn_14bit_mode;


sub disable_nrpn_14bit_mode {
    my ( $self, $nopurge ) = @_;
    $self->purge_last_events( 'control_change' ) unless $nopurge;
    delete $self->{ 'nrpn_14bit_mode' };
}
*disable_nrpn_14bit_callback = \&disable_nrpn_14bit_mode;


*note_off = sub { shift->send_event( note_off => @_ ) };
*note_on = sub { shift->send_event( note_on => @_ ) };
*control_change = sub { shift->send_event( control_change => @_ ) };
*patch_change = sub { shift->send_event( patch_change => @_ ) };
*key_after_touch = sub { shift->send_event( key_after_touch => @_ ) };
*channel_after_touch = sub { shift->send_event( channel_after_touch => @_ ) };
*pitch_wheel_change = sub { shift->send_event( pitch_wheel_change => @_ ) };
*sysex_f0 = sub { shift->send_event( sysex_f0 => @_ ) };
*sysex_f7 = sub { shift->send_event( sysex_f7 => @_ ) };
*sysex = sub { shift->send_event( sysex => @_ ) };


*cc = \&control_change;

my $free_dispatch = {
    in  => \&rtmidi_in_free,
    out => \&rtmidi_out_free
};
sub DESTROY {
    my ( $self ) = @_;
    my $fn = $free_dispatch->{ $self->{type} };
    # croak "Unable to free type : $self->{type}" unless $fn;
    # There is an extant issue around the Perl object lifecycle and C++ object lifecycle.
    # If we free the RtMidiPtr here, a double-free error may occur on process exit.
    # https://github.com/jbarrett/MIDI-RtMidi-FFI/issues/8
    #
    # For now, cancel the callback and close the port, then trust the process ...
    $self->cancel_callback;
    $self->close_port;
    # $fn->( $self->{device} );
}

{
    package RtMidiIn;
    use strict; use warnings;
    sub new {
        shift;
        MIDI::RtMidi::FFI::Device->new( @_, type => 'in' );
    }
}

{
    package RtMidiOut;
    use strict; use warnings;
    sub new {
        shift;
        MIDI::RtMidi::FFI::Device->new( @_, type => 'out' );
    }
}

1;

#__END__

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::RtMidi::FFI::Device - OO interface for MIDI::RtMidi::FFI

=head1 VERSION

version 0.06

=head1 SYNOPSIS

    use MIDI::RtMidi::FFI::Device;
    
    # Create a new device instance
    my $device = RtMidiOut->new;
    
    # Open a "virtual port" - this is a virtual MIDI device which may be
    # connected to directly from external synths and software.
    # This is unsupported on Windows.
    $device->open_virtual_port( 'foo' );
    
    # An alternative to opening a virtual port is connecting to an available
    # MIDI device on your system, such as a loopback device, or virtual or
    # hardware synth. Your device must be connected to some sort of synth to
    # make noise.
    $device->open_port_by_name( qr/wavetable|loopmidi|timidity|fluid/i );
    
    # Now that a port is open we can start to send MIDI messages, such as
    # this annoying sequence
    while ( 1 ) {
        # Send Middle C (0x3C) to channel 0, strong velocity (0x7A)
        $device->note_on( 0x00, 0x3C, 0x7A );
        
        # Send a random control change value to Channel 0, CC 1
        $device->cc( 0x00, 0x01, int rand( 128 ) );
        
        sleep 1;
        
        # Stop playing Middle C on channel 0
        $device->note_off( 0x00, 0x40 );
        
        sleep 1;
    }

=head1 DESCRIPTION

MIDI::RtMidi::FFI::Device is an OO interface for L<MIDI::RtMidi::FFI> to help
you manage devices, ports and MIDI events.

=head1 METHODS

=head2 new

    my $device = MIDI::RtMidi::FFI::Device->new( %options );
    my $midiin = RtMidiIn->new( %options );
    my $midiout = RtMidiOut->new( %options );

Returns a new MIDI::RtMidi::FFI::Device object. RtMidiIn and RtMidiOut are
provided as shorthand to instantiate devices of type 'in' and 'out'
respectively. Valid attributes:

=over 4

=item *

B<type> -
Device type : 'in' or 'out' (defaults to 'out')

Ignored if instantiating RtMidiIn or RtMidiOut.

=item *

B<api> -
MIDI API to use. This should be a L<RtMidiApi constant|MIDI::RtMidi::FFI/"RtMidiApi">.
By default the device should use the first compiled API available. See search
order notes in
L<Using Simultaneous Multiple APIs|https://www.music.mcgill.ca/~gary/rtmidi/index.html#multi>
on the RtMidi website.

=item *

B<api_name> -
MIDI API to use by name. One of 'alsa', 'jack', 'core', 'winmm' or 'dummy'.

=item *

B<name> -
Device name

=item *

B<queue_size_limit> -
(Type 'in' only) The buffer size to allocate for queueing incoming messages
(defaults to 1024)

=item *

B<14bit_mode> -
Sets 14-bit control change behaviour. One of 'midi', 'pair', 'await',
'backwards', 'doubleback' or 'bassack'. More information on these options
can be found in L</14-bit Control Change Modes>

=item *

B<rpn_14bit_mode> -
Sets 14-bit behaviour for RPN control change messages on CC6.
One of 'midi', 'pair', 'await', 'backwards', 'doubleback' or 'bassack'. More
information on these options can be found in L</14-bit Control Change Modes>.

The value 'midi' is recommended.

This is for type 'out' only - RPN decoding is not currently implemented.

=item *

B<nrpn_14bit_mode> -
Sets 14-bit behaviour for NRPN control change messages on CC6.
One of 'midi', 'pair', 'await', 'backwards', 'doubleback' or 'bassack'. More
information on these options can be found in L</14-bit Control Change Modes>

The value 'midi' is recommended.

This is for type 'out' only - NRPN decoding is not currently implemented.

=item *

B<bufsize> -
(Type 'in' only) An alias for B<queue_size_limit>.

=item *

B<ignore_sysex> -
(Type 'in' only) Ignore incoming SysEx messages (defaults to true)

=item *

B<ignore_timing> -
(Type 'in' only) Ignore incoming timing messages (defaults to true)

=item *

B<ignore_sensing> -
(Type 'in' only) Ignore incoming active sensing messages (defaults to true)

=back

=head2 ok, msg, data, ptr

    warn $device->msg unless $device->ok;

Getters for RtMidiWrapper device struct members

=head2 open_virtual_port

    $device->open_virtual_port( $name );

Open a virtual device port. A virtual device may be connected to other MIDI
software, just as with a hardware device. The name is an arbitrary name of
your choosing, though it is perhaps safest if you stick to plain ASCII for
this.

This method will not work on Windows. See L</Virtual Devices and Windows>
for details and possible workarounds.

=head2 open_port

    $device->open_port( $port, $name );

Open a (numeric) port on a device, with a name of your choosing.

See L</open_port_by_name> for a potentially more flexible option.

=head2 get_ports_by_name

    $device->get_ports_by_name( $name );
    $device->get_ports_by_name( qr/name/ );

Returns a list of port numbers matching the supplied name criteria.

=head2 open_port_by_name

    $device->open_port_by_name( $name );
    $device->open_port_by_name( qr/name/ );
    $device->open_port_by_name( [ $name, $othername, qr/anothername/ ] );

Opens the first port found matching the supplied name criteria.

=head2 get_all_port_nums

    $device->get_all_port_nums();

Return a hashref of available devices the form { port number => port name }

=head2 get_all_port_names

    $device->get_all_port_names();

Return a hashref of available devices of the form { port name => port number }

=head2 close_port

    $device->close_port();

Closes the currently open port

=head2 get_port_count

    $device->get_port_count();

Return the number of available MIDI ports to connect to.

=head2 get_port_name

    $self->get_port_name( $port );

Returns the corresponding device name for the supplied port number.

=head2 get_current_api

    $device->get_current_api();

Returns the MIDI API in use for the device.

This is a L<RtMidiApi constant|MIDI::RtMidi::FFI/"RtMidiApi">.

=head2 set_callback

    $device->set_callback( sub {
        my ( $ts, $msg ) = @_;
        # handle $msg here
    } );

Type 'in' only. Sets a callback to be executed when an incoming MIDI message is
received. Your callback receives the time which has elapsed since the previous
event in seconds, alongside the MIDI message.

B<NB> As a callback may occur at any point in your program's flow, the program
should probably not be doing much when it occurs. That is, programs handling
RtMidi callbacks should be asleep or awaiting user input when the callback is
triggered.

For the sake of compatibility with previous versions, some data may be passed
which is passed to the callback for each event. This data parameter exists in
the librtmidi interface to work around the lack of closures in C. It is less
useful in Perl, though you are free to use it.

The data is not stored by librtmidi, so may be any Perl data structure you
like.

    $device->set_callback( sub {
        my ( $ts, $msg, $data ) = @_;
        # handle $msg here
    }, $data );

See the examples included with this dist for some ideas on how to incorporate
callbacks into your program.

=head2 set_callback_decoded

    $device->set_callback_decoded( sub {
        my ( $ts, $msg, $event ) = @_;
        # handle $msg / $event here
    } );

Same as L</set_callback>, though also attempts to decode the message, and pass
that to the callback as an array ref. The original
message is also sent in case this fails.

=head2 cancel_callback

    $device->cancel_callback();

Type 'in' only. Removes the callback from your device.

=head2 ignore_types

    $device->ignore_types( $ignore_sysex, $ignore_timing, $ignore_sensing );
    $device->ignore_types( (1)x3 );

Type 'in' only. Set message types to ignore.

=head2 ignore_sysex

    $device->ignore_sysex( 1 );
    $device->ignore_sysex( 0 );

Type 'in' only. Set whether or not to ignore sysex messages.

=head2 ignore_timing

    $device->ignore_timing( 1 );
    $device->ignore_timing( 0 );

Type 'in' only. Set whether or not to ignore timing messages.

=head2 ignore_sensing

    $device->ignore_sensing( 1 );
    $device->ignore_sensing( 0 );

Type 'in' only. Set whether or not to ignore active sensing messages.

=head2 get_message

    $device->get_message();

Type 'in' only. Gets the next message from the queue, if available.

=head2 get_event

    $device->get_message_decoded();

Type 'in' only. Gets the next message from the queue, if available, decoded
as an event. See L</decode_message> for what to expect from incoming events.

=head2 get_event

Alias for L</get_message_decoded>, for backwards compatibility.

B<NB> Previous versions of this call spliced out the channel portion of the
message. This is no longer the case.

=head2 decode_message

    $device->decode_message( $msg );

Decodes the passed MIDI byte string. Some messages, such as clock control,
may be decoded by this module. The most common mesage types are passed
through to L<Midi::Event>.

The most common message types are:

=over

=item ('note_off', I<channel>, I<note>, I<velocity>)

=item ('note_on', I<channel>, I<note>, I<velocity>)

=item ('key_after_touch', I<channel>, I<note>, I<velocity>)

=item ('control_change', I<channel>, I<controller(0-127)>, I<value(0-127)>)

=item ('patch_change', I<channel>, I<patch>)

=item ('channel_after_touch', I<channel>, I<velocity>)

=item ('pitch_wheel_change', I<channel>, I<pitch_wheel>)

=item ('sysex_f0', I<raw>)

=item ('sysex_f7', I<raw>)

=back

Additional message types handled by this module are:

=over

=item ('timecode', I<rate>, I<hour>, I<minute>, I<second>, I<frame> )

=item ('clock')

=item ('start')

=item ('continue')

=item ('stop')

=item ('active_sensing')

=item ('system_reset')

=back

See L<Midi::Event> documentation for details on other events handled by
that module, though keep in mind that a realtime message will not have the
I<dtime> parameter.

=head2 send_message

    $device->send_message( $msg );

Type 'out' only. Sends a message on the device's open port.

=head2 encode_message

    my $msg = $device->encode_message( note_on => 0x00, 0x40, 0x5a )
    $device->send_message( $msg );

Attempts to encode the passed message with L<MIDI::Event> or message
handling within this module. See L</decode_message> for some common
supported message types.

The event name 'sysex' is an alias for 'sysex_f0'.

=head2 send_message_encoded

    $device->send_message_encoded( @event );
    # Event, channel, note, velocity
    $device->send_message_encoded( note_on => 0x00, 0x40, 0x5A );
    $device->send_message_encoded( control_change => 0x01, 0x1F, 0x3F7F );
    $device->send_message_encoded( sysex => "Hello, computer?" );

Type 'out' only. Sends a L<MIDI::Event> encoded message to the open port.

=head2 send_message_encoded_cb

    # Within callback ...
    $device->send_message_encoded_cb( @event );

Type 'out' only. A variant of send_message_encoded for use within user-defined
callbacks handling 14 bit CC, as callbacks are invoked by send_message_encoded.

=head2 send_event

Alias for L</send_message_encoded>, for backwards compatibility.

B<NB> Previous versions of this module erroneously stripped channel data from
messages. This is no longer the case - channel should be provided where
necessary.

=head2 panic

    $device->panic( $channel );
    $device->panic( 0x00 );

Send an "All MIDI notes off" (CC 123) message to the specified channel.
If no channel is specified, the message is sent to all channels.

=head2 PANIC

    $device->PANIC( $channel );
    $device->PANIC( 0x00 );

Send 'note_off' to all 128 notes on the specified channel.
If no channel is specified, the message is sent to all channels.

B<Warning:> This method has the potential to flood buffers!
It should be a recourse of last resort - consider L</panic>,
it'll probably work.

=head2 get_14bit_mode

    $device->get_14bit_mode;

Get the currently in-use 14 bit mode. See L</14-bit Control Change Modes>.

=head2 set_14bit_mode

    $device->set_14bit_mode( 'await' );
    $device->set_14bit_mode( $callback );
    $device->set_14bit_mode( $callback, 'no purge' );

Sets the 14 bit mode. See L</14-bit Control Change Modes>.
Pass a true value to the second parameter to skip purging the last-modified
cache of control change values.

This method is intended to help find the most compatible 14 bit CC encoding
or decoding mode - it probably shouldn't be used mid performance or
playback unless you seek odd side effects.

If a RPN or NRPN is active, this 14 bit mode will not have an effect on CC6.
See </set_set_rpn_14bit_mode> and </set_nrpn_14bit_mode>

=head2 disable_14bit_mode

    $device->disable_14bit_mode;
    $device->disable_14bit_mode( 'no purge' );

Disables 14 bit mode. See L</14-bit Control Change Modes>.

=head2 resolve_cc_encoder

    $device->resolve_cc_encoder( 'await' );

Return the callback associated with the given 14 bit CC encoder method.

=head2 resolve_cc_decoder

    $device->resolve_cc_decoder( 'midi' );

Return the callback associated with the given 14 bit CC decoder method.

=head2 get_timestamp

    $device->get_timestamp;

Returns the time since the first MIDI message was processed

=head2 set_last_event

    $device->set_last_event( control_change => 2, 6, 127 );

Set the last event explicitly. This event should represent a single 7-bit MIDI
message, not a composite value such as 14 bit CC.

=head2 set_last

An alias for set_last_event

=head2 get_last_event

    my $last_event = $device->get_last_event( control_change => $channel, $cc );
    # ... Do something with $last_event->{ val } and $last_event->{ ts }

Returns a hashref containing details on the last event matching the specified
parameters, if it exists.
Hashref keys include the value (val) and timestamp (ts).

=head2 get_last

An alias for get_last_event

=head2 purge_last_events

    $device->purge_last_events( 'control_change' );

Delete all cached events for the event type.

=head2 open_rpn

    $device->open_rpn( $channel, $msb, $lsb );
    $device->open_rpn( 1, 0, 1 );

Open a Registered Parameter Number (RPN) for setting with later control change
messages for CC6. This method will also close any open RPN or NRPN.

=head2 open_nrpn

    $device->open_rpn( $channel, $msb, $lsb );
    $device->open_rpn( 1, 0, 1 );

Open a Non-Registered Parameter Number (NRPN) for setting with later control
change messages for CC6. This method will also close any open RPN or NRPN.

=head2 close_rpn

    $device->close_rpn( $channel );

Close any open RPN on the given channel.

=head2 close_nrpn

    $device->close_rpn( $channel );

Close any open NRPN on the given channel.

=head2 get_rpn

    $device->get_nrpn( $channel );

Get the currently open RPN for the given channel.

=head2 get_nrpn

    $device->get_rpn( $channel );

Get the currently open RPN for the given channel.

=head2 send_rpn

    $device->send_rpn( $channel, $msb, $lsb, $value );

Send a single value for the given RPN. This method is suitable for individual
settings accessed via RPN. It will open the RPN, send the passed value to
CC6 on the passed channel, then close the RPN.

A 14 bit value is expected if rpn_14bit_mode is set.

=head2 rpn

    $device->rpn( $channel, $msb, $lsb, $value );

An alias for L</send_rpn>.

=head2 send_nrpn

    $device->send_nrpn( $channel, $msb, $lsb, $value );

Send a single value for the given NRPN. This method is suitable for single
setting values accessed via NRPN. It will open the NRPN, send the passed value
to CC6 on the passed channel, then close the NRPN.

A 14 bit value is expected if nrpn_14bit_mode is set.

If sending modulation to a NRPN, calling L</open_nrpn> and sending a stream of
control change messages separately is recommended:

    $device->open_nrpn( $channel, 1, 1 );
    $device->cc( $channel, 6, $value )
    # ...more cc() calls here
    $device->close_nrpn( $channel );

=head2 nrpn

    $device->nrpn( $channel, $msb, $lsb, $value );

An alias for L</send_nrpn>.

=head2 get_rpn_14bit_mode

    $self->get_rpn_14bit_mode;

Get the currently in-use RPN 14 bit mode.

=head2 get_nrpn_14bit_mode

    $self->get_nrpn_14bit_mode;

Get the currently in-use NRPN 14 bit mode.

=head2 set_rpn_14bit_mode

    $device->set_rpn_14bit_mode( 'await' );
    $device->set_rpn_14bit_mode( $callback );
    $device->set_rpn_14bit_mode( $callback, 'no purge' );

Sets the RPN 14 bit mode. See L</14-bit Control Change Modes>, similar to
L</set_14bit_mode>.

=head2 set_nrpn_14bit_mode

    $device->set_nrpn_14bit_mode( 'await' );
    $device->set_nrpn_14bit_mode( $callback );
    $device->set_nrpn_14bit_mode( $callback, 'no purge' );

Sets the NRPN 14 bit mode. See L</14-bit Control Change Modes>, similar to
L</set_14bit_mode>.

=head2 disable_rpn_14bit_mode

    $device->disable_rpn_14bit_mode;
    $device->disable_rpn_14bit_mode( 'no purge' );

Disables the RPN 14 bit mode. See L</14-bit Control Change Modes>.

=head2 disable_nrpn_14bit_mode

    $device->disable_nrpn_14bit_mode;
    $device->disable_nrpn_14bit_mode( 'no purge' );

Disables the NRPN 14 bit mode. See L</14-bit Control Change Modes>.

=head2 note_off, note_on, control_change, patch_change, key_after_touch, channel_after_touch, pitch_wheel_change, sysex_f0, sysex_f7, sysex

Wrapper methods for L</send_message_encoded>, e.g.

    $device->note_on( 0x00, 0x40, 0x5a );

is equivalent to:

    $device->send_message_encoded( note_on => 0x00, 0x40, 0x5a );

=head2 cc

An alias for control_change.

=head1 14 bit Control Change Modes

14 bit Control Change messages are achieved by sending a pair of 7-bit
messages. Only CCs 0-31 can send / receive 14-bit messages. The most
significant byte (or MSB or coarse control) is sent on the desired CC.
The least significant byte (or LSB or fine control) is sent on that
CC + 32. 14 bit allows for a control value between 0 and 16,383.

For example, to I<manually> set CC 6 on channel 0 to the value 1,337 you
would do something like:

    my $value = 1_337;
    my $msb = $value >> 7 & 0x7F;
    my $lsb = $value & 0x7F;
    $sevice->cc( 0, 6, $msb );
    $sevice->cc( 0, 38, $lsb );

If receving 14 bit Control Change, you would need to cache the MSB
value for the geven CC and channel, then combine it later with the
matching LSB, something like:

    $device->set_callback_decoded( sub {
        my ( $ts, $msg, $event ) = @_;
        state $last_msb;

        if ( $event->[0] eq 'control_change' ) {
            my $cc_value;
            my ( $channel, $cc, $value ) = @{ $event }[ 1..3 ];
            if ( $channel < 32 ) {
                # Cache MSB
                $last_msb->[ $channel ]->[ $cc ] = $value;
            }
            elsif ( $channel < 64 ) {
                my $msb = $last_msb->[ $channel ]->[ $cc ];
                $cc_value = $msb << 7 | $value & 0x7F;
            }
            else {
                $cc_value = $value;
            }
            if ( defined $cc_value ) {
                # ... do something with $cc_value here
            }
        }
        # ... process other events here
    } );

Some problems emerge with this approach. The first is MIDI standards -
deficiencies in, and deviation from.

For example, the MIDI 1.0 Detailed Specification states:

I<
"If both the MSB and LSB are sent initially, a subsequent fine adjustment only
requires the sending of the LSB. The MSB does not have to be retransmitted. If
a subsequent major adjustment is necessary the MSB must be transmitted again.
When an MSB is received, the receiver should set its concept of the LSB to
zero."
>

Let's break this down. I<"If 128 steps of resolution is sufficient the second
byte (LSB) of the data requires the sending of the LSB. The MSB does not have
to be retransmitted.">. The decoding callback above I<should> cater for this,
as the cached MSB will persist for multiple LSB transmissions. So far, so OK.

I<"If a subsequent major adjustment is necessary the MSB must be transmitted
again."> - again, this is fine - it fits in with expectations so far.

I<"When an MSB is received, the receiver should set its concept of the LSB
to zero">. This, to me, is ambiguous. Should our CC now be set to
C<( $msb << 7 ) + 0>? Or is it an instruction to forget any existing LSB value and
await the transmission of a fresh one before constructing a CC value?

With the former approach you could imagine a descending control passing a
MSB threshold, then jumping to a value aligned with the floor value of
the new lower MSB,
before jumping back up when the next LSB is received. The latter approach
seems to make more sense to me as it would avoid such jumps.

Some implementations skip transmission of the MSB where it would be zero.
That is for values < 128, no MSB is sent. If the controller starts at zero,
no MSB value would be cached. If the cached MSB happens to be invalid when
small values are sent (that is, the device *never* sends MSB for values
< 128), then we must resort to heuristic detection for crossing of this
MSB threshold (a large jump in LSB).

Some implementations send LSB first, MSB second. If a LSB/MSB pair is sent
each time, this is easily handled. If a pair is sent, then fine control
is sent subsequently via LSB we have a problem. When we cross a MSB threshold,
we need to wait for the new MSB value before we can construct the complete
CC value. This means we need to somehow know when to stop performing fine
control with new LSB values, and await a new MSB value - we are back to
heuristic detection, looking for LSB jumps.

All to say, there are some ambiguities in how this is handled, and there
are endless variations between different devices and implementations.

The second problem is needing to write explicit 14 bit message handling in
each project individually. This module intends to obviate some of this by
providing 14 bit message handling out of the box, with a number of
compatibility options. Currently, these options are mostly derived from
reading manuals and forum posts - testing and feedback appreciated!

=head2 For Output (Sending)

When sending 14 bit CC, multiple messages must potentially be constructed,
then sent individually. A number of options on handling this are built into
this module.

=head3 midi (recommended)

This implements the MIDI 1.0 specification. MSB values are
only sent where they have changed. LSB values are always sent. Messages
are in MSB/LSB order.

=head3 await

Equivalent to 'midi' when sending messages.

=head3 pair

Always sends a complete pair of messages for each controller change,
in MSB/LSB order.

=head3 backwards

Sends a complete pair of messages for each controller change, in
LSB/MSB order.

=head3 backwait

Sends messages in LSB/MSB order. MSB values are only sent when they have
changed.

=head3 doubleback

"Double backwards" mode. Sends a complete pair of messages for each controller
change, in MSB/LSB order, with the MSB value on the B<high> controller number.

=head3 bassack

"Bass-ackwards" mode.  Sends a complete pair of messages for each controller
change, in LSB/MSB order, with the MSB value on the B<high> controller number.

=head3 Callback

You may also provide your own callback to send 14 bit Control Change. This
callback will receive the following parameters:

=over 4

=item *

B<device> - This instance of the device.

=item *

B<channel> - The channel to send the message on, 0-15.

=item *

B<controller> - The receiving controller, 0-31.

=item *

B<value> - A 14 bit CC value, 0-16383.

=back

To take a simple example, imagine we wanted a callback which implemented the
MIDI standard:

    sub callback {
        my ( $device, $channel, $controller, $value ) = @_;
        my $msb = $value >> 7 & 0x7F;
        my $lsb = $value & 0x7F;
        my $last_msb = $device->get_last( control_change => $channel, $controller );
        if ( !defined $last_msb || $last_msb->{ val } != $msb ) {
            $device->send_message_encoded_cb( control_change => $channel, $controller, $msb )
        }
        $device->send_message_encoded_cb( control_change => $channel, $controller | 0x20, $lsb );
    }
    
    my $out = RtMidiOut->new( 14bit_callback => \&callback );
    
    # The sending of this message will be handled by your callback.
    $out->cc( 0x00, 0x06, 0x1337 );

Callbacks should not call the send_message_encoded, send_event, control_change
or cc methods as these may invoke further 14 bit message handling, potentially
causing an
infinite loop. The </send_message_encoded_cb> method exists for sending
messages within 14 bit CC callbacks.

=head2 For Input (Decoding)

When decoding 14 bit Control Change messages involves coalescing a pair of
7 bit messages which may not appear in a strict order. One value must be
cached and combined with one or more values which arrive later.

The following decode modes are built in:

=head3 midi

This implements the strictest interpretation of the MIDI 1.0 specification.
LSB messages are combined with the last sent MSB. If no MSB has yet been
received, the value will be < 128. When a new MSB is received, LSB is
reset to zero and a new value is returned.

=head3 await (recommended)

This is the same as 'midi' mode, but it always awaits a LSB message before
returning a value.

This is likely the most compatible and reliable mode for decoding.

=head3 pair

Expects a pair of values in MSB/LSB order. This is equivalent to the 'await'
mode, as that can adequately decode messages sent using this approach.

=head3 backwards

Expects a pair of values in LSB/MSB order. New values are only returned on
receipt of the MSB.

=head3 backwait

Expects an initial pair in LSB/MSB order, with additional fine control sent
as additional LSB messages. This uses a heuristic to guess when to wait for
new MSB values.

=head3 doubleback

"Double backwards" mode. Expects messages in MSB/LSB ordered pairs with MSB
on the B<high> controller number. New values are returned on incoming LSB
messages.

=head3 bassack

"Bass-ackwards" mode. Expects messages in LSB/MSB ordered pairs with MSB on
the B<high> controller number. New values are returned on incoming MSB
messages.

=head3 Callback

You may also provide your own callback to send 14 bit Control Change. This
callback will receive the following parameters:

=over 4

=item *

B<device> - This instance of the device.

=item *

B<channel> - The channel the message was sent on, 0-15.

=item *

B<controller> - The receiving controller, 0-63.

=item *

B<value> - A 7 bit CC value, 0-127.

=back

Imagine we have a device which is MIDI 1.0 compatible, but does not send a new
MSB value of zero for values < 128. We need to somehow detect a large swings in
LSB, then assume the MSB has been set to zero. For extra credit, let's only do
this only when the controller has tended towards the low end of the scale.

Wrapping a built-in decoder is possible with the L</resolve_cc_decoder>
method.

    my $callback = sub {
        my ( $device, $channel, $controller, $value ) = @_;
        my $method = $device->resolve_cc_decoder( 'await' );
        
        # Pass MSB through;
        return $device->$method( $channel, $controller, $value ) if $controller < 32;
        
        my $last_msb = $device->get_last( control_change => $channel, $controller - 32 );
        # If we start low, we never get a MSB
        my $last_msb_value = $last_msb->{ val } // 0;
        
        # Pass LSB through if we are not at the low end of the dial
        return $device->$method( $channel, $controller, $value ) if $last_msb_value > 3; # magic number
        
        # Explicitly set a MSB of 0 if there has been a large jump in LSB
        my $last_lsb = $device->get_last( control_change => $channel, $controller );
        my $diff = abs( $last_lsb->{ val } - $value );
        $device->set_last( control_change => $channel, $controller - 32, 0 ) if $diff > 100;
        
        # Finally, process the value
        $device->$method( $channel, $controller, $value );
    };
    
    my $in = RtMidiIn->new( 14bit_callback => $callback );
    $in->set_callback_decoded ( sub {
        my ( $ts, $msg, $event ) = @_;
        # For 14 bit CC, $event will contain a message decoded by your callback
    } );

One issue with the above implementation is that the heuristic magic numbers
are untuned - they would require some real world testing and tuning, and may
even vary depending on play styles or input source. Another issue is that
this scenario is (I think) likely rare and probably does not need specific
handling.

=head1 Some MIDI Terms

There are terms specific to MIDI which are somewhat overloaded by this
interface. I will try to disambiguate them here.

=head2 Device

A MIDI device, virtual or physical, is required to mediate MIDI messages.  That
is, you may not simply connect RtMidi to another piece of software without a
virtual or loopback device in between, e.g. via the L</open_virtual_port>
method. RtMidi may talk to connected physical devices directly, without the use
of a virtual device. The same is true of any software-defined virtual or
loopback devices external to your software, RtMidi may connect directly to
these.

"Virtual device" and "virtual port" are effectively interchangeable
terms when using RtMidi - each
MIDI::RtMidi::FFI::Device may represent a single input or output port,
so any virtual device instantiated has a single virtual port.

See L</Virtual Devices and Windows> for caveats and workarounds for virtual
device support on that platform.

=head2 Port

Every MIDI device has at least one port for Input and/or Output.
In hardware, connections between ports are usually 1:1. Some software
implementations allow for multiple connections to a port.

There is a special Output port usually called "MIDI Thru" or
"MIDI Through" which mirrors every message sent to a given Input port.

=head2 Channel

Each port has 16 channels, numbered 0-15, which are used to route messages
to specifically configured instruments, modules or effects.

Channel must be specified in any message related to performance, such as
"note on" or "control change".

=head2 Messages and Events

A MIDI message is a (usually) short series of bytes sent on a port, instructing
an instrument on how to behave - which notes to play, when, how loudly, with which
timbral variations & expression, and so on. They may also contain configuration
info or some other sort of instruction.

In this module "events" usually refer to incoming message bytes decoded into a
descriptive sequence of values, or a mechanism for turning these descriptive
sequences into message bytes for ouput.

=head2 General MIDI and Soundfonts

General MIDI is a specification which standardises a single set of musical
instruments, accessed via the "patch change" command. Any of 128 instruments
may be assigned to any of 16 channels, with the exception of channel 10
(0x09) which is reserved for percussion.

Soundfonts are banks of sampled instruments which may be loaded by a General
MIDI compatible softsynth. These can be quite large and complex, though they
usually tend to be small and cheesy. If you remember 90s video game
music or web pages playing .mid files, you're on the right track.

Some implementations also support DLS files, which are similar to soundfonts,
though unlike soundfonts the specification is freely available.

=head1 Virtual Devices and Windows

Windows currently (as of June 2024) lacks built-in support for on-the-fly
creation of virtual MIDI devices. While
L<Windows MIDI Services|https://microsoft.github.io/MIDI/>
will offer dynamic virtual loopback, alongside MIDI 2.0 support, it is a
work in progress.

This situation has resulted in some confusion for MIDI users on Windows,
and a number of solutions exist to work around the issue.

=head2 Loopback Devices

Virtual loopback drivers allow for the
creation of external ports which may be connected to by each participant
in the MIDI conversation.

Rather than create a virtual port, you connect your Perl code to a
virtual loopback device, and connect your DAW or synth to the other side
of the loopback device.

The best currently working virtual loopback drivers based on my research are:

L<loopMIDI|https://www.tobias-erichsen.de/software/loopmidi.html> by
Tobias Erichsen

L<Sbvmidi|https://springbeats.com/sbvmidi/> by Springbeats

L<LoopBe|https://www.nerds.de/en/loopbe1.html> by nerds.de

In my own experience loopMIDI is the simplest and most flexible option,
allowing for arbitrary numbers of devices, with arbitrary names.

You should review the licensing terms of any software you choose to
incorporate into your projects to ensure it is appropriate for your use case.
Each of the above is free for personal, non-commercial use.

=head2 General MIDI

A General MIDI synth called "Microsoft GS Wavetable Synth" should be available
for direct connection on Windows. While the sounds are basic, it can act as a
useful device for testing. This should play a middle-C note on the default
piano instrument:

    use MIDI::RtMidi::FFI::Device;
    my $device = RtMidiOut->new;
    $device->open_port_by_name( qr/gs\ wavetable/i );
    $device->note_on( 0x00, 0xc3, 0x7f );
    sleep( 1 );
    $device->note_off( 0x00, 0xc3 );

=head1 General MIDI on Linux

The days of consumer sound cards containing their own wavetable banks are
behind us.  These days, General MIDI is usually supported in software.

A commonly available General MIDI soft-synth is
L<TiMidity++|https://timidity.sourceforge.net/> - a version is likely packaged
for your distro. This package may or
may not install a timidity service (it may be packaged separately as
timidity-daemon). If not, you can quickly make a timidity port available by
running:

    $ timidity -iAD

You may also need to install and configure a soundfont for TiMidity++.

Another option is FluidSynth, which should also be packaged for any given
distro. To run FluidSynth you'll need a SF2 or SF3 soundfont file. See
L<Getting started with fluidsynth|https://github.com/FluidSynth/fluidsynth/wiki/GettingStarted>
and
L<Example Command Lines to start fluidsynth|https://github.com/FluidSynth/fluidsynth/wiki/ExampleCommandLines>.
L<FluidR3_GM.sf2 Professional|https://musical-artifacts.com/artifacts/738>
is a high quality sound font with a complete set of General MIDI instruments.

A typical FluidSynth invocation on Linux might be:

    $ fluidsynth -a pulseaudio -m alsa_seq -g 1.0 your_soundfont.sf2

=head1 General MIDI on MacOS

An Audio Unit named DLSMusicDevice is available for use within GarageBand,
Logic, and other Digital Audio Workstation (DAW) software on MacOS.

If you wish to use banks other than the default QuickTime set, place
them in C<~/Library/Audio/Sounds/Banks/>. You may now create a new track
within GarageBand or Logic with the DLSMusicDevice instrument, and
select your Sound Bank within the settings for this instrument.

The next step is to open a virtual port, which should autoconnect within
your DAW and be ready to send performance info to DLSMusicDevice:

    # Open virtual port with a name of your choosing
    $device->open_virtual_port('My Snazzy Port');
    # Send middle C
    $device->note_on( 0x00, 0xc3, 0x7f );
    sleep( 1 );
    $device->note_off( 0x00, 0xc3 );

The 'MUS 214: MIDI Composition' channel on YouTube has a
L<Video on setting up DLSMusicDevice in Logic|https://youtu.be/YIb-H10yzyI>.

A potential alternative option is FluidSynth. This has more limited support for
DLS banks but should load SF2/3 banks just fine. See L</General MIDI on Linux>
for links to get started using FluidSynth. A typical FluidSynth invocation on
MacOS might be:

    % fluidsynth -a coreaudio -m coremidi your_soundfont.sf2

=head1 KNOWN ISSUES

Use of L<MIDI::Event> is a bit of a hack for convenience, exploiting the
similarity of realtime MIDI messages and MIDI song file messages. It may break
in unexpected ways if used for large SysEx messages or other "non-music"
events, though should be fine for encoding and decoding note, pitch, aftertouch
and CC messages.

Test coverage, both automated testing and hands-on testing, is limited. Some
elements of this module (especially around 14 bit CC and (N)RPN) are based on
reading, and probably often misreading, MIDI specifications, device
documentation and forum posts. Issues in the GitHub repo are more than
welcome, even if just to ask questions. You may also find me in #perl-music
on irc.perl.org - look for fuzzix.

This software has been fairly well exercised on Linux and Windows, but not
so much on MacOS / CoreMIDI. I am interested in feedback on successes
and failures on this platform.

NRPN and 14 bit CC have not been tested on real hardware, though they work
well in the "virtual" domain - for controlling software-defined instruments.

L<Currently open MIDI::RtMidi::FFI issues on GitHub|https://github.com/jbarrett/MIDI-RtMidi-FFI/issues>

=head1 SEE ALSO

L<RtMidi|https://www.music.mcgill.ca/~gary/rtmidi/>

L<MIDI CC & NRPN database|https://midi.guide/>

L<Phil Rees Music Tech page on NRPN/RPN|http://www.philrees.co.uk/nrpnq.htm>

L<MIDI::RtMidi::FFI>

L<MIDI::Event>

=head1 CONTRIBUTING

L<https://github.com/jbarrett/MIDI-RtMidi-FFI>

All comments and contributions welcome.

=head1 BUGS AND SUPPORT

Please direct all requests to L<https://github.com/jbarrett/MIDI-RtMidi-FFI/issues>

=head1 CONTRIBUTORS

=over 4

=item *

Gene Boggs <gene@cpan.org>

=back

=head1 AUTHOR

John Barrett <john@jbrt.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by John Barrett.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
