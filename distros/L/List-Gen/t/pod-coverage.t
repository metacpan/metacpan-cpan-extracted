use strict;
use warnings;
use Test::More;

# Ensure a recent version of Test::Pod::Coverage
my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
    if $@;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
    if $@;

#plan skip_all => ' Fix pod';
plan tests => 2;
pod_coverage_ok('List::Gen', {also_private => [qr/^(?: [A-Z_]+|
    dwim|packager|generator|mutable_gen|isagen|tiegen|collect
    |DEBUG|VERSION|canglob|catch_done|clone|empty|\\|is_lvalue|alpha2num|num2alpha
    |arange|gather_stream|gather_multi_stream|filterS|gatherM|gatherMS|gatherS|grepS
    |iterateMS|iterateS|itrMS|itrS|iterateM|Grep|take_while|drop_while|take_until|drop_until
	|scan_stream|scanS|while_|until_|filter_|genzip|looks_like_number
)$/x]});
pod_coverage_ok('List::Gen::Haskell', {trustme => [qr/^[A-Z]|
    hs_replicate|map_|map|last|length|or|reverse
/x]});
