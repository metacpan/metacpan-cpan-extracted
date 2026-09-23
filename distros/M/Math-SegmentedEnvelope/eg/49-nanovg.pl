#!/usr/bin/env perl
# NanoVG rendering via GLUT: 60fps envelope animation with anti-aliased vector graphics
#
# Build helper first:
#   cd eg && cc -shared -fPIC -O2 -o libnanovg_helper.so nanovg_helper.c -lGL -lglut -lGLEW -lm
#
# Requires: FFI::Platypus, OpenGL, GLUT, GLEW, nanovg headers
use strict;
use warnings;

BEGIN {
    eval { require FFI::Platypus; 1 }
        or die "This example requires FFI::Platypus\n";
}

use FindBin;
use FFI::Platypus;
use FFI::Platypus::Buffer qw(scalar_to_pointer);
use Math::SegmentedEnvelope qw(adsr perc spline env);
use Time::HiRes qw(time);

my $W = 800;
my $H = 450;

my $lib = "$FindBin::Bin/libnanovg_helper.so";
die "Build helper first: cd eg && cc -shared -fPIC -O2 -o libnanovg_helper.so nanovg_helper.c -lGL -lglut -lGLEW -lm\n"
    unless -f $lib;

my $ffi = FFI::Platypus->new(api => 2, lib => [$lib]);
$ffi->type('opaque' => 'NVGctx');

$ffi->attach(nvg_init           => ['int', 'int'] => 'void');
$ffi->attach(nvg_set_curves     => ['int'] => 'void');
$ffi->attach(nvg_set_curve_data => ['int', 'float[]', 'int', 'uint8', 'uint8', 'uint8', 'int'] => 'void');
$ffi->attach(nvg_set_playhead   => ['float', 'float'] => 'void');
$ffi->attach(nvg_set_tick_callback => ['(void)->void'] => 'void');
$ffi->attach(nvg_main_loop      => [] => 'void');
$ffi->attach(nvg_cleanup        => [] => 'void');

# Envelopes
my @curves = (
    { env => adsr(0.1, 0.15, 0.7, 0.3, morpher_formula => 'smoothstep'),
      r => 60, g => 140, b => 255, label => 'ADSR' },
    { env => perc(0.01, 0.5, morpher_formula => 'cubic_out'),
      r => 255, g => 90, b => 60, label => 'Perc' },
    { env => spline([0, 0.2, 0.5, 0.8, 1.0], [0, 0.9, 0.2, 0.8, 0]),
      r => 60, g => 210, b => 90, label => 'Spline' },
    { env => env([[0, 1], [1], [1]], morpher_formula => 'bounce_out'),
      r => 210, g => 90, b => 240, label => 'Bounce' },
);

my $samples = $W - 80;
for my $c (@curves) {
    $c->{vals} = [$c->{env}->table($samples)];
    $c->{static} = $c->{env}->static;
}

my $active_idx = 0;
my $start_time = time();
my $last_switch = time();

# Initialize NanoVG + GLUT
nvg_init($W, $H);

# Upload curve data
nvg_set_curves(scalar @curves);
for my $ci (0 .. $#curves) {
    my $c = $curves[$ci];
    nvg_set_curve_data($ci, $c->{vals}, scalar @{$c->{vals}},
                       $c->{r}, $c->{g}, $c->{b}, $ci == $active_idx ? 1 : 0);
}

# Tick callback: update playhead + cycle envelopes
my $tick = $ffi->closure(sub {
    my $t = time();

    if ($t - $last_switch > 4) {
        $active_idx = ($active_idx + 1) % @curves;
        $start_time = $t;
        $last_switch = $t;
        for my $ci (0 .. $#curves) {
            my $c = $curves[$ci];
            nvg_set_curve_data($ci, $c->{vals}, scalar @{$c->{vals}},
                               $c->{r}, $c->{g}, $c->{b}, $ci == $active_idx ? 1 : 0);
        }
    }

    my $dur = $curves[$active_idx]{env}->duration;
    my $phase = ($t - $start_time) / $dur;
    $phase -= int($phase);
    my $val = $curves[$active_idx]{static}->($phase * $dur);
    nvg_set_playhead($phase, $val);
});

nvg_set_tick_callback($tick);

print "Starting NanoVG render loop (close window or Ctrl+C to quit)...\n";
nvg_main_loop();
nvg_cleanup();
