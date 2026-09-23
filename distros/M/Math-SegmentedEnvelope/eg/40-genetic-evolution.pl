#!/usr/bin/env perl
# Genetic envelope evolution: breed envelopes toward a target shape
# Uses lerp, map_levels, and from_samples for mutation/crossover
use strict;
use warnings;
use Math::SegmentedEnvelope qw(adsr perc env spline);

srand(42);

my $width  = 60;
my $height = 10;
my $pop_size = 12;
my $generations = 30;
my $mutation_rate = 0.15;
my $samples = 32;

# Target: a complex shape that's hard to guess
my $target = spline(
    [0, 0.15, 0.3, 0.5, 0.7, 0.85, 1.0],
    [0, 0.9,  0.2, 0.8, 0.3, 0.7,  0],
    resolution => 4,
);
my @target_vals = $target->table($samples);

# Fitness: negative mean squared error (higher = better)
sub fitness {
    my ($e) = @_;
    my @vals = $e->table($samples);
    my $mse = 0;
    for my $i (0 .. $#vals) {
        my $d = $vals[$i] - $target_vals[$i];
        $mse += $d * $d;
    }
    return -$mse / @vals;
}

# Mutation: randomly perturb levels
sub mutate {
    my ($e) = @_;
    $e->map_levels(sub {
        my $v = $_[0];
        if (rand() < $mutation_rate) {
            $v += (rand() - 0.5) * 0.3;
            $v = 0 if $v < 0;
            $v = 1 if $v > 1;
        }
        $v;
    });
}

# Crossover: lerp between two parents
sub crossover {
    my ($a, $b) = @_;
    if ($a->segments == $b->segments) {
        return $a->lerp($b, 0.3 + rand() * 0.4);
    }
    return $a->blend($b, 0.3 + rand() * 0.4, segments => $a->segments);
}

# Initial random population
my @pop;
for (1 .. $pop_size) {
    my @vals = map { rand() } 0 .. $samples;
    push @pop, Math::SegmentedEnvelope->from_samples(\@vals, $target->duration);
}

# Print target
print "Target:\n";
plot($target);

# Evolution loop
for my $gen (0 .. $generations - 1) {
    # Evaluate fitness
    my @scored = sort { $b->[1] <=> $a->[1] }
                 map { [$_, fitness($_)] } @pop;

    if ($gen % 5 == 0 || $gen == $generations - 1) {
        printf "\nGen %2d  best_fit=%.4f  worst_fit=%.4f\n",
            $gen, $scored[0][1], $scored[-1][1];
        plot($scored[0][0]);
    }

    # Selection: keep top half
    my @parents = map { $_->[0] } @scored[0 .. $pop_size/2 - 1];

    # Breed next generation
    @pop = @parents;
    while (@pop < $pop_size) {
        my $a = $parents[int(rand(@parents))];
        my $b = $parents[int(rand(@parents))];
        my $child = crossover($a, $b);
        $child = mutate($child);
        push @pop, $child;
    }
}

# Final comparison
my @final_scored = sort { $b->[1] <=> $a->[1] }
                   map { [$_, fitness($_)] } @pop;
my $best = $final_scored[0][0];

print "\nFinal best vs target:\n";
my @bv = $best->table($width);
my @tv = $target->table($width);
for my $y (reverse 0 .. $height - 1) {
    my $level = $y / ($height - 1);
    for my $x (0 .. $width - 1) {
        my $ib = int($bv[$x] * ($height - 1) + 0.5) == $y;
        my $it = int($tv[$x] * ($height - 1) + 0.5) == $y;
        if ($ib && $it) { print '@' }
        elsif ($it)     { print '.' }
        elsif ($ib)     { print '*' }
        else            { print ' ' }
    }
    print "\n";
}
print "  . = target  * = evolved  @ = overlap\n";

sub plot {
    my ($e) = @_;
    my @vals = $e->table($width);
    my ($min, $max) = (0, 1);
    for my $y (reverse 0 .. $height - 1) {
        my $level = $y / ($height - 1);
        print '  ';
        for my $x (0 .. $width - 1) {
            my $vy = int($vals[$x] * ($height - 1) + 0.5);
            print $vy == $y ? '*' : ' ';
        }
        print "\n";
    }
}
