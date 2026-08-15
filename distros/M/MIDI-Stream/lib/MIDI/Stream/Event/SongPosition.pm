use v5.26;
use warnings;
use Feature::Compat::Class;

# ABSTRACT: Song Position event class


package MIDI::Stream::Event::SongPosition;
class MIDI::Stream::Event::SongPosition :isa( MIDI::Stream::Event );

our $VERSION = '0.006';

use MIDI::Stream::Tables qw/ combine_bytes /;


field $position :reader;

ADJUST {
    $position = combine_bytes( $self->message->@[ 1, 2 ] );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::Stream::Event::SongPosition - Song Position event class

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Class representing a Song Position Pointer event.

=head1 METHODS

All methods in L<MIDI::Stream::Event>, plus:

=head2 position

Position value - between 0 and 16383

=head1 AUTHOR

John Barrett <john@jbrt.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by John Barrett.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
