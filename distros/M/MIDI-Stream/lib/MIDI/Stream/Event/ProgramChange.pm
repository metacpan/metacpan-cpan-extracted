use v5.26;
use warnings;
use Feature::Compat::Class;

# ABSTRACT: Program Change event class


package MIDI::Stream::Event::ProgramChange;
class MIDI::Stream::Event::ProgramChange :isa( MIDI::Stream::Event::Channel );

our $VERSION = '0.006';


field $program :reader;

ADJUST {
    $program = $self->message->[1];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::Stream::Event::ProgramChange - Program Change event class

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Class representing a Program Change event.

=head1 METHODS

All methods in L<MIDI::Stream::Event::Channel>, plus:

=head2 program

Program number

=head1 AUTHOR

John Barrett <john@jbrt.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by John Barrett.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
