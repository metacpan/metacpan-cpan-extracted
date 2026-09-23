#!/usr/bin/env perl
# MIDI CC automation: envelope-driven synth parameter modulation
#
# Plays a chord with envelope-modulated volume, filter cutoff, and modulation.
# For audio output, start fluidsynth separately first:
#   fluidsynth -a alsa -m alsa_seq /usr/share/sounds/sf2/FluidR3_GM.sf2 &
# Then run this script -- it will auto-connect to fluidsynth.
#
# Requires: MIDI::RtMidi::FFI::Device
use strict;
use warnings;

BEGIN {
    eval { require MIDI::RtMidi::FFI::Device; MIDI::RtMidi::FFI::Device->import; 1 }
        or die "This example requires MIDI::RtMidi::FFI::Device\n";
}

use Math::SegmentedEnvelope qw(adsr env);
use Time::HiRes qw(time sleep);

# Find soundfont
my @sf_paths = (
    '/usr/share/sounds/sf2/FluidR3_GM.sf2',
    '/usr/share/sounds/sf2/FluidR3_GS.sf2',
    '/usr/share/soundfonts/default.sf2',
);
my ($sf2) = grep { -f $_ } @sf_paths;
die "No soundfont found\n" unless $sf2;

# Launch fluidsynth
printf "Starting fluidsynth with %s...\n", $sf2;
open my $fs, '|-', 'fluidsynth', '-a', 'alsa', '-m', 'alsa_seq',
     '-q', '-i', $sf2
    or die "Cannot start fluidsynth: $!\n";

sleep(1);

# Find fluidsynth's ALSA port
my $fs_port;
my $dev = MIDI::RtMidi::FFI::Device->new(type => 'output');
my $n = $dev->get_port_count;
printf "MIDI ports (%d):\n", $n;
for my $i (0 .. $n - 1) {
    my $name = $dev->get_port_name($i);
    printf "  %d: %s\n", $i, $name;
    $fs_port = $i if $name =~ /fluid|synth/i;
}

# Fall back: open virtual port and use aconnect
unless (defined $fs_port) {
    printf "No fluidsynth port found via RtMidi, trying aconnect...\n";
    $dev->open_virtual_port('EnvelopeCC');

    # Find fluidsynth via aconnect
    my @aconn = `aconnect -o 2>/dev/null`;
    my $fs_client;
    for (@aconn) {
        if (/client\s+(\d+).*fluid/i) {
            $fs_client = $1;
            last;
        }
    }

    if ($fs_client) {
        # Find our virtual port
        my @aconn_i = `aconnect -i 2>/dev/null`;
        my $our_client;
        for (@aconn_i) {
            if (/client\s+(\d+).*EnvelopeCC/i) {
                $our_client = $1;
                last;
            }
        }
        if ($our_client) {
            system("aconnect $our_client:0 $fs_client:0 2>/dev/null");
            printf "Connected via aconnect: %d -> %d\n", $our_client, $fs_client;
        }
    } else {
        warn "Could not find fluidsynth port. Playing blind (no audio).\n";
    }
} else {
    $dev->open_port($fs_port);
    printf "Connected to port %d\n", $fs_port;
}

my $ch = 0;

# Select a warm pad sound (program 89 = Pad 2 Warm)
$dev->send_message(pack "C*",0xC0 | $ch, 89);

# CC envelopes
my $volume = adsr(0.05, 0.2, 0.7, 1.5,
    peak => 1.0, morpher_formula => 'smoothstep');
my $cutoff = adsr(0.01, 0.5, 0.3, 0.8,
    peak => 1.0, attack_curve => 3, decay_curve => -3,
    morpher_formula => 'cubic_out');
my $mod = env(
    [[0, 0.6, 0, 0.6, 0], [0.3, 0.3, 0.3, 0.3], [2, -2, 2, -2]],
    morpher_formula => 'smoothstep',
    is_fold_over => 1,
);

my @ccs = (
    { cc =>  7, name => 'Vol',    env => $volume },
    { cc => 74, name => 'Cutoff', env => $cutoff },
    { cc =>  1, name => 'Mod',    env => $mod },
);
$_->{static} = $_->{env}->static for @ccs;

# Play chord: Am7 (A2, C3, E3, G3)
my @notes = (45, 48, 52, 55);
for my $note (@notes) {
    $dev->send_message(pack "C*",0x90 | $ch, $note, 80);
}
printf "Notes ON: %s\n\n", join(', ', @notes);

# Animate CCs
my $dur = $volume->duration;
my $rate = 60;
my $t0 = time();
my $last_print = -1;

while (1) {
    my $t = time() - $t0;
    last if $t > $dur;

    for my $c (@ccs) {
        my $val = $c->{static}->($t);
        my $midi = int($val * 127 + 0.5);
        $midi = 0   if $midi < 0;
        $midi = 127 if $midi > 127;
        $dev->send_message(pack "C*",0xB0 | $ch, $c->{cc}, $midi);
    }

    if (int($t * 10) > $last_print) {
        $last_print = int($t * 10);
        printf "t=%5.2f", $t;
        for my $c (@ccs) {
            printf "  %s=%3d", $c->{name}, int($c->{static}->($t) * 127 + 0.5);
        }
        print "\n";
    }

    my $next = $t0 + (int($t * $rate) + 1) / $rate;
    my $wait = $next - time();
    sleep($wait) if $wait > 0;
}

# Cleanup
for my $note (@notes) {
    $dev->send_message(pack "C*",0x80 | $ch, $note, 0);
}
for my $c (@ccs) {
    $dev->send_message(pack "C*",0xB0 | $ch, $c->{cc}, 0);
}
print "\nNotes OFF. Done.\n";
close $fs;
