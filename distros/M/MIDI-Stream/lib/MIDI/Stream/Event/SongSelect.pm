use v5.26;
use warnings;
use Feature::Compat::Class;

# ABSTRACT: Song Select event class


package MIDI::Stream::Event::SongSelect;
class MIDI::Stream::Event::SongSelect :isa( MIDI::Stream::Event );

our $VERSION = '0.006';


field $song :reader;

ADJUST {
    $song = $self->message->[1];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::Stream::Event::SongSelect - Song Select event class

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Class representing a Song Position Pointer event.

=head1 METHODS

All methods in L<MIDI::Stream::Event>, plus:

=head2 song

Song number

=head1 AUTHOR

John Barrett <john@jbrt.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by John Barrett.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
