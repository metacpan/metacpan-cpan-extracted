######################################################################
#
# 03_grouping.pl - Grouping and join example
#
# Demonstrates:
#   - GroupBy: group records by key
#   - GroupJoin: left outer join
#   - SelectMany: flatten nested arrays
#   - Join: inner join
#   - ToLookup: multi-value dictionary
#
######################################################################

use strict;
BEGIN { if ($] < 5.006) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";
use JSON::LINQ;

print "=== Grouping and Join Examples ===\n\n";

my @departments = (
    {id => 1, name => 'Engineering'},
    {id => 2, name => 'Sales'},
    {id => 3, name => 'HR'},
);

my @employees = (
    {id => 10, name => 'Alice', dept_id => 1, salary => 1000},
    {id => 11, name => 'Bob',   dept_id => 2, salary => 800},
    {id => 12, name => 'Carol', dept_id => 1, salary => 900},
    {id => 13, name => 'Dave',  dept_id => 1, salary => 850},
    {id => 14, name => 'Eve',   dept_id => 2, salary => 750},
);

# --- GroupBy: headcount per department ---
print "[ Headcount per department ]\n";
my @by_dept = JSON::LINQ->From(\@employees)
    ->GroupBy(sub { $_[0]{dept_id} })
    ->Select(sub {
        my $g = shift;
        my $avg = JSON::LINQ->From($g->{Elements})->Average(sub { $_[0]{salary} });
        return { dept_id => $g->{Key}, count => scalar(@{$g->{Elements}}), avg => $avg };
    })
    ->OrderByNum(sub { $_[0]{dept_id} })
    ->ToArray();

for my $d (@by_dept) {
    printf "  dept_id=%s  count=%d  avg_salary=%.0f\n",
        $d->{dept_id}, $d->{count}, $d->{avg};
}

# --- GroupJoin: all departments with their staff (incl. empty HR) ---
print "\n[ All departments with staff (GroupJoin = left outer join) ]\n";
my @dept_staff = JSON::LINQ->From(\@departments)->GroupJoin(
    JSON::LINQ->From(\@employees),
    sub { $_[0]{id} },
    sub { $_[0]{dept_id} },
    sub {
        my($dept, $staff) = @_;
        my @names = $staff->Select(sub { $_[0]{name} })->ToArray();
        return { dept => $dept->{name}, staff => \@names };
    }
)->ToArray();

for my $d (@dept_staff) {
    my $staff = @{$d->{staff}} ? join(', ', @{$d->{staff}}) : '(none)';
    printf "  %-15s  %s\n", $d->{dept}, $staff;
}

# --- Join: employee with department name ---
print "\n[ Employee with department name (inner Join) ]\n";
my @with_dept = JSON::LINQ->From(\@employees)->Join(
    JSON::LINQ->From(\@departments),
    sub { $_[0]{dept_id} },
    sub { $_[0]{id} },
    sub { my($e, $d) = @_; return {name => $e->{name}, dept => $d->{name}} }
)->OrderByStr(sub { $_[0]{name} })->ToArray();

for my $r (@with_dept) {
    printf "  %-10s  %s\n", $r->{name}, $r->{dept};
}

# --- SelectMany: flatten tags ---
print "\n[ Tags via SelectMany ]\n";
my @tagged = (
    {item => 'report.pdf', tags => ['finance', 'Q1', 'annual']},
    {item => 'plan.docx',  tags => ['strategy', 'Q2']},
    {item => 'data.csv',   tags => ['finance', 'data']},
);
my @all_tags = JSON::LINQ->From(\@tagged)
    ->SelectMany(sub { $_[0]{tags} })
    ->Distinct()
    ->OrderByStr(sub { $_[0] })
    ->ToArray();
print "  All unique tags: ", join(', ', @all_tags), "\n";

# --- ToLookup: multi-value grouping ---
print "\n[ ToLookup: employees by department name ]\n";
my $lookup = JSON::LINQ->From(\@employees)->Join(
    JSON::LINQ->From(\@departments),
    sub { $_[0]{dept_id} },
    sub { $_[0]{id} },
    sub { my($e,$d) = @_; return {name => $e->{name}, dept => $d->{name}} }
)->ToLookup(sub { $_[0]{dept} }, sub { $_[0]{name} });

for my $dept (sort keys %$lookup) {
    printf "  %-15s  %s\n", $dept, join(', ', @{$lookup->{$dept}});
}

print "\nDone.\n";
