use v5.26;
use warnings;
use Feature::Compat::Class 0.08;

# ABSTRACT: MIDI bytestream decoding and encoding

package MIDI::Stream;
class MIDI::Stream;

our $VERSION = '0.006';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::Stream - MIDI bytestream decoding and encoding

=head1 VERSION

version 0.006

=head1 DESCRIPTION

MIDI::Stream includes a realtime MIDI bytestream
L<encoder|MIDI::Stream::Encoder> and L<decoder|MIDI::Stream::Decoder>.

The classes in this distribution are stateful and are designed so a single
instance serves a single MIDI port, or device, or bytestream. Attempting to
consume or generate multiple streams in a single instance could result in
partial message collision. running status confusion, or inaccurate tempo
measurement - there are no MIDI-merge facilities.

For turning midi bytestreams into usable events see L<MIDI::Stream::Decoder>.

For turning performance and system events into a MIDI bytes suitable for
passing to MIDI hardware and other MIDI software see L<MIDI::Stream::Encoder>.

=head1 AUTHOR

John Barrett <john@jbrt.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by John Barrett.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
