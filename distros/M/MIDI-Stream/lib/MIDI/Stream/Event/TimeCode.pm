use v5.26;
use warnings;
use Feature::Compat::Class;

# ABSTRACT: Time Code Qtr. Frame event class


package MIDI::Stream::Event::TimeCode;
class MIDI::Stream::Event::TimeCode :isa( MIDI::Stream::Event );

our $VERSION = '0.006';


field $byte :reader;
field $high;
field $low;

method high {
    $high //= $byte & 0xf0 >> 5;
}

method low {
    $low //= $byte & 0x0f;
}

ADJUST {
    $byte = $self->message->[ 1 ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::Stream::Event::TimeCode - Time Code Qtr. Frame event class

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Class representing a Time Code event.

=head1 METHODS

All methods in L<MIDI::Stream::Event>, plus:

=head2 byte

The original timecode byte

=head2 high

Timecode high nibble

=head2 low

Timecode low nibble

=head1 AUTHOR

John Barrett <john@jbrt.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by John Barrett.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
