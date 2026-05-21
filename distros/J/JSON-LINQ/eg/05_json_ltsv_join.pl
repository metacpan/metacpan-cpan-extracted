######################################################################
#
# 05_json_ltsv_join.pl - JOIN main JSON table with sub-table LTSV
#
# Demonstrates:
#   - FromJSON: read main employee table from JSON
#   - FromLTSV: read sub-table department lookup from LTSV
#   - Join:     inner join JSON x LTSV on dept_id == id
#   - GroupJoin: LEFT OUTER variant keeping unmatched employees
#
######################################################################

use strict;
BEGIN { if ($] < 5.006) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";
use JSON::LINQ;
use File::Spec ();

my $tmpdir   = File::Spec->tmpdir();
my $emp_json = File::Spec->catfile($tmpdir, "eg05_emp_$$.json");
my $dep_ltsv = File::Spec->catfile($tmpdir, "eg05_dep_$$.ltsv");

# --- Setup: write sample input files ---
local *EMP_FH;
open(EMP_FH, "> $emp_json") or die $!;
binmode EMP_FH;
print EMP_FH '[';
print EMP_FH '{"id":1,"name":"Alice","dept_id":10},';
print EMP_FH '{"id":2,"name":"Bob","dept_id":20},';
print EMP_FH '{"id":3,"name":"Carol","dept_id":10},';
print EMP_FH '{"id":4,"name":"Dave","dept_id":99}';   # no matching dept
print EMP_FH ']';
close EMP_FH;

local *DEP_FH;
open(DEP_FH, "> $dep_ltsv") or die $!;
binmode DEP_FH;
print DEP_FH "id:10\tname:Engineering\n";
print DEP_FH "id:20\tname:Sales\n";
close DEP_FH;

print "=== JOIN: main JSON x sub-table LTSV ===\n\n";

# --- (a) Inner Join: matched employees only ---
print "[ Inner Join (matched only) ]\n";
my $depts = JSON::LINQ->FromLTSV($dep_ltsv);
my @joined = JSON::LINQ->FromJSON($emp_json)
    ->Join($depts,
        sub { $_[0]{dept_id} },                       # outer key (JSON side)
        sub { $_[0]{id}      },                       # inner key (LTSV side)
        sub { { name => $_[0]{name},
                dept => $_[1]{name} } })
    ->OrderBy(sub { $_[0]{name} })
    ->ToArray();

for my $r (@joined) {
    printf "  %-10s -> %s\n", $r->{name}, $r->{dept};
}

# --- (b) GroupJoin (LEFT OUTER): keep employees without matching dept ---
print "\n[ GroupJoin (LEFT OUTER, all employees) ]\n";
my $depts2 = JSON::LINQ->FromLTSV($dep_ltsv);
my @all = JSON::LINQ->FromJSON($emp_json)
    ->GroupJoin($depts2,
        sub { $_[0]{dept_id} },
        sub { $_[0]{id}      },
        sub { my($e, $g) = @_;
              my @g = $g->ToArray();
              { name => $e->{name},
                dept => @g ? $g[0]{name} : '(unassigned)' } })
    ->OrderBy(sub { $_[0]{name} })
    ->ToArray();

for my $r (@all) {
    printf "  %-10s -> %s\n", $r->{name}, $r->{dept};
}

# --- (c) Pipeline: filter + join + count by dept ---
print "\n[ Headcount per department (assigned only) ]\n";
my $depts3 = JSON::LINQ->FromLTSV($dep_ltsv);
my %count;
JSON::LINQ->FromJSON($emp_json)
    ->Join($depts3,
        sub { $_[0]{dept_id} },
        sub { $_[0]{id}      },
        sub { $_[1]{name} })
    ->ForEach(sub { $count{$_[0]}++ });

for my $d (sort keys %count) {
    printf "  %-15s %d\n", $d, $count{$d};
}

unlink $emp_json, $dep_ltsv;
print "\nDone.\n";
