use v5.26;
use warnings;
use experimental qw/ signatures /;

# ABSTRACT: Instantiate events from MIDI messages

package
    MIDI::Stream::EventFactory;

our $VERSION = '0.006';

require MIDI::Stream::Event::Note;
require MIDI::Stream::Event::PolyTouch;
require MIDI::Stream::Event::ControlChange;
require MIDI::Stream::Event::ProgramChange;
require MIDI::Stream::Event::AfterTouch;
require MIDI::Stream::Event::PitchBend;
require MIDI::Stream::Event::SysEx;
require MIDI::Stream::Event::TimeCode;
require MIDI::Stream::Event::SongPosition;
require MIDI::Stream::Event::SongSelect;

sub event( $class, $dt, $message ) {
    my $status = $message->[0];
    return if $status < 0x80;

    my sub instance( $name = undef ) {
        my $class = 'MIDI::Stream::Event' . ( $name ? "::$name" : '' );
        $class->new( dt => $dt, message => $message );
    }

    # Single byte status
    return instance() if $status > 0xf3;

    # Channel events
    return instance( 'Note' )           if $status < 0xa0;
    return instance( 'PolyTouch' )      if $status < 0xb0;
    return instance( 'ControlChange' )  if $status < 0xc0;
    return instance( 'ProgramChange' )  if $status < 0xd0;
    return instance( 'AfterTouch' )     if $status < 0xe0;
    return instance( 'PitchBend' )      if $status < 0xf0;

    # System events
    return instance( 'SysEx' )        if $status == 0xf0;
    return instance( 'TimeCode' )     if $status == 0xf1;
    return instance( 'SongPosition' ) if $status == 0xf2;
    return instance( 'SongSelect' )   if $status == 0xf3;
}

;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::Stream::EventFactory - Instantiate events from MIDI messages

=head1 VERSION

version 0.006

=head1 AUTHOR

John Barrett <john@jbrt.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by John Barrett.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
