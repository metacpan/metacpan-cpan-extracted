#!/usr/bin/env perl
# Serialization: save/load envelopes via to_hash/from_hash
use strict;
use warnings;
use Math::SegmentedEnvelope qw(adsr);

# JSON round-trip (if JSON module available)
my $has_json = eval { require JSON; 1 };

my $e = adsr(0.05, 0.1, 0.7, 0.3,
    is_hold => 1,
    morpher_formula => 'smoothstep',
);

# Serialize to hash
my $h = $e->to_hash;

printf "Serialized hash keys: %s\n", join(', ', sort keys %$h);
printf "  is_morph:         %d\n", $h->{is_morph};
printf "  is_hold:          %d\n", $h->{is_hold};
printf "  morpher_formula:  %s\n", $h->{morpher_formula} // 'undef';
printf "  segments:         %d\n", scalar @{$h->{def}[1]};

# Reconstruct
my $e2 = Math::SegmentedEnvelope->from_hash($h);

# Verify round-trip
my $ok = 1;
for my $t (0, 0.1, 0.2, 0.3, 0.5, 0.8) {
    my $diff = abs($e->at($t) - $e2->at($t));
    if ($diff > 0.0001) {
        printf "MISMATCH at t=%.1f: %.6f vs %.6f\n", $t, $e->at($t), $e2->at($t);
        $ok = 0;
    }
}
printf "Round-trip: %s\n", $ok ? 'PASS' : 'FAIL';

# JSON serialization
if ($has_json) {
    my $json = JSON::encode_json($h);
    printf "\nJSON (%d bytes): %.60s...\n", length($json), $json;

    my $h2 = JSON::decode_json($json);
    my $e3 = Math::SegmentedEnvelope->from_hash($h2);
    printf "JSON round-trip at(0.3): %.6f (original: %.6f)\n",
        $e3->at(0.3), $e->at(0.3);
} else {
    print "\n(Install JSON module for JSON serialization demo)\n";
}
