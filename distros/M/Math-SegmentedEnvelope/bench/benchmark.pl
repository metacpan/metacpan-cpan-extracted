#!/usr/bin/env perl
use strict;
use warnings;
use feature 'state';
use Benchmark qw(cmpthese timethese);
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch", "$FindBin::Bin";

use Math::SegmentedEnvelope;
use PurePerl;

print "=" x 60, "\n";
print "Math::SegmentedEnvelope Benchmark: XS vs Pure Perl\n";
print "=" x 60, "\n\n";

# Use same envelope definition for fair comparison
my $def = [
    [0, 1, 0.8, 0.7, 0],
    [0.1, 0.2, 0.4, 0.3],
    [1, 2, 1, -3]
];

my $xs = Math::SegmentedEnvelope->new($def);
my $pp = Math::SegmentedEnvelope::PurePerl->new($def);

print "Envelope: 4 segments, duration = ", $xs->duration, "\n\n";

# Verify both produce same results
print "Verification (should be ~equal):\n";
for my $t (0, 0.25, 0.5, 0.75, 1.0) {
    my $xs_val = $xs->at($t);
    my $pp_val = $pp->at($t);
    printf "  t=%.2f: XS=%.6f, PP=%.6f, diff=%.2e\n", $t, $xs_val, $pp_val, abs($xs_val - $pp_val);
}
print "\n";

# Reset state
$xs->clean;
$pp->clean;

print "-" x 60, "\n";
print "1. Object method at() - random access (1M calls)\n";
print "-" x 60, "\n";

cmpthese(1_000_000, {
    'XS at()' => sub { $xs->at(rand) },
    'PP at()' => sub { $pp->at(rand) },
});

print "\n";

# Reset state
$xs->clean;
$pp->clean;

print "-" x 60, "\n";
print "2. Object method at() - sequential access (100K calls)\n";
print "-" x 60, "\n";

cmpthese(100_000, {
    'XS at() seq' => sub {
        state $t = 0;
        $xs->at($t);
        $t += 0.00001;
        $t = 0 if $t > 1;
    },
    'PP at() seq' => sub {
        state $t = 0;
        $pp->at($t);
        $t += 0.00001;
        $t = 0 if $t > 1;
    },
});

print "\n";

print "-" x 60, "\n";
print "3. Static evaluator - random access (1M calls)\n";
print "-" x 60, "\n";

my $xs_static = $xs->static;
my $pp_static = $pp->static;

cmpthese(1_000_000, {
    'XS static()' => sub { $xs_static->(rand) },
    'PP static()' => sub { $pp_static->(rand) },
});

print "\n";

print "-" x 60, "\n";
print "4. Static evaluator - sequential access (100K calls)\n";
print "-" x 60, "\n";

# Get fresh static evaluators
$xs_static = $xs->static;
$pp_static = $pp->static;

cmpthese(100_000, {
    'XS static seq' => sub {
        state $t = 0;
        $xs_static->($t);
        $t += 0.00001;
        $t = 0 if $t > 1;
    },
    'PP static seq' => sub {
        state $t = 0;
        $pp_static->($t);
        $t += 0.00001;
        $t = 0 if $t > 1;
    },
});

print "\n";

print "-" x 60, "\n";
print "5. Table generation (1024 samples, 1000 iterations)\n";
print "-" x 60, "\n";

cmpthese(1000, {
    'XS table()' => sub { my @t = $xs->table(1024) },
    'PP table()' => sub { my @t = $pp->table(1024) },
});

print "\n";

print "-" x 60, "\n";
print "6. Object construction (10K iterations)\n";
print "-" x 60, "\n";

cmpthese(10_000, {
    'XS new()' => sub { Math::SegmentedEnvelope->new($def) },
    'PP new()' => sub { Math::SegmentedEnvelope::PurePerl->new($def) },
});

print "\n";

print "-" x 60, "\n";
print "7. With is_morph enabled - static (500K calls)\n";
print "-" x 60, "\n";

my $xs_morph = Math::SegmentedEnvelope->new($def, is_morph => 1);
my $pp_morph = Math::SegmentedEnvelope::PurePerl->new($def, is_morph => 1);
my $xs_morph_static = $xs_morph->static;
my $pp_morph_static = $pp_morph->static;

cmpthese(500_000, {
    'XS morph' => sub { $xs_morph_static->(rand) },
    'PP morph' => sub { $pp_morph_static->(rand) },
});

print "\n";
print "=" x 60, "\n";
print "Done!\n";
