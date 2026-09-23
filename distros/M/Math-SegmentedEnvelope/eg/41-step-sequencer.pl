#!/usr/bin/env perl
# Step sequencer: 8-step pattern with per-step envelopes, scrolling piano-roll
use strict;
use warnings;
use Math::SegmentedEnvelope qw(perc adsr env);
use Time::HiRes qw(time sleep);

$| = 1;

my $bpm = 140;
my $step_dur = 60 / $bpm / 2;  # 8th notes
my $steps = 8;
my $loops = 4;

# Each step: pitch (MIDI note), velocity, envelope shape
my @pattern = (
    { note => 36, vel => 1.0,  env => perc(0.005, $step_dur * 0.9) },  # kick
    { note =>  0, vel => 0,    env => undef },                          # rest
    { note => 38, vel => 0.7,  env => perc(0.002, $step_dur * 0.6) },  # snare
    { note =>  0, vel => 0,    env => undef },                          # rest
    { note => 36, vel => 0.9,  env => perc(0.005, $step_dur * 0.9) },  # kick
    { note => 42, vel => 0.5,  env => perc(0.001, $step_dur * 0.3) },  # hihat
    { note => 38, vel => 0.8,  env => perc(0.002, $step_dur * 0.7) },  # snare
    { note => 42, vel => 0.4,  env => perc(0.001, $step_dur * 0.3) },  # hihat
);

# Prepare static evaluators
for my $s (@pattern) {
    $s->{static} = $s->{env} ? $s->{env}->static : undef;
}

my $roll_width = 60;
my $roll_height = 8;
my $history_len = $roll_width;

# History buffer: each column is a time slice, each row is a step
my @history;

my $note_names = {36 => 'KCK', 38 => 'SNR', 42 => 'HHT', 0 => '---'};

print "\e[2J";  # clear

my $t0 = time();
my $total_steps = $steps * $loops;
my $display_rate = 20;  # Hz

for my $global_step (0 .. $total_steps - 1) {
    my $step_idx = $global_step % $steps;
    my $step_start = $global_step * $step_dur;

    # Animate within this step
    my $substeps = int($step_dur * $display_rate);
    $substeps = 1 if $substeps < 1;

    for my $sub (0 .. $substeps - 1) {
        my $t = $step_start + $sub * $step_dur / $substeps;
        my $sub_t = $sub * $step_dur / $substeps;

        # Sample all active envelopes at this sub-step
        my @col;
        for my $i (0 .. $steps - 1) {
            my $s = $pattern[$i];
            if ($i == $step_idx && $s->{static}) {
                push @col, $s->{static}->($sub_t) * $s->{vel};
            } elsif ($i == $step_idx && !$s->{env}) {
                push @col, 0;
            } else {
                # Check if this step is still ringing from a previous trigger
                my $steps_ago = ($step_idx - $i) % $steps;
                if ($steps_ago > 0 && $s->{static}) {
                    my $elapsed = $steps_ago * $step_dur + $sub_t;
                    my $v = ($elapsed < $s->{env}->duration) ? $s->{static}->($elapsed) * $s->{vel} : 0;
                    push @col, $v;
                } else {
                    push @col, 0;
                }
            }
        }

        push @history, \@col;
        shift @history if @history > $history_len;

        # Render
        print "\e[H";  # cursor home
        printf " Step Sequencer  %d BPM  step %d/%d  loop %d/%d\n\n",
            $bpm, $step_idx + 1, $steps, int($global_step / $steps) + 1, $loops;

        # Step indicator bar
        print ' ';
        for my $i (0 .. $steps - 1) {
            printf " %s", $i == $step_idx ? '[>>]' : ' -- ';
        }
        print "\n";

        # Piano roll: rows = steps, columns = time
        for my $row (0 .. $steps - 1) {
            my $s = $pattern[$row];
            printf " %s |", $note_names->{$s->{note}} // sprintf('%3d', $s->{note});
            for my $col_idx (0 .. $#history) {
                my $v = $history[$col_idx][$row] // 0;
                if ($v > 0.7)    { print '#' }
                elsif ($v > 0.3) { print '*' }
                elsif ($v > 0.1) { print '.' }
                else             { print ' ' }
            }
            # Pad remaining
            print ' ' x ($history_len - @history) if @history < $history_len;
            print "|\n";
        }
        printf "     +%s+\n", '-' x $history_len;

        # Mix meter
        my $mix = 0;
        for my $v (@col) { $mix += $v }
        $mix /= @col;
        my $bar = int($mix * 40);
        printf " MIX |%-40s| %.2f\n", '#' x $bar, $mix;

        # Frame timing
        my $target_t = $t0 + $t + $step_dur / $substeps;
        my $wait = $target_t - time();
        sleep($wait) if $wait > 0;
    }
}

print "\e[", $steps + 8, "H\n";
