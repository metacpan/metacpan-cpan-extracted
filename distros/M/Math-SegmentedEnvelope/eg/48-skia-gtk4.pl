#!/usr/bin/env perl
# Skia-accelerated rendering to GTK4: 60fps envelope animation
# Uses a C++ Skia helper (eg/libskia_helper.so) for hardware-speed rendering,
# uploads to GdkTexture via GdkPixbuf for GTK4 display.
#
# Build helper first:
#   cd eg && g++ -shared -fPIC -O2 -o libskia_helper.so skia_helper.cpp -I/usr/include/skia -lskia
#
# Requires: FFI::Platypus, Glib::Object::Introspection, GTK4, GdkPixbuf, libskia
use strict;
use warnings;
use POSIX;
END { POSIX::_exit(0) }

use FindBin;
use FFI::Platypus;
use Glib::Object::Introspection;
use Glib qw(TRUE FALSE);

Glib::Object::Introspection->setup(
    basename => 'Gtk', version => '4.0', package => 'Gtk4');
Glib::Object::Introspection->setup(
    basename => 'Gdk', version => '4.0', package => 'Gdk4');
Glib::Object::Introspection->setup(
    basename => 'Gio', version => '2.0', package => 'Gio');
Glib::Object::Introspection->setup(
    basename => 'GdkPixbuf', version => '2.0', package => 'GdkPixbuf');

use Math::SegmentedEnvelope qw(adsr perc asr spline env);
use Time::HiRes qw(time);

my $W = 800;
my $H = 450;
my $PAD = 40;

# Skia FFI
my $lib = "$FindBin::Bin/libskia_helper.so";
die "Build helper first: cd eg && g++ -shared -fPIC -O2 -o libskia_helper.so skia_helper.cpp -I/usr/include/skia -lskia\n"
    unless -f $lib;

my $ffi = FFI::Platypus->new(api => 2, lib => [$lib]);
$ffi->type('opaque' => 'SkiaCtx');

$ffi->attach(skia_create    => ['int', 'int'] => 'SkiaCtx');
$ffi->attach(skia_destroy   => ['SkiaCtx'] => 'void');
$ffi->attach(skia_clear     => ['SkiaCtx', 'uint32'] => 'void');
$ffi->attach(skia_set_color => ['SkiaCtx', 'uint8', 'uint8', 'uint8', 'uint8'] => 'void');
$ffi->attach(skia_set_stroke => ['SkiaCtx', 'float'] => 'void');
$ffi->attach(skia_set_fill  => ['SkiaCtx'] => 'void');
$ffi->attach(skia_path_reset => ['SkiaCtx'] => 'void');
$ffi->attach(skia_path_move => ['SkiaCtx', 'float', 'float'] => 'void');
$ffi->attach(skia_path_line => ['SkiaCtx', 'float', 'float'] => 'void');
$ffi->attach(skia_path_close => ['SkiaCtx'] => 'void');
$ffi->attach(skia_draw_path => ['SkiaCtx'] => 'void');
$ffi->attach(skia_draw_line => ['SkiaCtx', 'float', 'float', 'float', 'float'] => 'void');
$ffi->attach(skia_draw_circle => ['SkiaCtx', 'float', 'float', 'float'] => 'void');
$ffi->attach(skia_draw_rect => ['SkiaCtx', 'float', 'float', 'float', 'float'] => 'void');
$ffi->attach(skia_get_pixels => ['SkiaCtx', 'opaque', 'int'] => 'int');

my $ctx = skia_create($W, $H);

# Envelopes
my @curves = (
    { env => adsr(0.1, 0.15, 0.7, 0.3, morpher_formula => 'smoothstep'),
      r => 60, g => 140, b => 255, label => 'ADSR' },
    { env => perc(0.01, 0.5, morpher_formula => 'cubic_out'),
      r => 255, g => 90, b => 60, label => 'Perc' },
    { env => spline([0, 0.2, 0.5, 0.8, 1.0], [0, 0.9, 0.2, 0.8, 0]),
      r => 60, g => 210, b => 90, label => 'Spline' },
    { env => env([[0, 1], [1], [1]], morpher_formula => 'elastic_out'),
      r => 210, g => 90, b => 240, label => 'Elastic' },
);

my $pw = $W - 2 * $PAD;
my $ph = $H - 2 * $PAD;
for my $c (@curves) {
    $c->{vals} = [$c->{env}->table($pw)];
    $c->{static} = $c->{env}->static;
}

my $active_idx = 0;
my $start_time = time();
my $rowstride = ($W * 3 + 3) & ~3;
my $pixbuf_buf = "\0" x ($rowstride * $H);
my $pixbuf_ptr = unpack('Q', pack('P', $pixbuf_buf));

sub render_frame {
    my $t = time() - $start_time;
    my $dur = $curves[$active_idx]{env}->duration;
    my $phase = ($t / $dur) - int($t / $dur);

    # Clear
    skia_clear($ctx, 0xFF141418);

    # Grid
    skia_set_color($ctx, 40, 40, 50, 60);
    skia_set_stroke($ctx, 0.5);
    for my $i (0 .. 10) {
        my $x = $PAD + $i / 10 * $pw;
        skia_draw_line($ctx, $x, $PAD, $x, $PAD + $ph);
        my $y = $PAD + $i / 10 * $ph;
        skia_draw_line($ctx, $PAD, $y, $PAD + $pw, $y);
    }

    # Envelope curves
    for my $ci (0 .. $#curves) {
        my $c = $curves[$ci];
        my @v = @{$c->{vals}};
        my $active = ($ci == $active_idx);

        # Fill area
        skia_set_color($ctx, $c->{r}, $c->{g}, $c->{b}, $active ? 30 : 10);
        skia_set_fill($ctx);
        skia_path_reset($ctx);
        skia_path_move($ctx, $PAD, $PAD + $ph);
        for my $x (0 .. $#v) {
            skia_path_line($ctx, $PAD + $x, $PAD + (1 - $v[$x]) * $ph);
        }
        skia_path_line($ctx, $PAD + $#v, $PAD + $ph);
        skia_path_close($ctx);
        skia_draw_path($ctx);

        # Stroke line
        skia_set_color($ctx, $c->{r}, $c->{g}, $c->{b}, $active ? 230 : 70);
        skia_set_stroke($ctx, $active ? 2.5 : 1.5);
        skia_path_reset($ctx);
        skia_path_move($ctx, $PAD, $PAD + (1 - $v[0]) * $ph);
        for my $x (1 .. $#v) {
            skia_path_line($ctx, $PAD + $x, $PAD + (1 - $v[$x]) * $ph);
        }
        skia_draw_path($ctx);
    }

    # Playhead
    my $px = $PAD + $phase * $pw;
    skia_set_color($ctx, 255, 255, 100, 180);
    skia_set_stroke($ctx, 1.5);
    skia_draw_line($ctx, $px, $PAD, $px, $PAD + $ph);

    # Dot
    my $val = $curves[$active_idx]{static}->($phase * $dur);
    my $py = $PAD + (1 - $val) * $ph;
    skia_set_color($ctx, 255, 255, 80, 255);
    skia_set_fill($ctx);
    skia_draw_circle($ctx, $px, $py, 5);

    # Legend boxes
    my $ly = $PAD + 8;
    for my $ci (0 .. $#curves) {
        my $c = $curves[$ci];
        skia_set_color($ctx, $c->{r}, $c->{g}, $c->{b}, $ci == $active_idx ? 255 : 120);
        skia_set_fill($ctx);
        skia_draw_rect($ctx, $PAD + 8, $ly, 12, 12);
        $ly += 18;
    }

    # Read pixels into buffer
    skia_get_pixels($ctx, $pixbuf_ptr, $rowstride);
}

my ($picture, $pixbuf, $texture);

my $app = Gtk4::Application->new('org.cpan.envelope.skia60', 'default-flags');

$app->signal_connect(activate => sub {
    my ($app) = @_;
    my $win = Gtk4::ApplicationWindow->new($app);
    $win->set_title('Envelope Viewer (Skia 60fps)');
    $win->set_default_size($W, $H);

    render_frame();
    $pixbuf = GdkPixbuf::Pixbuf->new_from_data(
        $pixbuf_buf, 'rgb', 0, 8, $W, $H, $rowstride);
    $texture = Gdk4::Texture->new_for_pixbuf($pixbuf);
    $picture = Gtk4::Picture->new_for_paintable($texture);
    $win->set_child($picture);

    my $last_switch = time();
    $picture->add_tick_callback(sub {
        if (time() - $last_switch > 4) {
            $active_idx = ($active_idx + 1) % @curves;
            $start_time = time();
            $last_switch = time();
        }
        render_frame();
        $pixbuf = GdkPixbuf::Pixbuf->new_from_data(
            $pixbuf_buf, 'rgb', 0, 8, $W, $H, $rowstride);
        $texture = Gdk4::Texture->new_for_pixbuf($pixbuf->copy);
        $picture->set_paintable($texture);
        return TRUE;
    });

    $win->present;
});

$app->run(\@ARGV);
skia_destroy($ctx);
