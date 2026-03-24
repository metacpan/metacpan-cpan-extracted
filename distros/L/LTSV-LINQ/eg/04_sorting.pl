######################################################################
# 04_sorting.pl - OrderBy, ThenBy, multi-key sorting
#
# Usage: perl eg/04_sorting.pl
#
# Demonstrates:
#   - OrderBy: primary sort (smart comparison)
#   - OrderByStr, OrderByNum: explicit comparison type
#   - ThenByNumDescending: secondary sort key (numeric descending)
#   - ThenByStr: secondary sort key (string)
#   - Reverse: reverse any sequence
######################################################################
use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; local $^W=1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";
use LTSV::LINQ;

my @people = (
    { name => 'Carol',  age => 28, dept => 'Eng' },
    { name => 'Alice',  age => 32, dept => 'HR'  },
    { name => 'Bob',    age => 28, dept => 'Eng' },
    { name => 'Dave',   age => 25, dept => 'HR'  },
    { name => 'Eve',    age => 32, dept => 'Eng' },
    { name => 'Frank',  age => 25, dept => 'Eng' },
);

######################################################################
# 1. OrderBy with smart comparison
######################################################################
print "--- 1. OrderBy name (smart) ---\n";
my @by_name = LTSV::LINQ->From(\@people)
    ->OrderBy(sub { $_[0]{name} })
    ->Select(sub { "$_[0]{name}($_[0]{age})" })
    ->ToArray();
print "  ", join(", ", @by_name), "\n";

######################################################################
# 2. Multi-key sort: dept asc, then age desc, then name asc
######################################################################
print "\n--- 2. dept ASC, age DESC, name ASC ---\n";
my @multi = LTSV::LINQ->From(\@people)
    ->OrderByStr(sub { $_[0]{dept} })
    ->ThenByNumDescending(sub { $_[0]{age} })
    ->ThenByStr(sub { $_[0]{name} })
    ->ToArray();

for my $p (@multi) {
    printf "  %-4s  age=%-3d  %s\n", $p->{dept}, $p->{age}, $p->{name};
}

######################################################################
# 3. Numeric sort vs string sort
######################################################################
print "\n--- 3. Numeric sort vs string sort ---\n";
my @versions = ('10', '9', '2', '20', '1', '11');

my @str_sorted = LTSV::LINQ->From(\@versions)
    ->OrderByStr(sub { $_[0] })
    ->ToArray();
print "  String sort : ", join(", ", @str_sorted), "\n";

my @num_sorted = LTSV::LINQ->From(\@versions)
    ->OrderByNum(sub { $_[0] })
    ->ToArray();
print "  Numeric sort: ", join(", ", @num_sorted), "\n";

######################################################################
# 4. Reverse
######################################################################
print "\n--- 4. Reverse ---\n";
my @reversed = LTSV::LINQ->From(\@versions)
    ->OrderByNum(sub { $_[0] })
    ->Reverse()
    ->ToArray();
print "  Reversed    : ", join(", ", @reversed), "\n";
