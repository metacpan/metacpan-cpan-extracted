package MIDI::Util;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: MIDI Utilities

our $VERSION = '0.0400';

use strict;
use warnings;

use MIDI;
use MIDI::Event;
use MIDI::Track;
use MIDI::Simple;
use Music::Tempo;


sub setup_score {
    my %args = (
        lead_in => 4,
        volume  => 120,
        bpm     => 100,
        channel => 0,
        patch   => 0,
        octave  => 4,
        @_,
    );

    my $score = MIDI::Simple->new_score();

    $score->set_tempo( bpm_to_ms($args{bpm}) * 1000 );

    $score->Channel(9);
    $score->n( 'qn', 42 ) for 1 .. $args{lead_in};

    $score->Volume($args{volume});
    $score->Channel($args{channel});
    $score->Octave($args{octave});
    $score->patch_change( $args{channel}, $args{patch} );

    return $score;
}


sub new_track {
    my %args = (
        channel => 0,
        patch   => 0,
        tempo   => 500000,
        @_,
    );

    my $track = MIDI::Track->new;

    $track->new_event( 'set_tempo', 0, $args{tempo} );
    $track->new_event( 'patch_change', 0, $args{channel}, $args{patch} );

    return $track;
}


sub set_chan_patch {
    my ( $score, $channel, $patch ) = @_;

    $channel //= 0;
    $patch   //= 0;

    $score->patch_change( $channel, $patch );

    $score->noop( 'c' . $channel );
}


sub dump {
    my ($key) = @_;

    if ( lc $key eq 'volume' ) {
        return [
            map { "$_ => $MIDI::Simple::Volume{$_}" }
                sort { $MIDI::Simple::Volume{$a} <=> $MIDI::Simple::Volume{$b} }
                    keys %MIDI::Simple::Volume
        ];
    }
    elsif ( lc $key eq 'length' ) {
        return [
            map { "$_ => $MIDI::Simple::Length{$_}" }
                sort { $MIDI::Simple::Length{$a} <=> $MIDI::Simple::Length{$b} }
                    keys %MIDI::Simple::Length
        ];
    }
    elsif ( lc $key eq 'note' ) {
        return [
            map { "$_ => $MIDI::Simple::Note{$_}" }
                sort { $MIDI::Simple::Note{$a} <=> $MIDI::Simple::Note{$b} }
                    keys %MIDI::Simple::Note
        ];
    }
    elsif ( lc $key eq 'note2number' ) {
        return [
            map { "$_ => $MIDI::note2number{$_}" }
                sort { $MIDI::note2number{$a} <=> $MIDI::note2number{$b} }
                    keys %MIDI::note2number
        ];
    }
    elsif ( lc $key eq 'number2note' ) {
        return [
            map { "$_ => $MIDI::number2note{$_}" }
                sort { $a <=> $b }
                    keys %MIDI::number2note
        ];
    }
    elsif ( lc $key eq 'patch2number' ) {
        return [
            map { "$_ => $MIDI::patch2number{$_}" }
                sort { $MIDI::patch2number{$a} <=> $MIDI::patch2number{$b} }
                    keys %MIDI::patch2number
        ];
    }
    elsif ( lc $key eq 'number2patch' ) {
        return [
            map { "$_ => $MIDI::number2patch{$_}" }
                sort { $a <=> $b }
                    keys %MIDI::number2patch
        ];
    }
    elsif ( lc $key eq 'notenum2percussion' ) {
        return [
            map { "$_ => $MIDI::notenum2percussion{$_}" }
                sort { $a <=> $b }
                    keys %MIDI::notenum2percussion
        ];
    }
    elsif ( lc $key eq 'percussion2notenum' ) {
        return [
            map { "$_ => $MIDI::percussion2notenum{$_}" }
                sort { $MIDI::percussion2notenum{$a} <=> $MIDI::percussion2notenum{$b} }
                    keys %MIDI::percussion2notenum
        ];
    }
    elsif ( lc $key eq 'all_events' ) {
        return \@MIDI::Event::All_events;
    }
    elsif ( lc $key eq 'midi_events' ) {
        return \@MIDI::Event::MIDI_events;
    }
    elsif ( lc $key eq 'meta_events' ) {
        return \@MIDI::Event::Meta_events;
    }
    elsif ( lc $key eq 'text_events' ) {
        return \@MIDI::Event::Text_events;
    }
    elsif ( lc $key eq 'nontext_meta_events' ) {
        return \@MIDI::Event::Nontext_meta_events;
    }
    else {
        return [];
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::Util - MIDI Utilities

=head1 VERSION

version 0.0400

=head1 SYNOPSIS

  use MIDI::Util;

  my $score = MIDI::Util::setup_score( bpm => 120, etc => '...', );

  MIDI::Util::set_chan_patch( $score, 0, 1 );

  my $track = MIDI::Util::new_track( channel => 0, patch => 1, tempo => 450_000 );

  my $dump = MIDI::Util::dump('volume');

=head1 DESCRIPTION

C<MIDI::Util> comprises a couple handy MIDI utilities.

=head1 FUNCTIONS

=head2 setup_score()

  $score = MIDI::Util::setup_score(
    lead_in => 4,
    volume  => 120,
    bpm     => 100,
    channel => 15,
    patch   => 42,
    octave  => 4,
  );

Set basic MIDI parameters and return a L<MIDI::Simple> object.  If given a
B<lead_in>, play a hi-hat for that many beats.

Named parameters and defaults:

  lead_in: 4
  volume:  120
  bpm:     100
  channel: 0
  patch:   0
  octave:  4

=head2 new_track()

  $track = MIDI::Util::new_track(%arguments);

Set the B<channel>, B<patch>, and B<tempo> and return a L<MIDI::Track> object.

Named parameters and defaults:

  channel: 0
  patch:   0
  tempo:   500000

=head2 set_chan_patch()

  MIDI::Util::set_chan_patch( $score, $channel, $patch );

Set the MIDI channel and patch.

Positional parameters and defaults:

  score:   undef (required)
  channel: 0
  patch:   0

=head2 dump()

  $dump = MIDI::Util::dump($list_name);

Return sorted array references of the following L<MIDI>,
L<MIDI::Simple>, and L<MIDI::Event> internal lists:

  Volume
  Length
  Note
  note2number
  number2note
  patch2number
  number2patch
  notenum2percussion
  percussion2notenum
  All_events
  MIDI_events
  Meta_events
  Text_events
  Nontext_meta_events

=head1 SEE ALSO

L<MIDI::Simple>

L<Music::Tempo>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
