use v5.26;
use warnings;
use Feature::Compat::Class;

# ABSTRACT: MIDI event base class


use experimental qw/ signatures /;

package MIDI::Stream::Event;
class MIDI::Stream::Event;

our $VERSION = '0.006';

use Carp qw/ croak /;
use MIDI::Stream::Tables qw/ status_name keys_for /;


field $name :reader;
field $message :reader :param;
field $dt :reader :param;
field $bytes;
field $status :reader;


method bytes {
    $bytes //= join '', map { chr } $message->@*;
}


method as_hashref {
    +{
        map { $_ => $self->$_ }
            ( 'name', keys_for( $self->name )->@* )
    };
}


method TO_JSON { $self->as_hashref };


method as_arrayref {
    [
        $self->name =>
        map { $self->$_ } keys_for( $self->name )->@*
    ]
}

ADJUST {
    $name = status_name( $message->[0] ) // 'unknown';
    $status = $message->[0];
    # note on with velocity 0 is note off
    $name = 'note_off' if $status < 0xa0 && !$message->[2];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::Stream::Event - MIDI event base class

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Base class for encapsulation of MIDI events parsed by L<MIDI::Stream::Decoder>.
An instance of this class will represent any single byte status, e.g. clock,
active_sensing.

See subclass documentation for additional information on multi-byte events:

=over

=item L<MIDI::Stream::Event::AfterTouch>

=item L<MIDI::Stream::Event::ControlChange>

=item L<MIDI::Stream::Event::Note>

=item L<MIDI::Stream::Event::PitchBend>

=item L<MIDI::Stream::Event::PolyTouch>

=item L<MIDI::Stream::Event::ProgramChange>

=item L<MIDI::Stream::Event::SongPosition>

=item L<MIDI::Stream::Event::SongSelect>

=item L<MIDI::Stream::Event::SysEx>

=item L<MIDI::Stream::Event::TimeCode>

=back

=head1 METHODS

=head2 new

    my $event = MIDI::Stream::Event->new( dt => $time, message => $midi_bytes_arrayref );
    my $event = MIDI::Stream::Event->new( dt => 0, message => [ 0xfe ] );

Returns a new event instance. Options:

=head3 dt

Dela-time

=head3 message

MIDI byte array

=head2 name

The event name, e.g. 'note_on'

=head2 dt

Dela-time - time since the previous event was seen.

=head2 message

The original message byte array passed to the constructor.

=head2 bytes

String representation of message.

=head2 as_hashref

Hash representation of the event. See L<MIDI::Stream::Encoder/Events and
Parameters> for keys you should expect in the hash for a given event. The event
name is accessible under the key 'name'.

=head2 TO_JSON

Alias for as_hashref.

=head2 as_arrayref

Array representation of the event, in C<[ name => @parameters ]> form.

=head1 AUTHOR

John Barrett <john@jbrt.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by John Barrett.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
