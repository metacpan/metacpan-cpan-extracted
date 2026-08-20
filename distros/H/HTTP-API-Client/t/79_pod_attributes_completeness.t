=head1 NAME

79_pod_attributes_completeness.t - HAC-101: two public rw constructor
attributes ('retry' and 'debug_flags') had no matching entry in the POD
ATTRIBUTES section - the same gap class HAC-052 already fixed for
retry_config/json, which somehow recurred for these two without any test
catching it. This test parses the actual 'has NAME => (...)' declarations
out of the module source and cross-checks each one against the POD
ATTRIBUTES section's '=item NAME' entries, so a future attribute added
without a matching POD entry fails the suite instead of silently shipping
undocumented.

=cut

use strict;
use warnings;
use FindBin;
use Test::More;

my $pm_path = "$FindBin::Bin/../lib/HTTP/API/Client.pm";
open my $fh, "<", $pm_path or die "can't open $pm_path: $!";
my $source = do { local $/; <$fh> };
close $fh;

my @declared = $source =~ /^has\s+(\w+)\s*=>/mg;

my ($pod_attributes) = $source =~ /^=head1 ATTRIBUTES\n(.*?)^=head1 /ms;
ok $pod_attributes, "found the ATTRIBUTES POD section";

my @documented_items = $pod_attributes =~ /^=item\s+(.+)$/mg;

my %documented;
for my $item (@documented_items) {
    $documented{$_} = 1 for split m{\s*/\s*}, $item;
}

for my $attr (sort @declared) {
    ok $documented{$attr}, "attribute '$attr' has a matching POD =item entry in ATTRIBUTES";
}

done_testing;
