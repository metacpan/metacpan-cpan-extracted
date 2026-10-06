use strict;
use warnings;
use Test::More;

# Phase-00 guardrail: sv_catpvf is banned in Simple.xs.
# It is at least 20x slower than sv_catpvn for the same byte work
# (printf format parsing every call) and was the single biggest
# scalar hot spot in the legacy parser. If a future change reintroduces
# it the suite must fail.

my $xs = 'Simple.xs';
# The XS is shipped in the MANIFEST, so a missing file is a packaging bug,
# not a reason to pass: skipping here is how this guardrail would go green
# the day the file moves again.
BAIL_OUT("$xs not found") unless -f $xs;

open my $fh, '<', $xs or die "open $xs: $!";
my @offenders;
while (my $line = <$fh>) {
    next if $line =~ /^\s*\*/;       # skip C block-comment body
    next if $line =~ m{^\s*//};      # skip C++ line comment
    push @offenders, "$.: $line" if $line =~ /\bsv_catpvf\b/;
}
close $fh;

is(scalar @offenders, 0, 'no sv_catpvf calls in Simple.xs')
    or diag join('', @offenders);

done_testing;
