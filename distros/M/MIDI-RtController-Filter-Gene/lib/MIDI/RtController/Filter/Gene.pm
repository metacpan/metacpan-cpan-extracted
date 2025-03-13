package MIDI::RtController::Filter::Gene;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Gene's RtController filters

use v5.36;

our $VERSION = '0.0101';

use Moo;
use strictures 2;
use List::SomeUtils qw(first_index);
use List::Util qw(shuffle uniq);
use Music::Scales qw(get_scale_MIDI get_scale_notes);
use Music::Chord::Note ();
use Music::Note ();
use Music::ToRoman ();
use Music::VoiceGen ();
use Types::Standard qw(ArrayRef Num Str);
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
    isa => Num,
    default => sub { 0 },
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
    isa => ArrayRef[Str],
    default => sub { [] },
);


has arp_type => (
    is  => 'rw',
    isa => Str,
    default => sub { 'up' },
);


sub _pedal_notes ($self, $note) {
    return $self->pedal, $note, $note + 7;
}
sub pedal_tone ($self, $dt, $event) {
    my ($ev, $chan, $note, $vel) = $event->@*;
    my @notes = $self->_pedal_notes($note);
    my $delay_time = 0;
    for my $n (@notes) {
        $delay_time += $self->delay;
        $self->rtc->delay_send($delay_time, [ $ev, $self->channel, $n, $vel ]);
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
sub chord_tone ($self, $dt, $event) {
    my ($ev, $chan, $note, $vel) = $event->@*;
    my @notes = $self->_chord_notes($note);
    $self->rtc->send_it([ $ev, $self->channel, $_, $vel ]) for @notes;
    return 0;
}


sub _delay_notes ($self, $note) {
    return ($note) x $self->feedback;
}
sub delay_tone ($self, $dt, $event) {
    my ($ev, $chan, $note, $vel) = $event->@*;
    my @notes = $self->_delay_notes($note);
    my $delay_time = 0;
    for my $n (@notes) {
        $delay_time += $self->delay;
        $self->rtc->delay_send($delay_time, [ $ev, $self->channel, $n, $vel ]);
        $vel -= $self->velocity;
    }
    return 0;
}


sub _offset_notes ($self, $note) {
    my @notes = ($note);
    push @notes, $note + $self->offset if $self->offset;
    return @notes;
}
sub offset_tone ($self, $dt, $event) {
    my ($ev, $chan, $note, $vel) = $event->@*;
    my @notes = $self->_offset_notes($note);
    $self->rtc->send_it([ $ev, $self->channel, $_, $vel ]) for @notes;
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
    return map { $voice->rand } 1 .. $self->feedback;
}
sub walk_tone ($self, $dt, $event) {
    my ($ev, $chan, $note, $vel) = $event->@*;
    my @notes = $self->_walk_notes($note);
    my $delay_time = 0;
    for my $n (@notes) {
        $delay_time += $self->delay;
        $self->rtc->delay_send($delay_time, [ $ev, $self->channel, $n, $vel ]);
    }
    return 0;
}


sub _arp_notes ($self, $note) {
    $self->feedback(2) if $self->feedback < 2;;
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
sub arp_tone ($self, $dt, $event) {
    my ($ev, $chan, $note, $vel) = $event->@*;
    my @notes = $self->_arp_notes($note);
    my $delay_time = 0;
    for my $n (@notes) {
        $self->rtc->delay_send($delay_time, [ $ev, $self->channel, $n, $vel ]);
        $delay_time += $self->delay;
    }
    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::RtController::Filter::Gene - Gene's RtController filters

=head1 VERSION

version 0.0101

=head1 SYNOPSIS

  use MIDI::RtController ();
  use MIDI::RtController::Filter::Gene ();

  my $rtc = MIDI::RtController->new; # * input/output required

  my $rtf = MIDI::RtController::Filter::Gene->new(rtc => $rtc);

  $rtc->add_filter('foo', note_on => $rtf->can('foo'));

  $rtc->run;

=head1 DESCRIPTION

C<MIDI::RtController::Filter::Gene> is the collection of Gene's
L<MIDI::RtController> filters.

=head1 ATTRIBUTES

=head2 rtc

  $rtc = $rtf->rtc;

The required L<MIDI::RtController> instance provided in the
constructor.

=head2 pedal

  $pedal = $rtf->pedal;
  $rtf->pedal($note);

The B<note> used by the pedal-tone filter.

Default: C<55>

Which is the MIDI-number for G below middle-C.

=head2 channel

  $channel = $rtf->channel;
  $rtf->channel($number);

The current MIDI channel (0-15, drums=9).

Default: C<0>

=head2 delay

  $delay = $rtf->delay;
  $rtf->delay($number);

The current delay time.

Default: C<0.1> seconds

=head2 velocity

  $velocity = $rtf->velocity;
  $rtf->velocity($number);

The velocity (or volume) change increment (0-127).

Default: C<10>

=head2 feedback

  $feedback = $rtf->feedback;
  $rtf->feedback($number);

The feedback (0-127).

Default: C<1>

=head2 offset

  $offset = $rtf->offset;
  $rtf->offset($number);

The note offset number.

Default: C<-12>

=head2 key

  $key = $rtf->key;
  $rtf->key($number);

The MIDI number of the musical key.

=head2 scale

  $scale = $rtf->scale;
  $rtf->scale($name);

The name of the musical scale.

=head2 intervals

  $intervals = $rtf->intervals;
  $rtf->intervals(\@intervals);

The voice intervals used by L<Music::VoiceGen> and the C<chord_tone>
filter.

=head2 arp

  $arp = $rtf->arp;
  $rtf->arp(\@notes);

The list of MIDI numbered pitches used by the C<arp_tone> filter.

=head2 arp_types

  $arp_types = $rtf->arp_types;
  $rtf->arp_types(\@strings);

A list of known arpeggiation types.

Default: C<[up, down, random]>

=head2 arp_type

  $arp_type = $rtf->arp_type;
  $rtf->arp_type($string);

The current arpeggiation type.

Default: C<up>

=head1 METHODS

All filter methods must accept the object, a delta-time, and a MIDI
event ARRAY reference, like:

  sub pedal_tone ($self, $dt, $event) {
    my ($event_type, $chan, $note, $value) = $event->@*;
    ...
    return $boolean;
  }

A filter also must return a boolean value. This tells
L<MIDI::RtController> to continue processing other known filters or
not.

=head2 pedal_tone

  pedal, $note, $note + 7

Where the B<pedal> is the object attribute.

=head2 chord_tone

Play a diatonic chord based on the given event note, B<key> and
B<scale> attributes.

=head2 delay_tone

Play a delayed note, or series of notes, based on the given event note
and B<delay> attribute.

=head2 offset_tone

Play a note and an offset note given the B<offset> value.

=head2 walk_tone

Play a chaotically walking, quasi-melody starting with the event note.
The number of notes in the "melody" is the B<feedback> setting.

=head2 arp_tone

Play a series of subsequently pressed notes based on the B<feedback>
setting.

=head1 SEE ALSO

L<Moo>

L<List::SomeUtils>

L<Music::Scales>

L<Music::Chord::Note>

L<Music::Note>

L<Music::ToRoman>

L<Music::VoiceGen>

=head1 AUTHOR

Gene Boggs <gene.boggs@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
