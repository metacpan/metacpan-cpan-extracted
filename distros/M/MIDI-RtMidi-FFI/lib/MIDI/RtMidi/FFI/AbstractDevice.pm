use v5.26;
use warnings;
use Feature::Compat::Class;
use experimental qw/ signatures /;

package
    MIDI::RtMidi::FFI::AbstractDevice;
class MIDI::RtMidi::FFI::AbstractDevice;

our $VERSION = '0.12';

# ABSTRACT: Base class for MIDI::RtMidi::FFI input and output devices

use MIDI::RtMidi::FFI ':all';
use Time::HiRes qw/ time /;
use Carp qw/ croak carp /;


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

my $api_by_name = sub( $api_name ) {
    $rtmidi_api_names->{ $api_name } // [];
};

field $name :param :reader = "RtMidi Client " . __CLASS__;
field $api_name :param = 'unspecified';
field $api :param = $api_by_name->( $api_name )->[1];
field $port_name :reader;

field $midi_event_map :param = {
    key_after_touch     => 'polytouch',
    patch_change        => 'program_change',
    channel_after_touch => 'aftertouch',
    pitch_wheel_change  => 'pitch_bend',
    sysex_f0            => 'sysex',
    sysex_f7            => 'eox',
};
field $invert_midi_event_map = {
    reverse $midi_event_map->%*
};

field $device :reader;

ADJUST {
    croak __CLASS__ . " may not be instantiated directly"
        if __CLASS__ eq __PACKAGE__;

    __CLASS__->can('get_current_api')
        or croak __CLASS__ . " cannot do get_current_api()";

    $device = $self->build_device( $api, $name );
}

method ok( $ok = undef ) { $device->ok( defined $ok ? $ok : () ) }
method msg  { $device->msg }
method data { $device->data }
method ptr  { $device->ptr }

method open_virtual_port( $virtual_port_name ) {
    croak "Virtual ports unsupported on this platform"
        if $self->get_current_api == RTMIDI_API_WINDOWS_MM;
    $self->ok(1);

    rtmidi_open_virtual_port( $device, $virtual_port_name );

    if ( $self->ok ) {
        $port_name = $virtual_port_name;
        return 1;
    }

    croak "Error opening virtual port: " . $self->msg;
}

method open_port( $port_number, $open_port_name ) {
    croak "Invalid port number ($port_number)"
        if ( $port_number < 0 || $port_number >= $self->get_port_count );
    $self->ok(1);

    rtmidi_open_port( $device, $port_number, $open_port_name );

    if ( $self->ok ) {
        $port_name = $open_port_name;
        return 1;
    }

    croak("Error opening port: " . $self->msg);
}

method open_port_by_name( $name, $open_port_name = 'in-' . time() ) {
    my @ports = $self->get_ports_by_name( $name );
    croak "No available device found matching supplied criteria" unless @ports;
    $self->open_port( $ports[0], $open_port_name );
}

method get_ports_by_name( $name ) {
    my @ports;
    if ( ref $name eq 'ARRAY' ) {
        for ( $name->@* ) {
            push @ports, $self->get_ports_by_name( $_ );
        }
    }
    else {
        push @ports, grep {
            my $pn = $self->get_port_name( $_ );
            ref $name eq 'Regexp'
                ? $pn =~ $name
                : $pn eq $name
        } 0..($self->get_port_count-1);
    }
    @ports;
}

method get_all_port_nums {
    +{
        map { $_ => $self->get_port_name( $_ ) }
        0..$self->get_port_count-1
    };
}

method get_all_port_names {
    +{
        reverse $self->get_all_port_nums->%*
    }
}

method print_ports( $handle = *STDOUT ) {
    my $ports = $self->get_all_port_nums;
    for my $port_num ( sort { $a <=> $b } keys $ports->%* ) {
        print $handle "$port_num: $ports->{ $port_num }\n";
    }
}

method close_port {
    return unless $port_name;
    $self->ok(1);
    rtmidi_close_port( $self->device );
    return 1 if $self->ok;
    croak "Error closing port: " . $self->msg;
}

method get_port_count {
    rtmidi_get_port_count( $self->device );
}

method get_port_name( $port_number ) {
    my $name = rtmidi_get_port_name( $self->device, $port_number );
    $name =~ s/\0$//;
    return $name;
}

method get_compiled_api {
    rtmidi_get_compiled_api( $self->device );
}

# Hit me across the nose with a rolled-up newspaper
method isa( $class ) {
    return !!1 if $class eq 'MIDI::RtMidi::FFI::Device';
    UNIVERSAL::isa( $self, $class );
}

method name_from_midi_event( $name ) {
    $midi_event_map->{ $name } // $name;
}

method name_to_midi_event( $name ) {
    $invert_midi_event_map->{ $name } // $name;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::RtMidi::FFI::AbstractDevice - Base class for MIDI::RtMidi::FFI input and output devices

=head1 VERSION

version 0.12

=head1 DESCRIPTION

Base class for RtMidi input and output classes. See L<MIDI::RtMidi::FFI::Device>
for methods common to all device types.

=head1 AUTHOR

John Barrett <john@jbrt.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by John Barrett.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
