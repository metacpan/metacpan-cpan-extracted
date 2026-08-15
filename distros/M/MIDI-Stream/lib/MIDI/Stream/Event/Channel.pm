use v5.26;
use warnings;
use Feature::Compat::Class;

# ABSTRACT: MIDI channel event base class
#

package MIDI::Stream::Event::Channel;
class MIDI::Stream::Event::Channel :isa( MIDI::Stream::Event );

our $VERSION = '0.006';


field $channel :reader;

ADJUST {
    $channel = $self->message->[0] & 0x0f;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::Stream::Event::Channel - MIDI channel event base class

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Channel message base class.

=head1 METHODS

All methods in L<MIDI::Stream::Event>, plus:

=head2 channel

Event channel.

=head1 AUTHOR

John Barrett <john@jbrt.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by John Barrett.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
