#!/usr/bin/env perl
# GTK4 dynamic rendering: animated envelope playback with real-time cursor
# Shows the envelope being evaluated in real-time with a moving playhead
#
# Requires: Glib::Object::Introspection, GTK4
use strict;
use warnings;

use POSIX;
END { POSIX::_exit(0) }

use Cairo;
use Cairo::GObject;
use Glib::Object::Introspection;
use Glib qw(TRUE FALSE);

Glib::Object::Introspection->setup(
    basename => 'Gtk', version => '4.0', package => 'Gtk4');
Glib::Object::Introspection->setup(
    basename => 'Gdk', version => '4.0', package => 'Gdk4');
Glib::Object::Introspection->setup(
    basename => "Gio", version => "2.0", package => "Gio");

use Math::SegmentedEnvelope qw(adsr perc env spline);
use Time::HiRes qw(time);

my $W = 900;
my $H = 500;
my $PAD = 50;

# Envelope + morpher cycling
my @envs = (
    adsr(0.1, 0.15, 0.7, 0.3, morpher_formula => 'smoothstep'),
    perc(0.01, 0.8, morpher_formula => 'cubic_out'),
    spline([0, 0.2, 0.4, 0.6, 0.8, 1.0], [0, 0.9, 0.2, 0.8, 0.3, 0],
           morpher_formula => 'smoothstep'),
    env([[0, 1, 0.3, 0.8, 0], [0.2, 0.15, 0.35, 0.3], [3, -2, 2, -3]],
        morpher_formula => 'bounce_out'),
);
my @labels = ('ADSR', 'Percussive', 'Spline', 'Custom + Bounce');

my $env_idx = 0;
my $current = $envs[0];
my $static_eval = $current->static;
my $start_time = time();
my $loop_dur = $current->duration;

# Playback history for trail effect
my @history;
my $max_history = 200;

sub draw_func {
    my ($area, $cr, $width, $height) = @_;

    my $t = (time() - $start_time);
    my $phase = $t / $loop_dur;
    $phase -= int($phase);
    my $playhead = $phase;
    my $val = $static_eval->($playhead * $loop_dur);

    # Record history
    push @history, [$playhead, $val];
    shift @history while @history > $max_history;

    my $pw = $width - 2 * $PAD;
    my $ph = $height - 2 * $PAD - 60;  # room for info

    # Background
    $cr->set_source_rgb(0.06, 0.06, 0.1);
    $cr->paint;

    # Grid
    $cr->set_line_width(0.5);
    for my $i (0 .. 10) {
        my $a = ($i == 0 || $i == 10) ? 0.3 : 0.08;
        $cr->set_source_rgba(1, 1, 1, $a);
        my $x = $PAD + $i / 10 * $pw;
        $cr->move_to($x, $PAD); $cr->line_to($x, $PAD + $ph); $cr->stroke;
        my $y = $PAD + $i / 10 * $ph;
        $cr->move_to($PAD, $y); $cr->line_to($PAD + $pw, $y); $cr->stroke;
    }

    # Waveform fill
    my $samples = int($pw / 2);
    my @vals = $current->table($samples);
    $cr->set_source_rgba(0.2, 0.5, 1.0, 0.1);
    $cr->move_to($PAD, $PAD + $ph);
    for my $i (0 .. $#vals) {
        my $x = $PAD + $i / $#vals * $pw;
        my $y = $PAD + (1 - $vals[$i]) * $ph;
        $cr->line_to($x, $y);
    }
    $cr->line_to($PAD + $pw, $PAD + $ph);
    $cr->close_path; $cr->fill;

    # Waveform stroke
    $cr->set_source_rgba(0.3, 0.6, 1.0, 0.8);
    $cr->set_line_width(2);
    for my $i (0 .. $#vals) {
        my $x = $PAD + $i / $#vals * $pw;
        my $y = $PAD + (1 - $vals[$i]) * $ph;
        $i == 0 ? $cr->move_to($x, $y) : $cr->line_to($x, $y);
    }
    $cr->stroke;

    # History trail (fading dots)
    for my $hi (0 .. $#history) {
        my ($hx, $hy) = @{$history[$hi]};
        my $alpha = ($hi + 1) / @history * 0.6;
        $cr->set_source_rgba(1.0, 0.8, 0.2, $alpha);
        my $x = $PAD + $hx * $pw;
        my $y = $PAD + (1 - $hy) * $ph;
        $cr->arc($x, $y, 2, 0, 3.14159 * 2);
        $cr->fill;
    }

    # Playhead line
    my $px = $PAD + $playhead * $pw;
    $cr->set_source_rgba(1.0, 0.3, 0.3, 0.8);
    $cr->set_line_width(1.5);
    $cr->move_to($px, $PAD); $cr->line_to($px, $PAD + $ph); $cr->stroke;

    # Current value dot
    my $py = $PAD + (1 - $val) * $ph;
    $cr->set_source_rgb(1.0, 1.0, 0.3);
    $cr->arc($px, $py, 5, 0, 3.14159 * 2);
    $cr->fill;

    # Value readout
    $cr->set_source_rgb(0.9, 0.9, 0.9);
    $cr->move_to($PAD, $height - 30);
    $cr->show_text(sprintf "t=%.3f  val=%.4f  dur=%.2fs  [%s]",
        $playhead * $loop_dur, $val, $loop_dur, $labels[$env_idx]);

    # Segment markers
    $cr->set_source_rgba(1, 1, 1, 0.15);
    $cr->set_line_width(1);
    my $def = $current->def;
    my @durs = @{$def->[1]};
    my $acc = 0;
    for my $d (@durs) {
        $acc += $d;
        my $sx = $PAD + ($acc / $loop_dur) * $pw;
        $cr->set_dash([4, 4], 0);
        $cr->move_to($sx, $PAD); $cr->line_to($sx, $PAD + $ph); $cr->stroke;
    }
    $cr->set_dash([], 0);
}

my $app = Gtk4::Application->new('org.cpan.envelope.dynamic', 'default-flags');

$app->signal_connect(activate => sub {
    my ($app) = @_;
    my $win = Gtk4::ApplicationWindow->new($app);
    $win->set_title('Envelope Oscilloscope');
    $win->set_default_size($W, $H);

    my $area = Gtk4::DrawingArea->new;
    $area->set_draw_func(\&draw_func);
    $win->set_child($area);

    # Animation: redraw at ~30fps
    Glib::Timeout->add(33, sub {
        $area->queue_draw;
        return TRUE;
    });

    # Cycle envelopes every 3 seconds
    Glib::Timeout->add(3000, sub {
        $env_idx = ($env_idx + 1) % @envs;
        $current = $envs[$env_idx];
        $static_eval = $current->static;
        $loop_dur = $current->duration;
        $start_time = time();
        @history = ();
        return TRUE;
    });

    $win->present;
});

$app->run(\@ARGV);
