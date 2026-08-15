use strict;
use warnings;
package MIDI::Stream::Tables;

# ABSTRACT: MIDI 1.0 look up tables and utility functions


our $VERSION = '0.006';

use parent 'Exporter';

my %status; my %fstatus;
BEGIN {
    %status = (
        note_off       => 0x80,
        note_on        => 0x90,
        polytouch      => 0xa0,
        control_change => 0xb0,
        program_change => 0xc0,
        aftertouch     => 0xd0,
        pitch_bend     => 0xe0,
    );

    %fstatus = (
        sysex          => 0xf0,
        timecode       => 0xf1,
        song_position  => 0xf2,
        song_select    => 0xf3,
        tune_request   => 0xf6,
        eox            => 0xf7,
        clock          => 0xf8,
        start          => 0xfa,
        continue       => 0xfb,
        stop           => 0xfc,
        active_sensing => 0xfe,
        system_reset   => 0xff,
    );
}

my %name = reverse %status;
my %fname = reverse %fstatus;

# Not exactly ecstatic about this pattern, but an alternative has yet to
# occur to me. One alternative I thought about was having objects push their
# ordered keys to an array in the top-level class, but this means you need
# an object instance to get the ordering:
# $class->from_hashref( $event )->as_arrayref seemed a little perverse.
my $event_keys = {
    note_off       => [qw/ channel note velocity /],
    note_on        => [qw/ channel note velocity /],
    polytouch      => [qw/ channel note pressure /],
    control_change => [qw/ channel control value /],
    program_change => [qw/ channel program /],
    aftertouch     => [qw/ channel pressure /],
    pitch_bend     => [qw/ channel value /],
    song_position  => [qw/ position /],
    song_select    => [qw/ song /],
    timecode       => [qw/ byte /],
    sysex          => [qw/ msg /],
};


sub event_desc { $event_keys }


sub keys_for {
    $event_keys->{ $_[0] } // [];
}


sub status_name {
    $name{ $_[0] & 0xf0 } // $fname{ $_[0] };
}


sub status_byte { $status{ $_[0] } // $fstatus{ $_[0] } }


sub is_realtime { $_[0] > 0xf7 }


sub is_single_byte { $_[0] > 0xf5 }


sub message_length {
    my ( $status ) = @_;

    $status = status_byte( $status ) if ( length $status // 0 ) > 3;

    return 0 unless $status;

    return 0 if $status < 0x80;
    return 3 if $status < 0xc0;
    return 2 if $status < 0xe0;
    return 3 if $status < 0xf0;

    return 0 if $status == 0xf0;
    return 2 if $status == 0xf1;
    return 3 if $status == 0xf2;
    return 2 if $status == 0xf3;

    return 1 if $status > 0xf5;
}


sub is_status_byte { $_[0] & 0x80 }


sub has_channel { ( length $_[0] > 3 ? status_byte( $_[0] ) : $_[0] ) < 0xf0 }


sub is_cc {
    ( $_[0] & 0xf0 ) == 0xb0;
}


sub combine_bytes {
    my ( $lsb, $msb ) = @_;
    $msb << 7 | $lsb & 0x7f;
}


sub split_bytes {
    my ( $value ) = @_;
    ( $value & 0x7f, $value >> 7 & 0x7f );
}

use constant {
    map { $_ => $_ } ( keys %fstatus, keys %status )
};

our @EXPORT_OK = qw/
    event_desc
    keys_for
    status_name
    status_byte
    status_chr
    is_realtime
    is_single_byte
    message_length
    is_status_byte
    has_channel
    is_cc
    is_pitch_bend
    combine_bytes
    split_bytes
/;
push @EXPORT_OK, keys %status, keys %fstatus;
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::Stream::Tables - MIDI 1.0 look up tables and utility functions

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    use MIDI::Stream::Tables qw/ split_bytes /;

    my ( $lsb, $msb ) = split_bytes( 0x1e2f );

=head1 DESCRIPTION

MIDI::Stream::Tables is a set of data and functions for encoding, decoding, and
manipulating MIDI messages and events. It is intended for use in
L<MIDI::Stream> and related libraries.

=head1 FUNCTIONS

=head2 event_desc

    my $event_hashref = event_desc

Returns a hashref of supported events and their parameters, e.g.

    $event_hashref->{ note_on }; # [qw/ channel note velocity /]

=head2 keys_for

    my $keys = keys_for( 'control_change' );

Returns key/accessor names for the given event name.

=head2 status_name

    my $name = status_name( 0x83 );

Returns the event name for the given status.

=head2 status_byte

    my $status = status_byte( 'clock' );

Returns the status byte corresponding to the event name.

=head2 is_realtime

    act_now( $byte ) if is_realtime( $byte );

Returns whether the given byte is in the realtime range.

=head2 is_single_byte

    my $sb = is_single_byte( 0xfa )

Returns whether the given byte represents a single-byte message, e.g. 'clock',
'tune_request'.

=head2 message_length

    my $len = message_length( 0x9f );
    my $len = message_length( 'note_on' );

Returns the expected message length for the given status.

=head2 is_status_byte

    new_status( $byte ) if is_status_byte( $byte );

Returns whether the given byte is a status byte.

=head2 has_channel

    new_channel_status( $byte ) if has_channel( $byte );
    my $has_channel = has_channel('clock');

Returns whether the passed status is a channel status.

=head2 is_cc

    do_cc( $byte ) if is_cc( $byte );

Returns whether the given byte is a control change status.

=head2 combine_bytes

    my $value_14bit = combine_bytes( $lsb, $msb );

Combine MSB/LSB pair into a 14-bit value.

=head2 split_bytes

    my ( $lsb, $msb ) = split_bytes( $value_14bit );

Split a 14-bit value into a MSB/LSB pair.

=head1 AUTHOR

John Barrett <john@jbrt.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by John Barrett.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
