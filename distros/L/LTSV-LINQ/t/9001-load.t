######################################################################
#
# 9001-load.t
#
# DESCRIPTION
#   1. LTSV::LINQ module load and interface
#   2. INA_CPAN_Check library load and export
#
# COMPATIBILITY
#   Perl 5.005_03 and later.  No non-core dependencies.
#
######################################################################

use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) {
        $INC{'warnings.pm'} = 'stub';
        eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";

my ($T_PLAN, $T_RUN, $T_FAIL) = (0, 0, 0);
sub plan_tests { $T_PLAN = $_[0]; print "1..$T_PLAN\n" }
sub ok {
    my ($ok, $name) = @_;
    $T_RUN++;
    $T_FAIL++ unless $ok;
    print +($ok ? '' : 'not ') . "ok $T_RUN" . ($name ? " - $name" : '') . "\n";
    return $ok;
}
sub diag { print "# $_[0]\n" }
END { exit 1 if $T_PLAN && $T_FAIL }

my @linq_methods = qw(
    new From FromLTSV Range Empty Repeat
    Where Select SelectMany Concat Zip
    Take Skip TakeWhile SkipWhile
    OrderBy OrderByDescending OrderByStr OrderByStrDescending
    OrderByNum OrderByNumDescending Reverse
    GroupBy Distinct Union Intersect Except
    Join GroupJoin
    Count Sum Min Max Average AverageOrDefault Aggregate
    ToArray ToList ToDictionary ToLookup ToLTSV
    DefaultIfEmpty ForEach
);
my @ordered_methods = qw(
    ThenBy ThenByDescending
    ThenByStr ThenByStrDescending
    ThenByNum ThenByNumDescending
);

my $total = 4
          + scalar(@linq_methods)
          + scalar(@ordered_methods)
          + 4;
plan_tests($total);

# Section 1: LTSV::LINQ
eval { require LTSV::LINQ };
ok(!$@, 'LTSV::LINQ loads without error');
diag("load error: $@") if $@;

ok(defined $LTSV::LINQ::VERSION,         'LTSV::LINQ: $VERSION defined');
ok($LTSV::LINQ::VERSION =~ /^\d+\.\d+/, 'LTSV::LINQ: $VERSION looks like a version number');
ok(defined $LTSV::LINQ::Ordered::{ThenBy}, 'LTSV::LINQ::Ordered package present');

for my $m (@linq_methods) {
    ok(LTSV::LINQ->can($m), "LTSV::LINQ->can('$m')");
}
for my $m (@ordered_methods) {
    ok(LTSV::LINQ::Ordered->can($m), "LTSV::LINQ::Ordered->can('$m')");
}

# Section 2: INA_CPAN_Check
eval { require INA_CPAN_Check };
ok(!$@, 'INA_CPAN_Check loads without error');
diag("load error: $@") if $@;

ok( defined &INA_CPAN_Check::ok
 && defined &INA_CPAN_Check::plan_tests
 && defined &INA_CPAN_Check::_slurp
 && defined &INA_CPAN_Check::_scan_code,
   'INA_CPAN_Check: key helpers defined');

ok( defined &INA_CPAN_Check::check_A && defined &INA_CPAN_Check::check_K,
   'INA_CPAN_Check: check_A through check_K defined');

ok( defined &INA_CPAN_Check::count_A && defined &INA_CPAN_Check::count_K,
   'INA_CPAN_Check: count_A through count_K defined');
