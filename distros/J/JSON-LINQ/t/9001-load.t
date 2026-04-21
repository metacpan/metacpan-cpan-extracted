######################################################################
#
# 9001-load.t
#
# DESCRIPTION
#   1. JSON::LINQ module load and interface
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
    new From FromJSON FromJSONL FromJSONString Range Empty Repeat
    Where Select SelectMany Concat Zip
    Take Skip TakeWhile SkipWhile
    OrderBy OrderByDescending OrderByStr OrderByStrDescending
    OrderByNum OrderByNumDescending Reverse
    GroupBy
    Distinct Union Intersect Except
    Join GroupJoin
    All Any Contains SequenceEqual
    First FirstOrDefault Last LastOrDefault
    Single SingleOrDefault ElementAt ElementAtOrDefault
    Count Sum Min Max Average AverageOrDefault Aggregate
    ToArray ToList ToDictionary ToLookup ToJSON ToJSONL DefaultIfEmpty
    ForEach
    true false
);

my @ordered_methods = qw(
    ThenBy ThenByDescending ThenByStr ThenByStrDescending ThenByNum ThenByNumDescending
);

my @check_subs = qw(
    plan_tests plan_skip ok diag end_testing
    _slurp _slurp_lines _find_pm
    _manifest_files _manifest_pm_and_t
    _pm_version _yaml_str _json_str
    _provides_versions_yml _provides_versions_json
    _scan_code
    check_A count_A  check_B count_B  check_C count_C
    check_D count_D  check_E count_E  check_F count_F
    check_G count_G  check_H count_H  check_I count_I
    check_J count_J  check_K count_K
);

plan_tests(4 + scalar(@linq_methods) + scalar(@ordered_methods) + scalar(@check_subs));

######################################################################
# 1. Load JSON::LINQ
######################################################################

eval { require JSON::LINQ };
ok(!$@, 'JSON::LINQ loads without error');

######################################################################
# 2. VERSION
######################################################################

ok(defined($JSON::LINQ::VERSION), 'JSON::LINQ has $VERSION');

######################################################################
# 3. JSON::LINQ::Ordered is loaded
######################################################################

ok(JSON::LINQ::Ordered->isa('JSON::LINQ'), 'JSON::LINQ::Ordered isa JSON::LINQ');

######################################################################
# 4. JSON::LINQ public methods
######################################################################

for my $m (@linq_methods) {
    ok(JSON::LINQ->can($m), "JSON::LINQ->can('$m')");
}

######################################################################
# 5. JSON::LINQ::Ordered ThenBy methods
######################################################################

for my $m (@ordered_methods) {
    ok(JSON::LINQ::Ordered->can($m), "JSON::LINQ::Ordered->can('$m')");
}

######################################################################
# 6. INA_CPAN_Check library
######################################################################

eval { require INA_CPAN_Check };
ok(!$@, 'INA_CPAN_Check loads');

for my $sub (@check_subs) {
    ok(INA_CPAN_Check->can($sub), "INA_CPAN_Check exports '$sub'");
}
