package MIDI::Util;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: MIDI Utilities

our $VERSION = '0.1304';

use strict;
use warnings;

use File::Slurper qw(write_text);
use List::Util qw(first);
use MIDI ();
use MIDI::Simple ();
use Music::Tempo qw(bpm_to_ms);
use Exporter 'import';

our @EXPORT = qw(
    midi_dump
    reverse_dump
    midi_format
    set_chan_patch
    set_time_signature
    setup_score
    dura_size
    ticks
    timidity_conf
    play_timidity
    play_fluidsynth
    get_microseconds
    score2events
);

use constant TICKS => 96;


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

    set_time_signature($score, $args{signature});

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


sub midi_dump {
    my ($key) = @_;

    if ( lc $key eq 'volume' ) {
        return {
            map { $_ => $MIDI::Simple::Volume{$_} }
                sort { $MIDI::Simple::Volume{$a} <=> $MIDI::Simple::Volume{$b} }
                    keys %MIDI::Simple::Volume
        };
    }
    elsif ( lc $key eq 'length' ) {
        return {
            map { $_ => $MIDI::Simple::Length{$_} }
                sort { $MIDI::Simple::Length{$a} <=> $MIDI::Simple::Length{$b} }
                    keys %MIDI::Simple::Length
        };
    }
    elsif ( lc $key eq 'ticks' ) {
        return {
            map { $_ => $MIDI::Simple::Length{$_} * TICKS }
                sort { $MIDI::Simple::Length{$a} <=> $MIDI::Simple::Length{$b} }
                    keys %MIDI::Simple::Length
        };
    }
    elsif ( lc $key eq 'note' ) {
        return {
            map { $_ => $MIDI::Simple::Note{$_} }
                sort { $MIDI::Simple::Note{$a} <=> $MIDI::Simple::Note{$b} }
                    keys %MIDI::Simple::Note
        };
    }
    elsif ( lc $key eq 'note2number' ) {
        return {
            map { $_ => $MIDI::note2number{$_} }
                sort { $MIDI::note2number{$a} <=> $MIDI::note2number{$b} }
                    keys %MIDI::note2number
        };
    }
    elsif ( lc $key eq 'number2note' ) {
        return {
            map { $_ => $MIDI::number2note{$_} }
                sort { $a <=> $b }
                    keys %MIDI::number2note
        };
    }
    elsif ( lc $key eq 'patch2number' ) {
        return {
            map { $_ => $MIDI::patch2number{$_} }
                sort { $MIDI::patch2number{$a} <=> $MIDI::patch2number{$b} }
                    keys %MIDI::patch2number
        };
    }
    elsif ( lc $key eq 'number2patch' ) {
        return {
            map { $_ => $MIDI::number2patch{$_} }
                sort { $a <=> $b }
                    keys %MIDI::number2patch
        };
    }
    elsif ( lc $key eq 'notenum2percussion' ) {
        return {
            map { $_ => $MIDI::notenum2percussion{$_} }
                sort { $a <=> $b }
                    keys %MIDI::notenum2percussion
        };
    }
    elsif ( lc $key eq 'percussion2notenum' ) {
        return {
            map { $_ => $MIDI::percussion2notenum{$_} }
                sort { $MIDI::percussion2notenum{$a} <=> $MIDI::percussion2notenum{$b} }
                    keys %MIDI::percussion2notenum
        };
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


sub reverse_dump {
    my ($name, $precision) = @_;

    $precision //= -1;

    my %by_value;

    my $dump = midi_dump($name); # dumps an arrayref

    for my $key (keys %$dump) {
        my $val = $name eq 'length' && $precision >= 0
            ? sprintf('%.*f', $precision, $dump->{$key})
            : $dump->{$key};
        $by_value{$val} = $key;
    }

    return \%by_value;
}


sub midi_format {
    my (@notes) = @_;
    my @formatted;
    for my $note (@notes) {
        $note =~ s/C##/D/;
        $note =~ s/D##/E/;
        $note =~ s/F##/G/;
        $note =~ s/G##/A/;

        $note =~ s/Dbb/C/;
        $note =~ s/Ebb/D/;
        $note =~ s/Abb/G/;
        $note =~ s/Bbb/A/;

        $note =~ s/E#/F/;
        $note =~ s/B#/C/;

        $note =~ s/Cb/B/;
        $note =~ s/Fb/E/;

        $note =~ s/#/s/;
        $note =~ s/b/f/;

        push @formatted, $note;
    }
    return @formatted;
}


sub set_time_signature {
    my ($score, $signature) = @_;
    my ($beats, $divisions) = split /\//, $signature;
    $score->time_signature(
        $beats,
        ($divisions == 8 ? 3 : 2),
        ($divisions == 8 ? 24 : 18 ),
        8
    );
}


sub dura_size {
    my ($duration, $ppqn) = @_;
    $ppqn ||= TICKS;
    my $size = 0;
    if ($duration =~ /^d(\d+)$/) {
        $size = sprintf '%0.f', $1 / $ppqn;
    }
    else {
        $size = $MIDI::Simple::Length{$duration};
    }
    return $size;
}


sub ticks {
    my ($score) = @_;
    return ${ $score->{Tempo} };
}


sub timidity_conf {
    my ($soundfont, $config_file) = @_;
    my $config = "soundfont $soundfont\n";
    write_text($config_file, $config) if $config_file;
    return $config;
}


sub play_timidity {
    my ($score, $midi, $soundfont, $config) = @_;
    $score->write_score($midi);
    my @cmd;
    if ($soundfont) {
        $config ||= 'timidity-midi-util.cfg';
        timidity_conf($soundfont, $config);
        @cmd = ('timidity', '-c', $config, '-Od', $midi);
    }
    else {
        @cmd = ('timidity', '-Od', $midi);
    }
    system(@cmd) == 0 or die "system(@cmd) failed: $?";
}


sub play_fluidsynth {
    my ($score, $midi, $soundfont, $config) = @_;
    if (!$config && $^O eq 'darwin') {
        $config = [qw(-a coreaudio -m coremidi -i)];
    }
    elsif (!$config && $^O eq 'MSWin32') {
        $config = [];
    }
    elsif (!$config) { # linux
        $config = [qw(-a alsa -m alsa_seq -i)];
    }
    my @cmd;
    @cmd = ('fluidsynth', @$config, $soundfont, $midi);
    system(@cmd) == 0 or die "system(@cmd) failed: $?";
}


sub get_microseconds {
    my ($score) = @_;
    my $tempo = first { $_->[0] eq 'set_tempo' } @{ $score->{Score} };
    return $tempo->[2] / ${ $score->{Tempo} };
}


sub score2events {
    my ($score) = @_;
    return MIDI::Score::score_r_to_events_r($score->{Score});
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::Util - MIDI Utilities

=head1 VERSION

version 0.1304

=head1 SYNOPSIS

  use MIDI::Util qw(
    midi_dump
    reverse_dump
    midi_format
    set_chan_patch
    set_time_signature
    setup_score
    dura_size
    ticks
    timidity_conf
    play_timidity
    play_fluidsynth
    get_microseconds
    score2events
  );

  my $dump = midi_dump('length'); # volume, etc.
  $dump = reverse_dump('length');
  print Dumper $dump;

  my $size = dura_size('dqn'); # 1.5

  my $score = setup_score( bpm => 120, etc => '...', );

  my $ticks = ticks($score);
  my $half = 'd' . ( $size / 2 * $ticks );

  set_time_signature( $score, '5/4' );

  set_chan_patch( $score, 0, 1 );

  my @notes = midi_format('C','C#','Db','D'); # C, Cs, Df, D

  $score->n( $half, @notes );      # MIDI::Simple functionality
  $score->write_score('some.mid'); # "

  my $cfg = timidity_conf('/some/soundfont.sf2');
  timidity_conf('soundfont.sf2', 'timidity.cfg'); # save to a file

  # Or you can just play the score:
  play_timidity($score, 'some.mid');

  my $ms = get_microseconds($score);

  my $events = score2events($score);

=head1 DESCRIPTION

C<MIDI::Util> comprises handy MIDI utilities.

Nothing is exported by default.

=head1 FUNCTIONS

=head2 setup_score

  $score = setup_score;  # Use defaults
  $score = setup_score(  # Override defaults
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

  set_chan_patch( $score, $channel );  # Just set the channel
  set_chan_patch( $score, $channel, $patch );

Set the MIDI channel and patch.

Positional parameters and defaults:

  score:   undef (required)
  channel: 0
  patch:   undef

=head2 midi_dump

  $dump = midi_dump($name);

Return a hash or array reference of the following L<MIDI>,
L<MIDI::Simple>, and L<MIDI::Event> internal lists:

  Hashes:
    volume
    length
    ticks
    note
    note2number
    number2note
    patch2number
    number2patch
    notenum2percussion
    percussion2notenum
  Arrays:
    all_events
    midi_events
    meta_events
    text_events
    nontext_meta_events

=head2 reverse_dump

  $by_value = reverse_dump($name);
  $by_value = reverse_dump($name, $precision); # for name = length

Return the reversed hashref from the B<midi_dump> routine hashes section.

=head2 midi_format

  @formatted = midi_format(@notes);

Change sharp C<#> and flat C<b>, in the list of named notes, to the
L<MIDI::Simple> C<s> and C<f> respectively.

Also change accidentals and double-accidentals into their note
equivalents, e.g. C<Cb> to C<B>, C<C##> to C<D>, etc.

=head2 set_time_signature

  set_time_signature( $score, $signature );

Set the B<score> C<time_signature> based on the given string.

=head2 dura_size

  $size = dura_size($duration);
  $size = dura_size($duration, $ppqn);

Return the B<duration> size based on the L<MIDI::Simple> C<Length>
value (e.g. C<hn>, C<ten>) or number of ticks (if given as C<d###>).

If a B<ppqn> value is not given, we use the MIDI::Simple value of
C<96> ticks.

=head2 ticks

  $ticks = ticks($score);

Return the B<score> ticks.

=head2 timidity_conf

  $timidity_conf = timidity_conf($soundfont);
  timidity_conf($soundfont, $config_file);

A suggested timidity.cfg paragraph to allow you to use the given
soundfont in timidity. If a B<config_file> is given, the timidity
configuration is written to that file.

=head2 play_timidity

  play_timidity($score_obj, $midi_file, $soundfont, $config_file);

Play a given B<score> named B<midi_file> with C<timidity> and a
B<soundfont> file.

If a soundfont is given, then if a B<config_file> is given, that is
used for the timidity configuration. If not, C<timidity-midi-util.cfg>
is used. If a soundfont is not given, a timidity configuration file is
not rendered and used.

=head2 play_fluidsynth

  play_fluidsynth($score_obj, $midi_file, $soundfont, \@config);

Play a given B<score> named B<midi_file> with C<fluidsynth> and a
B<soundfont> file and optional system B<config>.

For C,darwin> is is C<-a coreaudio -m coremidi>. For linux systems,
this is C<-a alsa -m alsa_seq>.

Of course you'll need to have C<fludisynth> installed.

=head2 get_microseconds

  get_microseconds($score_obj);

Calculate the microseconds of a tick given a B<score>, with tempo and
ticks.

=head2 score2events

  score2events($score_obj);

Return the B<score> as array reference of events.

=head1 SEE ALSO

The F<t/01-functions.t> test file and F<eg/*> examples in this distribution.

L<Exporter>

L<File::Slurper>

L<List::Util>

L<MIDI>

L<MIDI::Simple>

L<Music::Tempo>

=head1 AUTHOR

Gene Boggs <gene.boggs@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2025 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
