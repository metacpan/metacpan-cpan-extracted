package MIDI::RtController::Filter::Tonal;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Tonal RtController filters

use v5.36;

our $VERSION = '0.0302';

use strictures 2;
use Array::Circular ();
use List::SomeUtils qw(first_index);
use List::Util qw(shuffle uniq);
use MIDI::RtMidi::ScorePlayer ();
use Moo;
use Music::Scales qw(get_scale_MIDI get_scale_notes);
use Music::Chord::Note ();
use Music::Note ();
use Music::ToRoman ();
use Music::VoiceGen ();
use Types::MIDI qw(Channel);
use Types::Standard qw(ArrayRef Num Maybe Str);
use namespace::clean;



has rtc => (
    is  => 'ro',
    isa => sub { die 'Invalid rtc' unless ref($_[0]) eq 'MIDI::RtController' },
    required => 1,
);


has pedal => (
    is  => 'rw',
    isa => Num,
    default => sub { 55 },
);


has channel => (
    is  => 'rw',
    isa => Channel,
    default => sub { 0 },
);


has value => (
    is      => 'rw',
    isa     => Maybe[Num],
    default => undef,
);


has trigger => (
    is      => 'rw',
    isa     => Maybe[Num],
    default => undef,
);


has delay => (
    is  => 'rw',
    isa => Num,
    default => sub { 0.1 },
);


has velocity => (
    is  => 'rw',
    isa => Num,
    default => sub { 10 },
);


has feedback => (
    is  => 'rw',
    isa => Num,
    default => sub { 1 },
);


has offset => (
    is  => 'rw',
    isa => Num,
    default => sub { -12 },
);


has key => (
    is  => 'rw',
    isa => Str,
    default => sub { 'C' },
);


has scale => (
    is  => 'rw',
    isa => Str,
    default => sub { 'major' },
);


has intervals => (
    is  => 'rw',
    isa => ArrayRef[Num],
    default => sub { [qw(-3 -2 -1 1 2 3)] },
);


has arp => (
    is  => 'rw',
    isa => ArrayRef[Num],
    default => sub { [] },
);


has arp_types => (
    is  => 'rw',
    isa => sub { die 'Invalid rtc' unless ref($_[0]) eq 'Array::Circular' },
    default => sub { Array::Circular->new(qw(up down random)) },
);


has arp_type => (
    is  => 'rw',
    isa => Str,
    default => sub { 'up' },
);


sub _pedal_notes ($self, $note) {
    return $self->pedal, $note, $note + 7;
}
sub pedal_tone ($self, $device, $dt, $event) {
    my ($ev, $chan, $note, $val) = $event->@*;
    return 0 if defined $self->trigger && $note != $self->trigger;
    return 0 if defined $self->value && $val != $self->value;

    my @notes = $self->_pedal_notes($note);
    my $delay_time = 0;
    for my $n (@notes) {
        $delay_time += $self->delay;
        $self->rtc->delay_send($delay_time, [ $ev, $self->channel, $n, $val ]);
    }
    return 0;
}


sub _chord_notes ($self, $note) {
    my $mn = Music::Note->new($note, 'midinum');
    my $base = uc($mn->format('isobase'));
    my @scale = get_scale_notes($self->key, $self->scale);
    my $index = first_index { $_ eq $base } @scale;
    return $note if $index == -1;
    my $mtr = Music::ToRoman->new(scale_note => $base);
    my @chords = $mtr->get_scale_chords;
    my $chord = $scale[$index] . $chords[$index];
    my $cn = Music::Chord::Note->new;
    my @notes = $cn->chord_with_octave($chord, $mn->octave);
    @notes = map { Music::Note->new($_, 'ISO')->format('midinum') } @notes;
    return @notes;
}
sub chord_tone ($self, $device, $dt, $event) {
    my ($ev, $chan, $note, $val) = $event->@*;
    return 0 if defined $self->trigger && $note != $self->trigger;
    return 0 if defined $self->value && $val != $self->value;

    my @notes = $self->_chord_notes($note);
    $self->rtc->send_it([ $ev, $self->channel, $_, $val ]) for @notes;
    return 0;
}


sub _delay_notes ($self, $note) {
    return ($note) x $self->feedback;
}
sub delay_tone ($self, $device, $dt, $event) {
    my ($ev, $chan, $note, $val) = $event->@*;
    return 0 if defined $self->trigger && $note != $self->trigger;
    return 0 if defined $self->value && $val != $self->value;

    my @notes = $self->_delay_notes($note);
    my $delay_time = 0;
    for my $n (@notes) {
        $delay_time += $self->delay;
        $self->rtc->delay_send($delay_time, [ $ev, $self->channel, $n, $val ]);
        $val -= $self->velocity;
    }
    return 0;
}


sub _offset_notes ($self, $note) {
    my @notes = ($note);
    push @notes, $note + $self->offset if $self->offset;
    return @notes;
}
sub offset_tone ($self, $device, $dt, $event) {
    my ($ev, $chan, $note, $val) = $event->@*;
    return 0 if defined $self->trigger && $note != $self->trigger;
    return 0 if defined $self->value && $val != $self->value;

    my @notes = $self->_offset_notes($note);
    $self->rtc->send_it([ $ev, $self->channel, $_, $val ]) for @notes;
    return 0;
}


sub _walk_notes ($self, $note) {
    my $mn = Music::Note->new($note, 'midinum');
    my @pitches = (
        get_scale_MIDI($self->key, $mn->octave, $self->scale),
        get_scale_MIDI($self->key, $mn->octave + 1, $self->scale),
    );
    my $voice = Music::VoiceGen->new(
        pitches   => \@pitches,
        intervals => $self->intervals,
    );
    my @notes = map { $voice->rand } 1 .. $self->feedback;
    return @notes;
}
sub walk_tone ($self, $device, $dt, $event) {
    my ($ev, $chan, $note, $val) = $event->@*;
    return 0 if defined $self->trigger && $note != $self->trigger;
    return 0 if defined $self->value && $val != $self->value;

    # make sure the note_on and note_off notes are the same
    my $notes = $self->arp;
    if (@$notes) {
        $self->arp([]);
    }
    else {
        @$notes = $self->_walk_notes($note);
        $self->arp($notes);
    }

    my $delay_time = 0;
    for my $n (@$notes) {
        $delay_time += $self->delay;
        $self->rtc->delay_send($delay_time, [ $ev, $self->channel, $n, $val ]);
    }
    return 0;
}


sub _arp_notes ($self, $note) {
    $self->feedback(2) if $self->feedback < 2;
    my @tmp = $self->arp->@*;
    if (@tmp >= 2 * $self->feedback) { # double, on/off note event
        shift @tmp;
        shift @tmp;
    }
    push @tmp, $note;
    $self->arp(\@tmp);
    my @notes = uniq @tmp;
    if ($self->arp_type eq 'up') {
        @notes = sort { $a <=> $b } @notes;
    }
    elsif ($self->arp_type eq 'down') {
        @notes = sort { $b <=> $a } @notes;
    }
    elsif ($self->arp_type eq 'random') {
        @notes = shuffle @notes;
    }
    return @notes;
}
sub arp_tone ($self, $device, $dt, $event) {
    my ($ev, $chan, $note, $val) = $event->@*;
    return 0 if defined $self->trigger && $note != $self->trigger;
    return 0 if defined $self->value && $val != $self->value;

    my @notes = $self->_arp_notes($note);
    my $delay_time = 0;
    for my $n (@notes) {
        $self->rtc->delay_send($delay_time, [ $ev, $self->channel, $n, $val ]);
        $delay_time += $self->delay;
    }
    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::RtController::Filter::Tonal - Tonal RtController filters

=head1 VERSION

version 0.0302

=head1 SYNOPSIS

  use curry;
  use MIDI::RtController ();
  use MIDI::RtController::Filter::Tonal ();

  my $rtc = MIDI::RtController->new(
    input  => 'keyboard',
    output => 'usb',
  );

  my $filter = MIDI::RtController::Filter::Tonal->new(rtc => $rtc);

  $rtc->add_filter('pedal', note_on => $filter->curry::pedal_tone);

  $rtc->run;

=head1 DESCRIPTION

C<MIDI::RtController::Filter::Tonal> is the collection of tonal
L<MIDI::RtController> filters.

=head1 ATTRIBUTES

=head2 rtc

  $rtc = $filter->rtc;

The required L<MIDI::RtController> instance provided in the
constructor.

=head2 pedal

  $pedal = $filter->pedal;
  $filter->pedal($note);

The B<note> used by the pedal-tone filter.

Default: C<55>

Which is the MIDI-number for G below middle-C.

=head2 channel

  $channel = $filter->channel;
  $filter->channel($number);

The current MIDI channel (0-15, drums=9).

Default: C<0>

=head2 value

  $value = $filter->value;
  $filter->value($number);

Return or set the MIDI event value. This is a generic setting that can
be used by filters to set or retrieve state. This often a whole number
between C<0> and C<127>, but can take any number.

Default: C<undef>

=head2 trigger

  $trigger = $filter->trigger;
  $filter->trigger($number);

Return or set the trigger. This is a generic setting that
can be used by filters to set or retrieve state. This often a whole
number between C<0> and C<127>, but can take any number.

Default: C<undef>

=head2 delay

  $delay = $filter->delay;
  $filter->delay($number);

The current delay time.

Default: C<0.1> seconds

=head2 velocity

  $velocity = $filter->velocity;
  $filter->velocity($number);

The velocity (or volume) change increment (0-127).

Default: C<10>

=head2 feedback

  $feedback = $filter->feedback;
  $filter->feedback($number);

The feedback.

Default: C<1>

=head2 offset

  $offset = $filter->offset;
  $filter->offset($number);

The note offset number.

Default: C<-12>

=head2 key

  $key = $filter->key;
  $filter->key($number);

The musical key (C<C-B>).

=head2 scale

  $scale = $filter->scale;
  $filter->scale($name);

The name of the musical scale.

=head2 intervals

  $intervals = $filter->intervals;
  $filter->intervals(\@intervals);

The voice intervals used by the C<walk_tone> filter.

=head2 arp

  $arp = $filter->arp;
  $filter->arp(\@notes);

A list of MIDI numbered pitches used by the C<arp_tone> and
C<walk_tone> filters.

=head2 arp_types

  $arp_types = $filter->arp_types;
  $filter->arp_types(\@strings);

A list of known arpeggiation types. This is an L<Array::Circular>
instance.

Default: C<[up, down, random]>

=head2 arp_type

  $arp_type = $filter->arp_type;
  $filter->arp_type($string);

The current arpeggiation type.

Default: C<up>

=head1 METHODS

All filter methods must accept the object, a MIDI device name, a
delta-time, and a MIDI event ARRAY reference, like:

  sub pedal_tone ($self, $name, $delta, $event) {
    my ($event_type, $chan, $note, $value) = $event->@*;
    ...
    return $boolean;
  }

A filter also must return a boolean value. This tells
L<MIDI::RtController> to continue processing other known filters or
not.

=head2 pedal_tone

Play a series of notes in succession by B<delay>.

Default: C<pedal, $note, $note + 7 semitones>

Where B<pedal> is the object attribute.

If B<trigger> or B<value> is set, the filter checks those against the
MIDI event C<note> or C<value>, respectively, to see if the filter
should be applied.

=head2 chord_tone

Play a diatonic chord based on the given event note, B<key> and
B<scale> attributes.

If B<trigger> or B<value> is set, the filter checks those against the
MIDI event C<note> or C<value>, respectively, to see if the filter
should be applied.

=head2 delay_tone

Play a delayed note, or series of notes, based on the given event
note, and the B<delay> and B<feedback> attributes.

If B<trigger> or B<value> is set, the filter checks those against the
MIDI event C<note> or C<value>, respectively, to see if the filter
should be applied.

=head2 offset_tone

Play a note and an offset note given the B<offset> value.

If B<trigger> or B<value> is set, the filter checks those against the
MIDI event C<note> or C<value>, respectively, to see if the filter
should be applied.

=head2 walk_tone

Play a chaotically walking, quasi-melody starting with the event note.
The number of notes in the "melody" is the B<feedback> setting.

If B<trigger> or B<value> is set, the filter checks those against the
MIDI event C<note> or C<value>, respectively, to see if the filter
should be applied.

=head2 arp_tone

Play a series of subsequently pressed notes based on the B<feedback>
setting.

If B<trigger> or B<value> is set, the filter checks those against the
MIDI event C<note> or C<value>, respectively, to see if the filter
should be applied.

=head1 SEE ALSO

The F<eg/*.pl> program(s) in this distribution

L<MIDI::RtController::Filter::Drums>

L<MIDI::RtController::Filter::Math>

L<MIDI::RtController::Filter::CC>

L<Array::Circular>

L<List::SomeUtils>

L<List::Util>

L<MIDI::RtMidi::ScorePlayer>

L<Moo>

L<Music::Scales>

L<Music::Chord::Note>

L<Music::Note>

L<Music::ToRoman>

L<Music::VoiceGen>

L<Types::MIDI>

L<Types::Standard>

=head1 AUTHOR

Gene Boggs <gene.boggs@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
