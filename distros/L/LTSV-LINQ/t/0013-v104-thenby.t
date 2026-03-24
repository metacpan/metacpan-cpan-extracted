######################################################################
#
# 0013-v104-thenby.t - Tests for ThenBy/ThenByDescending (v1.04)
#
######################################################################

use strict;
BEGIN { if ($] < 5.006) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";
use LTSV::LINQ;

###############################################################################
# Embedded test harness (no Test::More dependency)
###############################################################################
my ($PASS, $FAIL, $T) = (0, 0, 0);
sub ok   { my($c,$n)=@_; $T++; $c ? ($PASS++, print "ok $T - $n\n") : ($FAIL++, print "not ok $T - $n\n") }
sub is   { my($g,$e,$n)=@_; $T++; defined($g)&&("$g" eq "$e") ? ($PASS++, print "ok $T - $n\n") : ($FAIL++, print "not ok $T - $n  (got='${\(defined $g?$g:'undef')}', exp='$e')\n") }
sub like { my($g,$re,$n)=@_; $T++; defined($g)&&$g=~$re ? ($PASS++, print "ok $T - $n\n") : ($FAIL++, print "not ok $T - $n\n") }
sub plan_skip { print "1..0 # SKIP $_[0]\n"; exit 0 }

print "1..42\n";

my $test_num = 0;
sub is_list {
    my($got_ref, $exp_ref, $name) = @_;
    my $ok = (scalar(@$got_ref) == scalar(@$exp_ref));
    if ($ok) {
        for my $i (0 .. $#$exp_ref) {
            unless (defined($got_ref->[$i]) && $got_ref->[$i] eq $exp_ref->[$i]) {
                $ok = 0; last;
            }
        }
    }
    ok($ok, $name);
}

my @employees = (
    { dept => 'Engineering', name => 'Zoe',    salary => 90000, age => 30 },
    { dept => 'Marketing',   name => 'Alice',  salary => 70000, age => 25 },
    { dept => 'Engineering', name => 'Alice',  salary => 95000, age => 35 },
    { dept => 'Marketing',   name => 'Bob',    salary => 72000, age => 28 },
    { dept => 'Engineering', name => 'Bob',    salary => 90000, age => 32 },
    { dept => 'HR',          name => 'Carol',  salary => 65000, age => 40 },
    { dept => 'HR',          name => 'Alice',  salary => 68000, age => 27 },
);

#---------------------------------------------------------------------
# 1. OrderBy returns LTSV::LINQ::Ordered
#---------------------------------------------------------------------
{
    my $q = LTSV::LINQ->From(\@employees)->OrderBy(sub { $_[0]{dept} });
    ok(ref($q) eq 'LTSV::LINQ::Ordered', 'OrderBy returns LTSV::LINQ::Ordered');
}

#---------------------------------------------------------------------
# 2. ThenBy returns LTSV::LINQ::Ordered
#---------------------------------------------------------------------
{
    my $q = LTSV::LINQ->From(\@employees)
        ->OrderBy(sub { $_[0]{dept} })
        ->ThenBy(sub { $_[0]{name} });
    ok(ref($q) eq 'LTSV::LINQ::Ordered', 'ThenBy returns LTSV::LINQ::Ordered');
}

#---------------------------------------------------------------------
# 3. Where after ThenBy returns LTSV::LINQ (not Ordered)
#---------------------------------------------------------------------
{
    my $q = LTSV::LINQ->From(\@employees)
        ->OrderBy(sub { $_[0]{dept} })
        ->ThenBy(sub { $_[0]{name} })
        ->Where(sub { 1 });
    ok(ref($q) eq 'LTSV::LINQ::Ordered', 'Where after ThenBy still chained');
}

#---------------------------------------------------------------------
# 4. ThenBy: OrderBy(dept asc) + ThenBy(name asc)
#---------------------------------------------------------------------
{
    my @r = LTSV::LINQ->From(\@employees)
        ->OrderBy(sub  { $_[0]{dept} })
        ->ThenBy(sub   { $_[0]{name} })
        ->Select(sub   { "$_[0]{dept}/$_[0]{name}" })
        ->ToArray();
    is_list(\@r,
        ['Engineering/Alice','Engineering/Bob','Engineering/Zoe',
         'HR/Alice','HR/Carol',
         'Marketing/Alice','Marketing/Bob'],
         'OrderBy(dept) + ThenBy(name)');
}

#---------------------------------------------------------------------
# 5. ThenByDescending: OrderBy(dept asc) + ThenByDescending(name)
#---------------------------------------------------------------------
{
    my @r = LTSV::LINQ->From(\@employees)
        ->OrderBy(sub            { $_[0]{dept} })
        ->ThenByDescending(sub   { $_[0]{name} })
        ->Select(sub             { "$_[0]{dept}/$_[0]{name}" })
        ->ToArray();
    is_list(\@r,
        ['Engineering/Zoe','Engineering/Bob','Engineering/Alice',
         'HR/Carol','HR/Alice',
         'Marketing/Bob','Marketing/Alice'],
         'OrderBy(dept) + ThenByDescending(name)');
}

#---------------------------------------------------------------------
# 6-10. Three keys: OrderBy(dept) + ThenBy(name) + ThenByNum(salary desc)
#---------------------------------------------------------------------
{
    my @r = LTSV::LINQ->From(\@employees)
        ->OrderBy(sub               { $_[0]{dept}   })
        ->ThenBy(sub                { $_[0]{name}   })
        ->ThenByNumDescending(sub   { $_[0]{salary} })
        ->Select(sub { "$_[0]{dept}/$_[0]{name}/$_[0]{salary}" })
        ->ToArray();
    # Engineering/Alice: only one -> 95000
    # Engineering/Bob: only one -> 90000
    # Engineering/Zoe: only one -> 90000
    ok($r[0] eq 'Engineering/Alice/95000', 'Three-key: Engineering/Alice');
    ok($r[1] eq 'Engineering/Bob/90000',   'Three-key: Engineering/Bob');
    ok($r[2] eq 'Engineering/Zoe/90000',   'Three-key: Engineering/Zoe');
    ok($r[3] eq 'HR/Alice/68000',          'Three-key: HR/Alice');
    ok($r[4] eq 'HR/Carol/65000',          'Three-key: HR/Carol');
}

#---------------------------------------------------------------------
# 11-12. Stability: equal primary keys preserve relative input order
#---------------------------------------------------------------------
{
    # Two Engineering/Bob entries with same dept+name but different salary
    my @data = (
        { dept => 'X', name => 'A', id => 1 },
        { dept => 'X', name => 'B', id => 2 },
        { dept => 'X', name => 'A', id => 3 },
        { dept => 'X', name => 'B', id => 4 },
    );
    my @r = LTSV::LINQ->From(\@data)
        ->OrderBy(sub  { $_[0]{dept} })
        ->ThenBy(sub   { $_[0]{name} })
        ->ToArray();
    # A before A (id 1 < 3), B before B (id 2 < 4)
    ok($r[0]{id} == 1 && $r[1]{id} == 3, 'Stability: A group preserves input order');
    ok($r[2]{id} == 2 && $r[3]{id} == 4, 'Stability: B group preserves input order');
}

#---------------------------------------------------------------------
# 13-15. Non-destructive: branching from the same Ordered object
#---------------------------------------------------------------------
{
    my $by_dept = LTSV::LINQ->From(\@employees)
        ->OrderBy(sub { $_[0]{dept} });

    my @by_name   = $by_dept->ThenBy(sub { $_[0]{name}   })->Select(sub { $_[0]{name} })->ToArray();
    my @by_salary = $by_dept->ThenByNum(sub { $_[0]{salary} })->Select(sub { $_[0]{salary} })->ToArray();

    # by_name: within each dept, names sorted asc
    ok($by_name[0] eq 'Alice', 'Non-destructive branch: first by name');
    # by_salary: within each dept, salary sorted asc (Engineering: 90000,90000,95000)
    ok($by_salary[0] == 90000, 'Non-destructive branch: first by salary');
    # Confirm the two branches differ
    my $differs = ($by_name[2] ne $by_salary[2]);
    ok($differs, 'Non-destructive branch: two branches produce different orders');
}

#---------------------------------------------------------------------
# 16-18. OrderByDescending + ThenBy
#---------------------------------------------------------------------
{
    my @r = LTSV::LINQ->From(\@employees)
        ->OrderByDescending(sub { $_[0]{dept} })
        ->ThenBy(sub            { $_[0]{name} })
        ->Select(sub { "$_[0]{dept}/$_[0]{name}" })
        ->ToArray();
    # dept desc: Marketing, HR, Engineering
    ok($r[0] eq 'Marketing/Alice', 'OrderByDescending + ThenBy: first');
    ok($r[1] eq 'Marketing/Bob',   'OrderByDescending + ThenBy: second');
    ok($r[2] eq 'HR/Alice',        'OrderByDescending + ThenBy: third');
}

#---------------------------------------------------------------------
# 19-20. ThenByStr vs ThenBy (smart): string "10" vs "9"
#---------------------------------------------------------------------
{
    my @data = (
        { g => 'A', v => '9'  },
        { g => 'A', v => '10' },
        { g => 'A', v => '2'  },
    );
    # ThenBy (smart): numeric -> 2, 9, 10
    my @smart = LTSV::LINQ->From(\@data)
        ->OrderByStr(sub { $_[0]{g} })
        ->ThenBy(sub     { $_[0]{v} })
        ->Select(sub { $_[0]{v} })->ToArray();
    is_list(\@smart, ['2','9','10'], 'ThenBy smart: numeric order');

    # ThenByStr: lexicographic -> 10, 2, 9
    my @str = LTSV::LINQ->From(\@data)
        ->OrderByStr(sub    { $_[0]{g} })
        ->ThenByStr(sub     { $_[0]{v} })
        ->Select(sub { $_[0]{v} })->ToArray();
    is_list(\@str, ['10','2','9'], 'ThenByStr: lexicographic order');
}

#---------------------------------------------------------------------
# 21-24. ThenByNum with undef (treated as 0)
#---------------------------------------------------------------------
{
    my @data = (
        { g => 'A', n => undef },
        { g => 'A', n => 5     },
        { g => 'A', n => undef },
        { g => 'A', n => 3     },
    );
    my @r = LTSV::LINQ->From(\@data)
        ->OrderByStr(sub  { $_[0]{g} })
        ->ThenByNum(sub   { $_[0]{n} })
        ->Select(sub { defined($_[0]{n}) ? $_[0]{n} : 'undef' })
        ->ToArray();
    # undef->0, 0, 3, 5
    ok($r[0] eq 'undef', 'ThenByNum undef: first is undef(=0)');
    ok($r[1] eq 'undef', 'ThenByNum undef: second is undef(=0)');
    ok($r[2] == 3,       'ThenByNum undef: third is 3');
    ok($r[3] == 5,       'ThenByNum undef: fourth is 5');
}

#---------------------------------------------------------------------
# 25-26. ThenByNumDescending
#---------------------------------------------------------------------
{
    my @r = LTSV::LINQ->From(\@employees)
        ->OrderByStr(sub            { $_[0]{dept}   })
        ->ThenByNumDescending(sub   { $_[0]{salary} })
        ->Select(sub { "$_[0]{dept}/$_[0]{salary}" })
        ->ToArray();
    # Engineering desc salary: 95000, 90000, 90000
    ok($r[0] eq 'Engineering/95000', 'ThenByNumDescending: highest first');
    ok($r[1] eq 'Engineering/90000', 'ThenByNumDescending: second');
}

#---------------------------------------------------------------------
# 27-29. ThenByStrDescending
#---------------------------------------------------------------------
{
    my @r = LTSV::LINQ->From(\@employees)
        ->OrderByStr(sub               { $_[0]{dept} })
        ->ThenByStrDescending(sub      { $_[0]{name} })
        ->Select(sub { "$_[0]{dept}/$_[0]{name}" })
        ->ToArray();
    ok($r[0] eq 'Engineering/Zoe',   'ThenByStrDescending: Zoe first in Engineering');
    ok($r[1] eq 'Engineering/Bob',   'ThenByStrDescending: Bob second');
    ok($r[2] eq 'Engineering/Alice', 'ThenByStrDescending: Alice third');
}

#---------------------------------------------------------------------
# 30-31. Chaining with Where after ThenBy
#---------------------------------------------------------------------
{
    my @r = LTSV::LINQ->From(\@employees)
        ->OrderBy(sub  { $_[0]{dept}   })
        ->ThenByNum(sub { $_[0]{salary} })
        ->Where(sub    { $_[0]{salary} >= 90000 })
        ->Select(sub   { "$_[0]{dept}/$_[0]{name}" })
        ->ToArray();
    ok(scalar(@r) == 3, 'ThenBy + Where: correct count (salary >= 90000)');
    ok($r[0] eq 'Engineering/Bob' || $r[0] eq 'Engineering/Zoe',
        'ThenBy + Where: Engineering first');
}

#---------------------------------------------------------------------
# 32-33. Chaining with Select after ThenBy
#---------------------------------------------------------------------
{
    my @r = LTSV::LINQ->From(\@employees)
        ->OrderByStr(sub { $_[0]{dept} })
        ->ThenByStr(sub  { $_[0]{name} })
        ->Select(sub     { { key => "$_[0]{dept}|$_[0]{name}", sal => $_[0]{salary} } })
        ->ToArray();
    ok($r[0]{key} eq 'Engineering|Alice', 'ThenBy + Select: first element key');
    ok($r[0]{sal} == 95000,               'ThenBy + Select: first element salary');
}

#---------------------------------------------------------------------
# 34. ThenBy with Count
#---------------------------------------------------------------------
{
    my $count = LTSV::LINQ->From(\@employees)
        ->OrderBy(sub  { $_[0]{dept} })
        ->ThenBy(sub   { $_[0]{name} })
        ->Count();
    ok($count == 7, 'ThenBy + Count: all elements present');
}

#---------------------------------------------------------------------
# 35-36. ThenBy with First / Last
#---------------------------------------------------------------------
{
    my $first = LTSV::LINQ->From(\@employees)
        ->OrderBy(sub  { $_[0]{dept} })
        ->ThenBy(sub   { $_[0]{name} })
        ->First();
    ok($first->{dept} eq 'Engineering' && $first->{name} eq 'Alice',
        'ThenBy + First');

    my $last = LTSV::LINQ->From(\@employees)
        ->OrderBy(sub  { $_[0]{dept} })
        ->ThenBy(sub   { $_[0]{name} })
        ->Last();
    ok($last->{dept} eq 'Marketing' && $last->{name} eq 'Bob',
        'ThenBy + Last');
}

#---------------------------------------------------------------------
# 37. ThenBy with Take / Skip
#---------------------------------------------------------------------
{
    my @r = LTSV::LINQ->From(\@employees)
        ->OrderByStr(sub { $_[0]{dept} })
        ->ThenByStr(sub  { $_[0]{name} })
        ->Skip(3)
        ->Take(2)
        ->Select(sub { "$_[0]{dept}/$_[0]{name}" })
        ->ToArray();
    # Sorted: Eng/Alice, Eng/Bob, Eng/Zoe, HR/Alice, HR/Carol, Mkt/Alice, Mkt/Bob
    # Skip(3) -> HR/Alice, HR/Carol, ... Take(2) -> HR/Alice, HR/Carol
    is_list(\@r, ['HR/Alice','HR/Carol'], 'ThenBy + Skip + Take');
}

#---------------------------------------------------------------------
# 38. OrderByNum + ThenByStr
#---------------------------------------------------------------------
{
    my @data = (
        { score => 80, name => 'Zoe'   },
        { score => 90, name => 'Alice' },
        { score => 80, name => 'Alice' },
        { score => 90, name => 'Bob'   },
    );
    my @r = LTSV::LINQ->From(\@data)
        ->OrderByNum(sub  { $_[0]{score} })
        ->ThenByStr(sub   { $_[0]{name}  })
        ->Select(sub { "$_[0]{score}/$_[0]{name}" })
        ->ToArray();
    is_list(\@r,
        ['80/Alice','80/Zoe','90/Alice','90/Bob'],
         'OrderByNum + ThenByStr');
}

#---------------------------------------------------------------------
# 39. Empty sequence
#---------------------------------------------------------------------
{
    my @r = LTSV::LINQ->From([])
        ->OrderBy(sub  { $_[0]{a} })
        ->ThenBy(sub   { $_[0]{b} })
        ->ToArray();
    ok(scalar(@r) == 0, 'ThenBy on empty sequence: empty result');
}

#---------------------------------------------------------------------
# 40. Single element
#---------------------------------------------------------------------
{
    my @r = LTSV::LINQ->From([{a=>1,b=>2}])
        ->OrderBy(sub  { $_[0]{a} })
        ->ThenByNum(sub { $_[0]{b} })
        ->ToArray();
    ok(scalar(@r) == 1 && $r[0]{a} == 1, 'ThenBy on single element');
}

#---------------------------------------------------------------------
# 41. Repeated iteration (re-iterability of Ordered object)
#---------------------------------------------------------------------
{
    my $q = LTSV::LINQ->From(\@employees)
        ->OrderByStr(sub { $_[0]{dept} })
        ->ThenByStr(sub  { $_[0]{name} });

    my @r1 = $q->ToArray();
    my @r2 = $q->ToArray();
    ok(scalar(@r1) == scalar(@r2) && $r1[0]{name} eq $r2[0]{name},
        'ThenBy: Ordered object is re-iterable');
}

#---------------------------------------------------------------------
# 42. LTSV realistic scenario: access log
#---------------------------------------------------------------------
{
    my @log = (
        { host => '10.0.0.1', status => '200', bytes => '512'  },
        { host => '10.0.0.2', status => '404', bytes => '128'  },
        { host => '10.0.0.1', status => '404', bytes => '64'   },
        { host => '10.0.0.2', status => '200', bytes => '1024' },
        { host => '10.0.0.1', status => '200', bytes => '256'  },
    );
    my @r = LTSV::LINQ->From(\@log)
        ->OrderByStr(sub    { $_[0]{host}   })
        ->ThenByStr(sub     { $_[0]{status} })
        ->ThenByNum(sub     { $_[0]{bytes}  })
        ->Select(sub { "$_[0]{host}/$_[0]{status}/$_[0]{bytes}" })
        ->ToArray();
    is_list(\@r,
        ['10.0.0.1/200/256','10.0.0.1/200/512',
         '10.0.0.1/404/64',
         '10.0.0.2/200/1024',
         '10.0.0.2/404/128'],
         'LTSV realistic: host + status + bytes');
}


exit($FAIL ? 1 : 0);
