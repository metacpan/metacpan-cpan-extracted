package MIDI::Util;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: MIDI Utilities

our $VERSION = '0.0703';

use strict;
use warnings;

use MIDI ();
use MIDI::Simple ();
use Music::Tempo qw(bpm_to_ms);


sub setup_score {
    my %args = (
        lead_in   => 4,
        volume    => 120,
        bpm       => 100,
        channel   => 0,
        patch     => 0,
        octave    => 4,
        signature => '4/4',
        @_,
    );

    my $score = MIDI::Simple->new_score();

    set_time_sig($score, $args{signature});

    $score->set_tempo( bpm_to_ms($args{bpm}) * 1000 );

    $score->Channel(9);
    $score->n( 'qn', 42 ) for 1 .. $args{lead_in};

    $score->Volume($args{volume});
    $score->Channel($args{channel});
    $score->Octave($args{octave});
    $score->patch_change( $args{channel}, $args{patch} );

    return $score;
}


sub set_chan_patch {
    my ( $score, $channel, $patch ) = @_;

    $channel //= 0;

    $score->patch_change( $channel, $patch )
        if defined $patch;

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


sub midi_format {
    my (@notes) = @_;
    my @formatted;
    for my $note (@notes) {
        $note =~ s/#/s/;
        $note =~ s/b/f/;
        $note =~ s/Es/F/;
        $note =~ s/Bs/C/;
        $note =~ s/Cf/B/;
        $note =~ s/Ff/E/;
        push @formatted, $note;
    }
    return @formatted;
}


sub set_time_sig {
    my ($score, $signature) = @_;
    my ($beats, $divisions) = split /\//, $signature;
    $score->time_signature(
        $beats,
        ($divisions == 8 ? 3 : 2),
        ($divisions == 8 ? 24 : 18 ),
        8
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::Util - MIDI Utilities

=head1 VERSION

version 0.0703

=head1 SYNOPSIS

  use MIDI::Util;

  my $dump = MIDI::Util::dump('volume'); # length, etc.
  print Dumper $dump;

  my $score = MIDI::Util::setup_score( bpm => 120, etc => '...', );

  MIDI::Util::set_time_sig( $score, '5/4' );

  MIDI::Util::set_chan_patch( $score, 0, 1 );

  my @notes = MIDI::Util::midi_format('C','C#','Db','D'); # C, Cs, Df, D

  $score->n('wn', @notes);         # MIDI::Simple functionality
  $score->write_score('some.mid'); # MIDI::Simple functionality

=head1 DESCRIPTION

C<MIDI::Util> comprises handy MIDI utilities.

Nothing is exported by default.

=head1 FUNCTIONS

=head2 setup_score

  $score = MIDI::Util::setup_score;  # Use defaults

  $score = MIDI::Util::setup_score(  # Override defaults
    lead_in   => $beats,
    volume    => $volume,
    bpm       => $bpm,
    channel   => $channel,
    patch     => $patch,
    octave    => $octave,
    signature => $signature,
  );

Set basic MIDI parameters and return a L<MIDI::Simple> object.  If
given a B<lead_in>, play a hi-hat for that many beats.  Do not
include a B<lead_in> by passing C<0> as its value.

Named parameters and defaults:

  lead_in:   4
  volume:    120
  bpm:       100
  channel:   0
  patch:     0
  octave:    4
  signature: 4/4

=head2 set_chan_patch

  MIDI::Util::set_chan_patch( $score, $channel );  # Just set the channel

  MIDI::Util::set_chan_patch( $score, $channel, $patch );

Set the MIDI channel and patch.

Positional parameters and defaults:

  score:   undef (required)
  channel: 0
  patch:   undef

=head2 dump

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

=head2 midi_format

  @formatted = MIDI::Util::midi_format(@notes);

Change sharp C<#> and flat C<b>, in the list of named notes, to the
L<MIDI::Simple> C<s> and C<f> respectively.

=head2 set_time_sig

  MIDI::Util::set_time_sig( $score, $signature );

Set the B<score> C<time_signature> based on the given string.

=head1 SEE ALSO

The F<t/01-functions.t> test file in this distribution

L<MIDI>

L<MIDI::Simple>

L<Music::Tempo>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
