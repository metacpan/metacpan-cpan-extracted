use v5.26;
use warnings;
use Feature::Compat::Class;

# ABSTRACT: Note event class


package MIDI::Stream::Event::Note;
class MIDI::Stream::Event::Note :isa( MIDI::Stream::Event::Channel );

our $VERSION = '0.006';


field $note :reader;
field $velocity :reader;

ADJUST {
    $note = $self->message->[1];
    $velocity = $self->message->[2];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::Stream::Event::Note - Note event class

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Class representing a Note On or Note Off event.

=head1 METHODS

All methods in L<MIDI::Stream::Event::Channel>, plus:

=head2 note

The played or released note.

=head2 velocity

The play or release velocity.

=head1 AUTHOR

John Barrett <john@jbrt.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by John Barrett.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
