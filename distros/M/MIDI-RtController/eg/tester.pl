#!/usr/bin/env perl

# PERL_FUTURE_DEBUG=1 perl eg/tester.pl

use Future::IO::Impl::IOAsync;
use MIDI::Drummer::Tiny ();
use MIDI::RtController ();
use MIDI::RtMidi::ScorePlayer ();
use Term::TermKey::Async qw(FORMAT_VIM KEYMOD_CTRL);

use constant CHANNEL   => 0;
use constant DRUMS     => 9;
use constant PEDAL     => 55; # G below middle C
use constant DELAY_INC => 0.01;
use constant VELO_INC  => 10; # volume change offset

my $input_name   = shift || 'tempopad'; # midi controller device
my $output_name  = shift || 'fluid';    # fluidsynth
my $filter_names = shift || '';         # delay,pedal,drums

my @filter_names = split /\s*,\s*/, $filter_names;

my %dispatch = (
    pedal => sub { add_filters(pedal => \&pedal_tone) },
    delay => sub { add_filters(delay => \&delay_tone) },
    drums => sub { add_filters(drums => \&drums) },
);

$dispatch{$_}->() for @filter_names;

my $channel  = CHANNEL;
my $delay    = 0.1; # seconds
my $feedback = 1;

my $rtc = MIDI::RtController->new(
    input  => $input_name,
    output => $output_name,
);

my $tka = Term::TermKey::Async->new(
    term   => \*STDIN,
    on_key => sub {
        my ($self, $key) = @_;
        my $pressed = $self->format_key($key, FORMAT_VIM);
        # say "Got key: $pressed";
        if ($pressed =~ /^\d$/) { $feedback = $pressed }
        elsif ($pressed eq 'u') { $channel = $channel ? CHANNEL : DRUMS }
        elsif ($pressed eq '<') { $delay -= DELAY_INC unless $delay <= 0 }
        elsif ($pressed eq '>') { $delay += DELAY_INC }
        elsif ($pressed eq 'p') { $dispatch{pedal}->() unless grep { 'pedal' eq $_ } @filter_names }
        elsif ($pressed eq 'd') { $dispatch{delay}->() unless grep { 'delay' eq $_ } @filter_names }
        elsif ($pressed eq 'y') { $dispatch{drums}->() unless grep { 'drums' eq $_ } @filter_names }
        $rtc->loop->loop_stop if $key->type_is_unicode and
                                 $key->utf8 eq 'C' and
                                 $key->modifiers & KEYMOD_CTRL;
    },
);
$rtc->loop->add($tka);

$rtc->run;

sub add_filters ($name, $coderef) {
    $rtc->add_filter($name, $_, $coderef)
        for qw(note_on note_off);
}

sub pedal_notes ($note) {
    return PEDAL, $note, $note + 7;
}
sub pedal_tone ($dt, $event) {
    my ($ev, $chan, $note, $vel) = $event->@*;
    my @notes = pedal_notes($note);
    my $delay_time = 0;
    for my $n (@notes) {
        $delay_time += $delay;
        $rtc->delay_send($delay_time, [ $ev, $channel, $n, $vel ]);
    }
    return 0;
}

sub delay_notes ($note) {
    return ($note) x $feedback;
}
sub delay_tone ($dt, $event) {
    my ($ev, $chan, $note, $vel) = $event->@*;
    my @notes = delay_notes($note);
    my $delay_time = 0;
    for my $n (@notes) {
        $delay_time += $delay;
        $rtc->delay_send($delay_time, [ $ev, $channel, $n, $vel ]);
        $vel -= VELO_INC;
    }
    return 0;
}

sub drum_parts ($note) {
    # warn __PACKAGE__,' L',__LINE__,' ',,"N: $note\n";
    my $part;
    if ($note == 99) {
        $part = sub {
            my (%args) = @_;
            $args{drummer}->metronome4;
        };
    }
    else {
        $part = sub {
            my (%args) = @_;
            $args{drummer}->note($args{drummer}->sixtyfourth, $note);
        };
    }
    return $part;
}
sub drums ($dt, $event) {
    my ($ev, $chan, $note, $vel) = $event->@*;
    return 1 unless $ev eq 'note_on';
    my $part = drum_parts($note);
    my $d = MIDI::Drummer::Tiny->new(bpm => 100);
    MIDI::RtMidi::ScorePlayer->new(
      device   => $rtc->_midi_out,
      score    => $d->score,
      common   => { drummer => $d },
      parts    => [ $part ],
      sleep    => 0,
      infinite => 0,
      # dump     => 1,
    )->play_async->retain;
    return 1;
}
