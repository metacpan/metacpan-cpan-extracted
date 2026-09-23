#!/usr/bin/env perl
# Morpher comparison: predefined, formula, callback
use strict;
use warnings;
use Math::SegmentedEnvelope qw(env morpher_formulas);

# List all predefined morphers
my @names = morpher_formulas();
printf "Predefined morphers (%d): %s\n\n", scalar @names, join(', ', @names);

# Compare morpher shapes on a simple 0->1 ramp
my $def = [[0, 1], [1], [1]];

# No morph (linear)
my $linear = env($def);

print "t      linear";
for my $name (@names) {
    printf "  %12s", $name;
}
print "\n";

for my $ti (0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0) {
    printf "%.1f    %6.4f", $ti, $linear->at($ti);
    for my $name (@names) {
        my $e = env($def, morpher_formula => $name);
        printf "  %12.4f", $e->at($ti);
    }
    print "\n";
}

# Custom formula morphers
print "\nCustom formula morphers:\n";
my @formulas = (
    't * t',                        # quadratic ease-in
    '1 - (1-t)*(1-t)',             # quadratic ease-out
    't * t * t',                    # cubic ease-in
    'sin(t * 1.5708)',             # sine quarter
    'sin(t * 1.5708) ^ 2',        # sine squared (default)
    '1 - cos(t * 1.5708)',        # cosine ease
);

for my $f (@formulas) {
    my $e = env($def, morpher_formula => $f);
    printf "  %-30s [%s]  at(0.5)=%.4f\n",
        $f, $e->morpher_jit_backend, $e->at(0.5);
}

# Perl callback morpher (slowest but most flexible)
my $e_cb = env($def,
    is_morph => 1,
    morpher => sub {
        my $t = shift;
        # Custom: fast start, slow middle, fast end
        return $t < 0.5
            ? 4 * $t * $t * $t
            : 1 - (-2 * $t + 2) ** 3 / 2;
    },
);
printf "\nPerl callback:  at(0.25)=%.4f  at(0.5)=%.4f  at(0.75)=%.4f\n",
    $e_cb->at(0.25), $e_cb->at(0.5), $e_cb->at(0.75);
