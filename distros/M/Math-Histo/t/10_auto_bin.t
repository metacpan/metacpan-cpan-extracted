use strict;
use warnings;
use Test::More;
use Math::Histo;
use Math::Histo::Constants qw(:bin_rules);

my @samples = map { sin($_ * 0.1) * ($_ % 5) } (1..300);

my $h_auto = Math::Histo->create_auto(\@samples, rule => 'auto');
ok(defined $h_auto, "create_auto returned histogram");
cmp_ok($h_auto->nbins, '>=', 3, "reasonable auto nbins");
is($h_auto->num_entries, 300, "all 300 entries filled");

my ($nbins, $min, $max) = Math::Histo->estimate_bins(\@samples, 'fd');
cmp_ok($nbins, '>=', 3, "estimate_bins fd nbins >= 3");
cmp_ok($max, '>', $min, "max > min");

for my $rule (qw(fd scott sturges doane knuth)) {
    my $h = Math::Histo->create_auto(\@samples, rule => $rule);
    ok(defined $h, "create_auto with rule $rule");
    cmp_ok($h->nbins, '>=', 1, "rule $rule has >= 1 bin");
}

done_testing();
