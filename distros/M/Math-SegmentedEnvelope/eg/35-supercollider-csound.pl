#!/usr/bin/env perl
# Export envelopes to SuperCollider and Csound formats
use strict;
use warnings;
use Math::SegmentedEnvelope qw(adsr perc asr spline);

my @envelopes = (
    ['ADSR note',  adsr(0.01, 0.1, 0.7, 0.3)],
    ['Percussive', perc(0.001, 0.2)],
    ['Pad',        asr(0.5, 2.0, 1.0, peak => 0.8)],
    ['Spline',     spline([0, 0.2, 0.5, 0.8, 1.0], [0, 0.9, 0.3, 0.8, 0],
                          resolution => 4)],
);

# SuperCollider output
print "// === SuperCollider ===\n";
print "(\n";
for my $pair (@envelopes) {
    my ($name, $e) = @$pair;
    (my $varname = lc $name) =~ s/\s+/_/g;
    printf "// %s (%.2fs, %d segments)\n", $name, $e->duration, $e->segments;
    print $e->to_supercollider(name => $varname);
}
print ")\n\n";

# SuperCollider SynthDef using the ADSR
print <<'SC';
// Usage in a SynthDef:
SynthDef(\envDemo, {
    var env = Env([0, 1, 0.7, 0.7, 0], [0.01, 0.1, 0.5, 0.3], [2, -2, 1, -2]);
    var amp = EnvGen.kr(env, doneAction: 2);
    var sig = SinOsc.ar(440) * amp;
    Out.ar(0, sig ! 2);
}).add;

SC

# Csound output
print ";; === Csound ===\n";
print ";; Use in a Csound orchestra instrument:\n\n";
for my $pair (@envelopes) {
    my ($name, $e) = @$pair;
    printf ";; %s (%.2fs)\n", $name, $e->duration;
    printf "k1 %s\n\n", $e->to_csound;
}

# Csound instrument example
print <<'CS';
;; Example instrument using generated envelope:
instr 1
  k1 linseg 0, 0.01, 1, 0.1, 0.7, 0.5, 0.7, 0.3, 0
  a1 oscili k1, 440, 1
  outs a1, a1
endin

;; Score:
f1 0 4096 10 1    ; sine wave
i1 0 1.0          ; play for 1 second
CS

# Show that derivative gives the slope envelope (useful for SC Env curves)
print "\n// === Derivative (slope) ===\n";
my $e = adsr(0.1, 0.1, 0.7, 0.3);
my $d = $e->derivative;
printf "// Original levels: %s\n", join(', ', map { sprintf '%.2f', $_ } @{$e->def->[0]});
printf "// Slope at each segment: %s\n", join(', ', map { sprintf '%.2f', $_ } @{$d->def->[0]}[0 .. $d->segments - 1]);
