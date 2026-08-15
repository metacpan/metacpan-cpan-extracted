use v5.26;
use warnings;
use Feature::Compat::Class;

# ABSTRACT: Pitch Bend event class


package MIDI::Stream::Event::PitchBend;
class MIDI::Stream::Event::PitchBend :isa( MIDI::Stream::Event::Channel );

our $VERSION = '0.006';

use MIDI::Stream::Tables qw/ combine_bytes /;


field $value :reader;

ADJUST {
    $value = combine_bytes( $self->message->@[ 1, 2 ] ) - 8192;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::Stream::Event::PitchBend - Pitch Bend event class

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Class representing a Pitch Bend event.

=head1 METHODS

All methods in L<MIDI::Stream::Event::Channel>, plus:

=head2 value

The pitch bend value - between -8192 and 8191.

=head1 AUTHOR

John Barrett <john@jbrt.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by John Barrett.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
