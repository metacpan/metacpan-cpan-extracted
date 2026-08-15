use v5.26;
use warnings;
use Feature::Compat::Class;

# ABSTRACT: Channel After Touch event class


package MIDI::Stream::Event::AfterTouch;
class MIDI::Stream::Event::AfterTouch :isa( MIDI::Stream::Event::Channel );

our $VERSION = '0.006';

use MIDI::Stream::Tables qw/ combine_bytes /;


field $pressure :reader;

ADJUST {
    $pressure = $self->message->[ 1 ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::Stream::Event::AfterTouch - Channel After Touch event class

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Class representing a Channel After Touch event.

=head1 METHODS

All methods in L<MIDI::Stream::Event::Channel>, plus:

=head2 pressure

After touch pressure

=head1 AUTHOR

John Barrett <john@jbrt.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by John Barrett.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
