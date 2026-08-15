use v5.26;
use warnings;
use Feature::Compat::Class;

# ABSTRACT: Polyphonic After Touch event class


package MIDI::Stream::Event::PolyTouch;
class MIDI::Stream::Event::PolyTouch :isa( MIDI::Stream::Event::Channel );

our $VERSION = '0.006';


field $note     :reader;
field $pressure :reader;

ADJUST {
    $note = $self->message->[ 1 ];
    $pressure = $self->message->[ 2 ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::Stream::Event::PolyTouch - Polyphonic After Touch event class

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Class representing a Polyphonic After Touch event.

=head1 METHODS

All methods in L<MIDI::Stream::Event::Channel>, plus:

=head2 note

The note pressure is applied to

=head2 pressure

The aftertouch pressure for this note

=head1 AUTHOR

John Barrett <john@jbrt.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by John Barrett.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
