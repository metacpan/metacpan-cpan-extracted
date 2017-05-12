use strict;
use warnings;

use Test::Pod::Coverage tests => 7;

my @modules_to_be_tested = qw(
    Lingua::Diversity
    Lingua::Diversity::Result
    Lingua::Diversity::Internals
    Lingua::Diversity::Utils
    Lingua::Diversity::Variety
    Lingua::Diversity::MTLD
    Lingua::Diversity::VOCD
);

foreach my $module ( @modules_to_be_tested ) {
    pod_coverage_ok(
        $module,
        { also_private => [ qr/^[A-Z_]+$/ ], },
        "$module is covered"
    );
}
