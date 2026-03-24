######################################################################
# 02_array_query.pl - LINQ queries on in-memory arrays
#
# Usage: perl eg/02_array_query.pl
#
# Demonstrates:
#   - From: wrap an array of hashrefs in a query
#   - Where, Select, OrderBy, OrderByNumDescending, Skip, Take
#   - Sum, Average, Min, Max, Count
#   - Any, All, Contains
#   - ToArray: execute and collect results
#   - Zip: combine two sequences element-by-element
######################################################################
use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; local $^W=1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";
use LTSV::LINQ;

my @students = (
    { name => 'Alice',   score => 85, grade => 'A' },
    { name => 'Bob',     score => 70, grade => 'B' },
    { name => 'Carol',   score => 95, grade => 'A' },
    { name => 'Dave',    score => 60, grade => 'C' },
    { name => 'Eve',     score => 88, grade => 'A' },
    { name => 'Frank',   score => 55, grade => 'F' },
);

######################################################################
# 1. Filter and sort
######################################################################
print "--- 1. Grade A students, sorted by score desc ---\n";
my @grade_a = LTSV::LINQ->From(\@students)
    ->Where(sub { $_[0]{grade} eq 'A' })
    ->OrderByNumDescending(sub { $_[0]{score} })
    ->ToArray();

for my $s (@grade_a) {
    printf "  %-8s score=%d\n", $s->{name}, $s->{score};
}

######################################################################
# 2. Aggregation
######################################################################
print "\n--- 2. Aggregation ---\n";
# Note: each terminal method exhausts the iterator; create a fresh query for each.
printf "  Count   : %d\n",   LTSV::LINQ->From(\@students)->Count();
printf "  Average : %.1f\n", LTSV::LINQ->From(\@students)->Average(sub { $_[0]{score} });
printf "  Max     : %d\n",   LTSV::LINQ->From(\@students)->Max(sub { $_[0]{score} });
printf "  Min     : %d\n",   LTSV::LINQ->From(\@students)->Min(sub { $_[0]{score} });
printf "  Sum     : %d\n",   LTSV::LINQ->From(\@students)->Sum(sub { $_[0]{score} });

######################################################################
# 3. Any / All / Contains
######################################################################
print "\n--- 3. Any / All / Contains ---\n";
my $any_fail = LTSV::LINQ->From(\@students)
    ->Any(sub { $_[0]{grade} eq 'F' });
printf "  Any grade F : %s\n", $any_fail ? 'yes' : 'no';

my $all_pass = LTSV::LINQ->From(\@students)
    ->All(sub { $_[0]{score} >= 50 });
printf "  All score>=50: %s\n", $all_pass ? 'yes' : 'no';

# Contains: check if a specific value appears in a sequence of scalars
my @names = LTSV::LINQ->From(\@students)->Select(sub { $_[0]{name} })->ToArray();
my $has_alice = LTSV::LINQ->From([ @names ])->Contains('Alice');
printf "  Contains Alice: %s\n", $has_alice ? 'yes' : 'no';

######################################################################
# 4. Paging: Skip / Take
######################################################################
print "\n--- 4. Paging (skip 2, take 2) ---\n";
my @page = LTSV::LINQ->From(\@students)
    ->OrderBy(sub { $_[0]{name} })
    ->Skip(2)
    ->Take(2)
    ->Select(sub { $_[0]{name} })
    ->ToArray();
print "  ", join(", ", @page), "\n";

######################################################################
# 5. Zip two sequences
######################################################################
print "\n--- 5. Zip scores with rank numbers ---\n";
my @sorted_names = LTSV::LINQ->From(\@students)
    ->OrderByNumDescending(sub { $_[0]{score} })
    ->Select(sub { "$_[0]{name}($_[0]{score})" })
    ->ToArray();

my @ranks = (1..scalar(@sorted_names));
# Zip: both arguments must be LTSV::LINQ objects
my @ranked = LTSV::LINQ->From([ @sorted_names ])
    ->Zip(LTSV::LINQ->From([ @ranks ]),
          sub { "Rank $_[1]: $_[0]" })
    ->ToArray();

for my $r (@ranked) {
    print "  $r\n";
}
