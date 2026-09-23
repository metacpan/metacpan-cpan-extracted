#!/usr/bin/env perl
# GTK4 static rendering: draw envelope curves into a GdkPixbuf via Cairo
# Creates a window showing multiple envelopes overlaid with different colors
#
# Requires: Glib::Object::Introspection, GTK4, Cairo
use strict;
use POSIX;
use warnings;

END { POSIX::_exit(0) }  # avoid cairo/GTK cleanup order crash

use Cairo;
use Cairo::GObject;
use Glib::Object::Introspection;

Glib::Object::Introspection->setup(
    basename => 'Gtk', version => '4.0', package => 'Gtk4');
Glib::Object::Introspection->setup(
    basename => 'Gdk', version => '4.0', package => 'Gdk4');
Glib::Object::Introspection->setup(
    basename => "Gio", version => "2.0", package => "Gio");

use Math::SegmentedEnvelope qw(adsr perc asr spline env);

my $W = 800;
my $H = 400;
my $PAD = 40;

# Envelopes to display
my @curves = (
    { env => adsr(0.1, 0.15, 0.7, 0.3, morpher_formula => 'smoothstep'),
      color => [0.2, 0.5, 1.0], label => 'ADSR' },
    { env => perc(0.01, 0.5),
      color => [1.0, 0.3, 0.2], label => 'Perc' },
    { env => asr(0.2, 0.5, 0.3, peak => 0.8),
      color => [0.2, 0.8, 0.3], label => 'ASR' },
    { env => spline([0, 0.2, 0.5, 0.8, 1.0], [0, 0.9, 0.2, 0.8, 0]),
      color => [0.9, 0.6, 0.1], label => 'Spline' },
    { env => env([[0, 1], [1], [1]], morpher_formula => 'bounce_out'),
      color => [0.7, 0.2, 0.9], label => 'Bounce' },
);

sub draw_func {
    my ($area, $cr, $width, $height) = @_;
    my $pw = $width - 2 * $PAD;
    my $ph = $height - 2 * $PAD;

    # Background
    $cr->set_source_rgb(0.12, 0.12, 0.15);
    $cr->paint;

    # Grid
    $cr->set_source_rgba(1, 1, 1, 0.1);
    $cr->set_line_width(0.5);
    for my $i (0 .. 10) {
        my $x = $PAD + $i / 10 * $pw;
        $cr->move_to($x, $PAD);
        $cr->line_to($x, $PAD + $ph);
        my $y = $PAD + $i / 10 * $ph;
        $cr->move_to($PAD, $y);
        $cr->line_to($PAD + $pw, $y);
    }
    $cr->stroke;

    # Draw each envelope
    my $samples = int($pw);
    for my $curve (@curves) {
        my $e = $curve->{env};
        my ($r, $g, $b) = @{$curve->{color}};
        my @vals = $e->table($samples);

        # Find range
        my ($min, $max) = ($vals[0], $vals[0]);
        for (@vals) { $min = $_ if $_ < $min; $max = $_ if $_ > $max }
        $min = 0; $max = 1;  # normalize to [0,1] for comparison
        my $range = $max - $min || 1;

        # Fill
        $cr->set_source_rgba($r, $g, $b, 0.08);
        $cr->move_to($PAD, $PAD + $ph);
        for my $i (0 .. $#vals) {
            my $x = $PAD + $i / $#vals * $pw;
            my $y = $PAD + (1 - ($vals[$i] - $min) / $range) * $ph;
            $cr->line_to($x, $y);
        }
        $cr->line_to($PAD + $pw, $PAD + $ph);
        $cr->close_path;
        $cr->fill;

        # Stroke
        $cr->set_source_rgba($r, $g, $b, 0.9);
        $cr->set_line_width(2);
        $cr->move_to($PAD, $PAD + (1 - ($vals[0] - $min) / $range) * $ph);
        for my $i (1 .. $#vals) {
            my $x = $PAD + $i / $#vals * $pw;
            my $y = $PAD + (1 - ($vals[$i] - $min) / $range) * $ph;
            $cr->line_to($x, $y);
        }
        $cr->stroke;
    }

    # Legend
    my $ly = $PAD + 10;
    for my $curve (@curves) {
        my ($r, $g, $b) = @{$curve->{color}};
        $cr->set_source_rgb($r, $g, $b);
        $cr->rectangle($PAD + 10, $ly, 12, 12);
        $cr->fill;
        $cr->set_source_rgb(0.9, 0.9, 0.9);
        $cr->move_to($PAD + 28, $ly + 10);
        $cr->show_text($curve->{label});
        $ly += 18;
    }

    # Axes labels
    $cr->set_source_rgba(1, 1, 1, 0.5);
    $cr->move_to($PAD - 5, $height - $PAD + 15);
    $cr->show_text('0');
    $cr->move_to($width - $PAD - 5, $height - $PAD + 15);
    $cr->show_text('t');
    $cr->move_to($PAD - 25, $PAD + 5);
    $cr->show_text('1.0');
}

# GTK4 app
my $app = Gtk4::Application->new('org.cpan.envelope.static', 'default-flags');

$app->signal_connect(activate => sub {
    my ($app) = @_;
    my $win = Gtk4::ApplicationWindow->new($app);
    $win->set_title('Math::SegmentedEnvelope - Static View');
    $win->set_default_size($W, $H);

    my $area = Gtk4::DrawingArea->new;
    $area->set_draw_func(\&draw_func);
    $win->set_child($area);
    $win->present;
});

$app->run(\@ARGV);
