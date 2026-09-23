#!/usr/bin/env perl
use strict;
use warnings;
use Math::SegmentedEnvelope;

# ============================================================================
# Industrial PID Controller Tuning & Step Response Analysis
# ============================================================================
# In process automation and motion control (e.g. robotic joints, temperature
# chambers, quadcopter flight stabilization), control engineers tune PID
# (Proportional-Integral-Derivative) parameters to achieve fast setpoint
# tracking while avoiding destabilizing overshoot or oscillatory ringing.
#
# This example demonstrates:
#   1. Modeling closed-loop unit step responses for 4 canonical tuning regimes:
#      - Overdamped (conservative/sluggish, zero overshoot)
#      - Critically Damped (fastest rise without overshoot)
#      - Underdamped / Moderate (Ziegler-Nichols balanced, ~10% overshoot)
#      - Highly Oscillatory / Under-damped (aggressive gains, ringing)
#   2. Utilizing morpher formulas: 'exp_out', 'smoothstep', 'back_out', 'elastic_out'
#   3. Deriving process slew rate dy/dt and error derivative de/dt using derivative()
#   4. Calculating key control engineering performance metrics:
#      - Rise Time (Tr: 10% -> 90% of setpoint)
#      - Peak Time (Tp) and Peak Overshoot (Mp %)
#      - Settling Time (Ts: within +/- 2% error band)
#      - Slew Rate max |dy/dt|
#   5. Generating an ASCII step response transient chart.
# ============================================================================

my $setpoint = 1.0;
my $duration = 2.5; # seconds

# 1. Define Step Response Profiles using different morphers
my %controllers = (
    overdamped => {
        label   => 'Overdamped (Low Kp/Ki)',
        morpher => 'exp_out',
        desc    => 'Sluggish approach, zero overshoot, safe for chemical reactors',
    },
    critical => {
        label   => 'Critically Damped',
        morpher => 'smoothstep',
        desc    => 'Fastest monotonic rise, zero overshoot, ideal for CNC position',
    },
    underdamped => {
        label   => 'Underdamped (Balanced PID)',
        morpher => 'back_out',
        desc    => 'Fast rise with moderate ~10% overshoot, rapid settling',
    },
    oscillatory => {
        label   => 'Under-damped (Aggressive)',
        morpher => 'elastic_out',
        desc    => 'Excessive proportional gain, high overshoot and ringing',
    },
);

my @keys = qw(overdamped critical underdamped oscillatory);

# Build envelopes and derivatives
my %envs;
my %derivs;

for my $k (@keys) {
    my $e = Math::SegmentedEnvelope->new(
        [[0.0, $setpoint], [$duration], [1]],
        is_morph        => 1,
        morpher_formula => $controllers{$k}{morpher},
        is_hold         => 1,
    );
    $envs{$k}   = $e;
    # Resample before taking derivative to capture continuous morpher dynamics
    $derivs{$k} = $e->resample(50)->derivative;
}

# 2. Analyze Step Response Metrics
print "=" x 76, "\n";
print "  Industrial Control Systems: PID Step Response & Slew Rate Analysis\n";
print "=" x 76, "\n";
print "Setpoint Target: $setpoint.00 | Step Time: t=0.0s | Evaluation Horizon: ${duration}s\n";
print "-" x 76, "\n";

printf "%-26s | %-8s | %-8s | %-8s | %-8s | %-8s\n",
    "Tuning Regime", "Rise Tr", "Peak Tp", "Overshoot", "Settle Ts", "Max dy/dt";
print "-" x 76, "\n";

my %metrics;
for my $k (@keys) {
    my $e = $envs{$k};
    my $d = $derivs{$k};

    my $t_10;
    my $t_90;
    my $peak_val = 0;
    my $peak_t   = 0;
    my $settle_t = $duration;
    my $max_slew = 0;

    my $dt = 0.005;
    for (my $t = 0; $t <= $duration; $t += $dt) {
        my $y  = $e->at($t);
        my $dy = abs($d->at($t));

        $max_slew = $dy if $dy > $max_slew;

        # 10% and 90% rise crossings
        $t_10 = $t if !defined $t_10 && $y >= 0.10 * $setpoint;
        $t_90 = $t if !defined $t_90 && $y >= 0.90 * $setpoint;

        # Peak detection
        if ($y > $peak_val) {
            $peak_val = $y;
            $peak_t   = $t;
        }

        # Settling time (within +/- 2% of setpoint = [0.98, 1.02])
        if (abs($y - $setpoint) > 0.02 * $setpoint) {
            $settle_t = $t + $dt;
        }
    }

    my $rise_time = (defined $t_90 && defined $t_10) ? ($t_90 - $t_10) : $duration;
    my $overshoot_pct = ($peak_val > $setpoint) ? (($peak_val - $setpoint) / $setpoint * 100) : 0.0;
    $settle_t = $duration if $settle_t > $duration;

    $metrics{$k} = {
        rise_time => $rise_time,
        peak_t    => $peak_t,
        overshoot => $overshoot_pct,
        settle_t  => $settle_t,
        max_slew  => $max_slew,
    };

    printf "%-26s | %6.2fs  | %6.2fs  | %6.1f%%   | %6.2fs  | %6.2f/s\n",
        $controllers{$k}{label},
        $rise_time,
        $peak_t,
        $overshoot_pct,
        $settle_t,
        $max_slew;
}
print "-" x 76, "\n";

# 3. ASCII Step Response Chart
print "\nTransient Step Response y(t) [0.0s to 2.4s]:\n";
print "Symbols: [O] Overdamped  [C] Critical  [U] Underdamped  [X] Oscillatory  [*] Target\n";
print "Time   | Overdamp | Critical | Underdmp | Oscillat | Step Response [0.0 to 1.2]\n";
print "-" x 76, "\n";

my $chart_width = 32;
for (my $t = 0.0; $t <= 2.4; $t += 0.12) {
    my $yo = $envs{overdamped}->at($t);
    my $yc = $envs{critical}->at($t);
    my $yu = $envs{underdamped}->at($t);
    my $yx = $envs{oscillatory}->at($t);

    my @row = (' ') x $chart_width;
    
    # Mark target line at 1.0 (pos = 1.0 / 1.2 * width)
    my $target_pos = int(1.0 / 1.2 * ($chart_width - 1));
    $row[$target_pos] = '|';

    my sub plot_pt {
        my ($val, $sym) = @_;
        my $pos = int($val / 1.2 * ($chart_width - 1));
        $pos = 0 if $pos < 0;
        $pos = $chart_width - 1 if $pos >= $chart_width;
        $row[$pos] = $sym;
    }

    plot_pt($yo, 'O');
    plot_pt($yc, 'C');
    plot_pt($yu, 'U');
    plot_pt($yx, 'X');

    my $graph = join('', @row);
    printf "%4.2fs  | %7.3f  | %7.3f  | %7.3f  | %7.3f  | [%s]\n",
        $t, $yo, $yc, $yu, $yx, $graph;
}
print "=" x 76, "\n";
print "Summary: Morphers provide analytical step response trajectories,\n";
print "while derivative() computes control action slew rate de/dt.\n";
print "=" x 76, "\n";
