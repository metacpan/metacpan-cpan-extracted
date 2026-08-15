use v5.26;
use warnings;
use Feature::Compat::Class;

# ABSTRACT: Control Change event class


package MIDI::Stream::Event::ControlChange;
class MIDI::Stream::Event::ControlChange :isa( MIDI::Stream::Event::Channel );

our $VERSION = '0.006';

use MIDI::Stream::Tables qw/ combine_bytes /;


field $control :reader;
field $value   :reader;

ADJUST {
    $control = $self->message->[ 1 ];
    $value   = $self->message->[ 2 ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::Stream::Event::ControlChange - Control Change event class

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Class representing a Control Change event.

=head1 METHODS

All methods in L<MIDI::Stream::Event::Channel>, plus:

=head2 control

The Continuous Controller (CC) the value should apply to.

=head2 value

The CC value.

=head1 AUTHOR

John Barrett <john@jbrt.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by John Barrett.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
