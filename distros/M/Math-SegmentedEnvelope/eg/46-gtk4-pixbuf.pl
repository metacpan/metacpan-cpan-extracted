#!/usr/bin/env perl
# GTK4 Pixbuf rendering: generate envelope as a pixel buffer image
# Renders envelope as a 2D heatmap/spectrogram-style visualization
# Two envelopes modulate X and Y to create a 2D intensity field
#
# Requires: Glib::Object::Introspection, GTK4, GdkPixbuf
use strict;
use warnings;

use Glib::Object::Introspection;

Glib::Object::Introspection->setup(
    basename => 'Gtk', version => '4.0', package => 'Gtk4');
Glib::Object::Introspection->setup(
    basename => 'Gdk', version => '4.0', package => 'Gdk4');
Glib::Object::Introspection->setup(
    basename => "Gio", version => "2.0", package => "Gio");
Glib::Object::Introspection->setup(
    basename => 'GdkPixbuf', version => '2.0', package => 'GdkPixbuf');

use Math::SegmentedEnvelope qw(adsr perc env spline);

my $W = 512;
my $H = 512;

# Two envelopes define the 2D field
my $env_x = adsr(0.05, 0.15, 0.6, 0.2, morpher_formula => 'smoothstep');
my $env_y = spline([0, 0.2, 0.5, 0.8, 1.0], [0, 1, 0.3, 0.8, 0]);

# Color palette envelope (hue variation)
my $hue_env = env(
    [[0, 0.3, 0.6, 1.0], [0.33, 0.33, 0.34], [1, 1, 1]],
    is_fold_over => 1,
);

my $sx = $env_x->static;
my $sy = $env_y->static;
my $sh = $hue_env->static;
my $dx = $env_x->duration;
my $dy = $env_y->duration;
my $dh = $hue_env->duration;

# Generate pixel data
my $data = '';
my $channels = 3;  # RGB
my $rowstride = $W * $channels;
# Pad rowstride to 4-byte boundary
$rowstride = ($rowstride + 3) & ~3;

for my $y (0 .. $H - 1) {
    my $vy = $sy->(($y / ($H - 1)) * $dy);
    my $row = '';
    for my $x (0 .. $W - 1) {
        my $vx = $sx->(($x / ($W - 1)) * $dx);

        # Combine: intensity = vx * vy, with hue variation
        my $intensity = $vx * $vy;
        my $hue = $sh->($intensity * $dh);

        # HSV to RGB
        my ($r, $g, $b) = hsv2rgb($hue, 0.8, $intensity);
        $row .= pack('CCC', int($r * 255), int($g * 255), int($b * 255));
    }
    # Pad row to rowstride
    $row .= "\0" x ($rowstride - $W * $channels);
    $data .= $row;
}

sub hsv2rgb {
    my ($h, $s, $v) = @_;
    $h = ($h - int($h)) * 6;
    my $f = $h - int($h);
    my $p = $v * (1 - $s);
    my $q = $v * (1 - $s * $f);
    my $t = $v * (1 - $s * (1 - $f));
    my @rgb = ([$v,$t,$p], [$q,$v,$p], [$p,$v,$t],
               [$p,$q,$v], [$t,$p,$v], [$v,$p,$q]);
    return @{$rgb[int($h) % 6]};
}

# Create pixbuf from raw data
my $pixbuf = GdkPixbuf::Pixbuf->new_from_data(
    $data, 'rgb', 0, 8, $W, $H, $rowstride);

my $app = Gtk4::Application->new('org.cpan.envelope.pixbuf', 'default-flags');

$app->signal_connect(activate => sub {
    my ($app) = @_;
    my $win = Gtk4::ApplicationWindow->new($app);
    $win->set_title('Envelope 2D Field (Pixbuf)');
    $win->set_default_size($W, $H);

    my $picture = Gtk4::Picture->new_for_pixbuf($pixbuf);
    $win->set_child($picture);
    $win->present;
});

printf "Generated %dx%d envelope field (%d bytes)\n", $W, $H, length($data);
exit($app->run(\@ARGV));
