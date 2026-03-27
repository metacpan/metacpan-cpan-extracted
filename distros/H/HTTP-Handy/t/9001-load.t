######################################################################
#
# 9001-load.t
#
# SYNOPSIS
#   prove -l t/9001-load.t
#   perl t/9001-load.t
#
# DESCRIPTION
#   Verifies two things:
#
#   1. HTTP::Handy module load and interface
#      - The module loads without error
#      - $VERSION is defined and looks like a version number
#      - HTTP::Handy::Input sub-package is present
#      - Public methods exist (can() check)
#
#   2. INA_CPAN_Check library load and export
#      - t/lib/INA_CPAN_Check.pm loads without error
#      - check_A through check_K and helpers are defined
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

######################################################################
# Minimal TAP harness (local -- not imported from INA_CPAN_Check
# so that the counter is not reset when INA_CPAN_Check is loaded)
######################################################################

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

######################################################################
# Test plan
######################################################################

my @handy_methods = qw(
    run serve_static
    url_decode parse_query mime_type
    is_htmx
    response_redirect response_json response_html response_text
);
my @input_methods = qw(new read seek tell getline getlines);

my $total = 4                           # load + VERSION + packages
          + scalar(@handy_methods)      # HTTP::Handy methods
          + scalar(@input_methods)      # HTTP::Handy::Input methods
          + 4;                          # INA_CPAN_Check section
plan_tests($total);

######################################################################
# Section 1: HTTP::Handy
######################################################################

# ok 1: module loads
eval { require HTTP::Handy };
ok(!$@, 'HTTP::Handy loads without error');
diag("load error: $@") if $@;

# ok 2-3: VERSION
ok(defined $HTTP::Handy::VERSION,         'HTTP::Handy: $VERSION defined');
ok($HTTP::Handy::VERSION =~ /^\d+\.\d+/, 'HTTP::Handy: $VERSION looks like a version number');

# ok 4: HTTP::Handy::Input present
ok(defined $HTTP::Handy::Input::{new}, 'HTTP::Handy::Input package present');

# ok 5+: HTTP::Handy public methods
for my $m (@handy_methods) {
    ok(HTTP::Handy->can($m), "HTTP::Handy->can('$m')");
}

# HTTP::Handy::Input methods
for my $m (@input_methods) {
    ok(HTTP::Handy::Input->can($m), "HTTP::Handy::Input->can('$m')");
}

######################################################################
# Section 2: INA_CPAN_Check
######################################################################

eval { require INA_CPAN_Check };
ok(!$@, 'INA_CPAN_Check loads without error');
diag("load error: $@") if $@;

ok( defined &INA_CPAN_Check::ok
 && defined &INA_CPAN_Check::plan_tests
 && defined &INA_CPAN_Check::_slurp
 && defined &INA_CPAN_Check::_slurp_lines
 && defined &INA_CPAN_Check::_scan_code,
   'INA_CPAN_Check: key helpers defined');

ok( defined &INA_CPAN_Check::check_A && defined &INA_CPAN_Check::check_B
 && defined &INA_CPAN_Check::check_C && defined &INA_CPAN_Check::check_D
 && defined &INA_CPAN_Check::check_E && defined &INA_CPAN_Check::check_F
 && defined &INA_CPAN_Check::check_G && defined &INA_CPAN_Check::check_H
 && defined &INA_CPAN_Check::check_I && defined &INA_CPAN_Check::check_J
 && defined &INA_CPAN_Check::check_K,
   'INA_CPAN_Check: check_A through check_K defined');

ok( defined &INA_CPAN_Check::count_A && defined &INA_CPAN_Check::count_B
 && defined &INA_CPAN_Check::count_C && defined &INA_CPAN_Check::count_D
 && defined &INA_CPAN_Check::count_E && defined &INA_CPAN_Check::count_F
 && defined &INA_CPAN_Check::count_G && defined &INA_CPAN_Check::count_H
 && defined &INA_CPAN_Check::count_I && defined &INA_CPAN_Check::count_J
 && defined &INA_CPAN_Check::count_K,
   'INA_CPAN_Check: count_A through count_K defined');
