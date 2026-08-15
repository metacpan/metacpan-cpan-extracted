use v5.26;
use warnings;
use Feature::Compat::Class;

# ABSTRACT: SysEx event class

package MIDI::Stream::Event::SysEx;
class MIDI::Stream::Event::SysEx :isa( MIDI::Stream::Event );


our $VERSION = '0.006';


field $msg_str;
field $msg :reader = [];

method msg_str {
    $msg_str //= join '', map { chr } $msg->@*;
}

ADJUST {
    ( undef, $msg->@* ) = $self->message->@*;
    delete $msg->[ -1 ] if $msg->[ -1 ] == 0xf7;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::Stream::Event::SysEx - SysEx event class

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Class representing a SysEx message.

=head1 METHODS

All methods in L<MIDI::Stream::Event>, plus:

=head2 msg

The original message as a MIDI byte array

=head2 msg_str

The original message as a MIDI byte string

=head1 AUTHOR

John Barrett <john@jbrt.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by John Barrett.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
