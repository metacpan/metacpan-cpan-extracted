######################################################################
#
# 0011-groupjoin.t - Tests for GroupJoin (v1.03)
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

print "1..35\n";

my $test_num = 0;
#---------------------------------------------------------------------
# Basic GroupJoin
#---------------------------------------------------------------------

# Test 1: Basic LEFT OUTER JOIN - all outer elements present
my @users  = ({id => 1, name => 'Alice'},
              {id => 2, name => 'Bob'},
              {id => 3, name => 'Carol'});
my @orders = ({user_id => 1, product => 'Book',     amount => 10},
              {user_id => 1, product => 'Pen',      amount =>  5},
              {user_id => 2, product => 'Notebook', amount => 15});

my @result = LTSV::LINQ->From(\@users)->GroupJoin(
    LTSV::LINQ->From(\@orders),
    sub { $_[0]{id} },
    sub { $_[0]{user_id} },
    sub {
        my($user, $grp) = @_;
        my @arr = $grp->ToArray();
        return { name => $user->{name}, count => scalar @arr };
    }
)->ToArray();

ok(@result == 3, 'GroupJoin: all outer elements returned (left outer)');

# Test 2: Correct match count for Alice (2 orders)
ok($result[0]{name} eq 'Alice' && $result[0]{count} == 2,
   'GroupJoin: Alice has 2 orders');

# Test 3: Correct match count for Bob (1 order)
ok($result[1]{name} eq 'Bob' && $result[1]{count} == 1,
   'GroupJoin: Bob has 1 order');

# Test 4: Carol has 0 orders (empty group)
ok($result[2]{name} eq 'Carol' && $result[2]{count} == 0,
   'GroupJoin: Carol has 0 orders (empty group)');

#---------------------------------------------------------------------
# LINQ methods on inner_group (re-iterable)
#---------------------------------------------------------------------

# Test 5: Count() on inner group
my @r5 = LTSV::LINQ->From(\@users)->GroupJoin(
    LTSV::LINQ->From(\@orders),
    sub { $_[0]{id} },
    sub { $_[0]{user_id} },
    sub {
        my($user, $grp) = @_;
        return { name => $user->{name}, count => $grp->Count() };
    }
)->ToArray();
ok($r5[0]{count} == 2 && $r5[1]{count} == 1 && $r5[2]{count} == 0,
   'GroupJoin: Count() on inner_group');

# Test 6: Any() on inner group
my @r6 = LTSV::LINQ->From(\@users)->GroupJoin(
    LTSV::LINQ->From(\@orders),
    sub { $_[0]{id} },
    sub { $_[0]{user_id} },
    sub {
        my($user, $grp) = @_;
        return { name => $user->{name}, has_orders => $grp->Any() ? 1 : 0 };
    }
)->ToArray();
ok($r6[0]{has_orders} == 1 && $r6[1]{has_orders} == 1 && $r6[2]{has_orders} == 0,
   'GroupJoin: Any() on inner_group');

# Test 7: Sum() on inner group
my @r7 = LTSV::LINQ->From(\@users)->GroupJoin(
    LTSV::LINQ->From(\@orders),
    sub { $_[0]{id} },
    sub { $_[0]{user_id} },
    sub {
        my($user, $grp) = @_;
        my $total = $grp->Sum(sub { defined($_[0]{amount}) ? $_[0]{amount} : 0 });
        return { name => $user->{name}, total => $total };
    }
)->ToArray();
ok($r7[0]{total} == 15 && $r7[1]{total} == 15 && $r7[2]{total} == 0,
   'GroupJoin: Sum() on inner_group');

# Test 8: Count() AND Any() both called on same $grp (re-iterability)
my @r8 = LTSV::LINQ->From(\@users)->GroupJoin(
    LTSV::LINQ->From(\@orders),
    sub { $_[0]{id} },
    sub { $_[0]{user_id} },
    sub {
        my($user, $grp) = @_;
        my $count   = $grp->Count();
        my $has_any = $grp->Any() ? 1 : 0;
        return { name => $user->{name}, count => $count, has_any => $has_any };
    }
)->ToArray();
ok($r8[0]{count} == 2 && $r8[0]{has_any} == 1,
   'GroupJoin: Count() + Any() re-iterable for Alice');

# Test 9: Count() AND Any() both called on same $grp (empty)
ok($r8[2]{count} == 0 && $r8[2]{has_any} == 0,
   'GroupJoin: Count() + Any() re-iterable for Carol (empty)');

# Test 10: Where() on inner group
my @r10 = LTSV::LINQ->From(\@users)->GroupJoin(
    LTSV::LINQ->From(\@orders),
    sub { $_[0]{id} },
    sub { $_[0]{user_id} },
    sub {
        my($user, $grp) = @_;
        my @cheap = $grp->Where(sub { (defined($_[0]{amount}) ? $_[0]{amount} : 0) < 10 })->ToArray();
        return { name => $user->{name}, cheap => scalar @cheap };
    }
)->ToArray();
ok($r10[0]{cheap} == 1, 'GroupJoin: Where() on inner_group (Alice cheap items)');

# Test 11: Where() on empty inner group
ok($r10[2]{cheap} == 0, 'GroupJoin: Where() on empty inner_group');

#---------------------------------------------------------------------
# Empty sequences
#---------------------------------------------------------------------

# Test 12: Empty outer sequence
my @r12 = LTSV::LINQ->From([])->GroupJoin(
    LTSV::LINQ->From(\@orders),
    sub { $_[0]{id} },
    sub { $_[0]{user_id} },
    sub { my($u, $g) = @_; return { count => $g->Count() }; }
)->ToArray();
ok(@r12 == 0, 'GroupJoin: empty outer -> empty result');

# Test 13: Empty inner sequence - all outer get empty groups
my @r13 = LTSV::LINQ->From(\@users)->GroupJoin(
    LTSV::LINQ->From([]),
    sub { $_[0]{id} },
    sub { $_[0]{user_id} },
    sub {
        my($user, $grp) = @_;
        return { name => $user->{name}, count => $grp->Count() };
    }
)->ToArray();
ok(@r13 == 3 && $r13[0]{count} == 0 && $r13[1]{count} == 0 && $r13[2]{count} == 0,
   'GroupJoin: empty inner -> all outer get empty groups');

# Test 14: Both sequences empty
my @r14 = LTSV::LINQ->From([])->GroupJoin(
    LTSV::LINQ->From([]),
    sub { $_[0] },
    sub { $_[0] },
    sub { return $_[1]->Count() }
)->ToArray();
ok(@r14 == 0, 'GroupJoin: both empty -> empty result');

#---------------------------------------------------------------------
# Scalar (non-hash-ref) keys
#---------------------------------------------------------------------

# Test 15: Scalar keys
my @nums  = (1, 2, 3);
my @pairs = (1, 1, 2);

my @r15 = LTSV::LINQ->From(\@nums)->GroupJoin(
    LTSV::LINQ->From(\@pairs),
    sub { $_[0] },
    sub { $_[0] },
    sub {
        my($num, $grp) = @_;
        return { num => $num, count => $grp->Count() };
    }
)->ToArray();
ok($r15[0]{count} == 2 && $r15[1]{count} == 1 && $r15[2]{count} == 0,
   'GroupJoin: scalar keys work correctly');

#---------------------------------------------------------------------
# Multiple matches (1:N)
#---------------------------------------------------------------------

# Test 16: One outer matches many inners
my @one_user  = ({id => 1, name => 'Alice'});
my @many_orders = map { {user_id => 1, seq => $_} } (1..5);

my @r16 = LTSV::LINQ->From(\@one_user)->GroupJoin(
    LTSV::LINQ->From(\@many_orders),
    sub { $_[0]{id} },
    sub { $_[0]{user_id} },
    sub {
        my($user, $grp) = @_;
        return { name => $user->{name}, count => $grp->Count() };
    }
)->ToArray();
ok($r16[0]{count} == 5, 'GroupJoin: one outer matches 5 inners');

#---------------------------------------------------------------------
# Result selector can produce complex results
#---------------------------------------------------------------------

# Test 17: result_selector returns flat scalar
my @r17 = LTSV::LINQ->From(\@users)->GroupJoin(
    LTSV::LINQ->From(\@orders),
    sub { $_[0]{id} },
    sub { $_[0]{user_id} },
    sub { my($u, $g) = @_; return $g->Count() }
)->ToArray();
ok($r17[0] == 2 && $r17[1] == 1 && $r17[2] == 0,
   'GroupJoin: result_selector can return scalar');

# Test 18: ToLTSV-compatible result (hash with string values)
my @r18 = LTSV::LINQ->From(\@users)->GroupJoin(
    LTSV::LINQ->From(\@orders),
    sub { $_[0]{id} },
    sub { $_[0]{user_id} },
    sub {
        my($user, $grp) = @_;
        return {
            name         => $user->{name},
            order_count  => $grp->Count(),
            total_amount => $grp->Sum(sub { defined($_[0]{amount}) ? $_[0]{amount} : 0 }),
        };
    }
)->ToArray();
ok($r18[0]{name} eq 'Alice' && $r18[0]{order_count} == 2 && $r18[0]{total_amount} == 15,
   'GroupJoin: complex result with Count+Sum (re-iterable)');

#---------------------------------------------------------------------
# Chaining with other LINQ methods
#---------------------------------------------------------------------

# Test 19: GroupJoin + Where
my @r19 = LTSV::LINQ->From(\@users)->GroupJoin(
    LTSV::LINQ->From(\@orders),
    sub { $_[0]{id} },
    sub { $_[0]{user_id} },
    sub {
        my($u, $g) = @_;
        return { name => $u->{name}, count => $g->Count() };
    }
)->Where(sub { $_[0]{count} > 0 })->ToArray();
ok(@r19 == 2, 'GroupJoin + Where: filters out no-order users');

# Test 20: GroupJoin + Select
my @r20 = LTSV::LINQ->From(\@users)->GroupJoin(
    LTSV::LINQ->From(\@orders),
    sub { $_[0]{id} },
    sub { $_[0]{user_id} },
    sub { my($u, $g) = @_; return { name => $u->{name}, count => $g->Count() }; }
)->Select(sub { "$_[0]{name}:$_[0]{count}" })->ToArray();
ok($r20[0] eq 'Alice:2' && $r20[1] eq 'Bob:1' && $r20[2] eq 'Carol:0',
   'GroupJoin + Select: maps to strings');

# Test 21: GroupJoin + OrderBy
my @r21 = LTSV::LINQ->From(\@users)->GroupJoin(
    LTSV::LINQ->From(\@orders),
    sub { $_[0]{id} },
    sub { $_[0]{user_id} },
    sub { my($u, $g) = @_; return { name => $u->{name}, count => $g->Count() }; }
)->OrderByDescending(sub { $_[0]{count} })->ToArray();
ok($r21[0]{count} >= $r21[1]{count}, 'GroupJoin + OrderByDescending');

# Test 22: GroupJoin + Count terminal
my $total_users_with_orders = LTSV::LINQ->From(\@users)->GroupJoin(
    LTSV::LINQ->From(\@orders),
    sub { $_[0]{id} },
    sub { $_[0]{user_id} },
    sub { my($u, $g) = @_; return $g->Any() ? 1 : 0; }
)->Sum(sub { $_[0] });
ok($total_users_with_orders == 2, 'GroupJoin + Sum: count users with orders');

#---------------------------------------------------------------------
# Lazy evaluation of outer sequence
#---------------------------------------------------------------------

# Test 23: outer is processed lazily (Take stops after 2)
my $outer_count = 0;
my @r23 = LTSV::LINQ->From(\@users)->Select(sub {
    $outer_count++;
    return $_[0];
})->GroupJoin(
    LTSV::LINQ->From(\@orders),
    sub { $_[0]{id} },
    sub { $_[0]{user_id} },
    sub { my($u, $g) = @_; return { name => $u->{name} }; }
)->Take(2)->ToArray();
ok(@r23 == 2 && $outer_count == 2, 'GroupJoin: outer is lazy (Take(2) processes only 2)');

#---------------------------------------------------------------------
# Inner group is a proper LTSV::LINQ object
#---------------------------------------------------------------------

# Test 24: inner group is a LTSV::LINQ object (isa check)
my $group_is_linq = 0;
LTSV::LINQ->From(\@users)->GroupJoin(
    LTSV::LINQ->From(\@orders),
    sub { $_[0]{id} },
    sub { $_[0]{user_id} },
    sub {
        my($u, $g) = @_;
        $group_is_linq = 1 if ref($g) && $g->isa('LTSV::LINQ');
        return { name => $u->{name} };
    }
)->ToArray();
ok($group_is_linq, 'GroupJoin: inner_group is a LTSV::LINQ object');

# Test 25: inner group ToArray returns correct data
my @r25_inner;
LTSV::LINQ->From([{id => 1}])->GroupJoin(
    LTSV::LINQ->From(\@orders),
    sub { $_[0]{id} },
    sub { $_[0]{user_id} },
    sub {
        my($u, $g) = @_;
        @r25_inner = $g->ToArray();
        return $u;
    }
)->ToArray();
ok(@r25_inner == 2 && $r25_inner[0]{product} eq 'Book',
   'GroupJoin: inner_group ToArray returns correct items');

#---------------------------------------------------------------------
# undef key handling
#---------------------------------------------------------------------

# Test 26: undef key treated as empty string
my @undef_outer = ({id => undef, name => 'X'});
my @undef_inner = ({user_id => undef, product => 'Y'});
my @r26 = LTSV::LINQ->From(\@undef_outer)->GroupJoin(
    LTSV::LINQ->From(\@undef_inner),
    sub { $_[0]{id} },
    sub { $_[0]{user_id} },
    sub { my($u, $g) = @_; return { name => $u->{name}, count => $g->Count() }; }
)->ToArray();
ok($r26[0]{count} == 1, 'GroupJoin: undef key matches undef key');

#---------------------------------------------------------------------
# Hash-ref key handling
#---------------------------------------------------------------------

# Test 27: hash-ref key (via _make_key) - keys extracted as scalars normally
# (This tests that _make_key is NOT called when key is already scalar)
my @r27 = LTSV::LINQ->From([{k => 'a'}, {k => 'b'}])->GroupJoin(
    LTSV::LINQ->From([{fk => 'a', v => 1}, {fk => 'a', v => 2}]),
    sub { $_[0]{k} },
    sub { $_[0]{fk} },
    sub { my($o, $g) = @_; return { k => $o->{k}, count => $g->Count() }; }
)->ToArray();
ok($r27[0]{count} == 2 && $r27[1]{count} == 0,
   'GroupJoin: scalar hash field keys work correctly');

#---------------------------------------------------------------------
# Compare with Join
#---------------------------------------------------------------------

# Test 28: GroupJoin includes unmatched outer (left outer), Join does not
my @g_result = LTSV::LINQ->From(\@users)->GroupJoin(
    LTSV::LINQ->From(\@orders),
    sub { $_[0]{id} },
    sub { $_[0]{user_id} },
    sub { my($u, $g) = @_; return { name => $u->{name}, count => $g->Count() }; }
)->ToArray();

my @j_result = LTSV::LINQ->From(\@users)->Join(
    LTSV::LINQ->From(\@orders),
    sub { $_[0]{id} },
    sub { $_[0]{user_id} },
    sub { my($u, $o) = @_; return $u->{name}; }
)->ToArray();

ok(@g_result == 3 && @j_result == 3,
   'GroupJoin has 3 rows (including Carol), Join also has 3 rows (matching only)');

# Test 29: GroupJoin includes unmatched outer (left outer), present with 0 orders
ok($g_result[2]{name} eq 'Carol',
   'GroupJoin: Carol present with 0 orders');

#---------------------------------------------------------------------
# Inner group: All() and First()
#---------------------------------------------------------------------

# Test 30: All() on inner group
my @r30 = LTSV::LINQ->From(\@users)->GroupJoin(
    LTSV::LINQ->From(\@orders),
    sub { $_[0]{id} },
    sub { $_[0]{user_id} },
    sub {
        my($u, $g) = @_;
        my $all_big = $g->Any() ? ($g->All(sub { $_[0]{amount} >= 5 }) ? 1 : 0) : 0;
        return { name => $u->{name}, all_big => $all_big };
    }
)->ToArray();
ok($r30[0]{all_big} == 1, 'GroupJoin: All() on inner_group (Alice: all >= 5)');

# Test 31: First() on inner group
my @r31 = LTSV::LINQ->From([{id => 1}])->GroupJoin(
    LTSV::LINQ->From(\@orders),
    sub { $_[0]{id} },
    sub { $_[0]{user_id} },
    sub {
        my($u, $g) = @_;
        my $first = $g->First();
        return { product => $first->{product} };
    }
)->ToArray();
ok($r31[0]{product} eq 'Book', 'GroupJoin: First() on inner_group');

#---------------------------------------------------------------------
# Combined: GroupJoin then flatten (simulating SelectMany-like)
#---------------------------------------------------------------------

# Test 32: Flatten groups back to rows via Select+multiple returns
my @r32 = LTSV::LINQ->From(\@users)->GroupJoin(
    LTSV::LINQ->From(\@orders),
    sub { $_[0]{id} },
    sub { $_[0]{user_id} },
    sub {
        my($u, $g) = @_;
        my @prods = $g->Select(sub{ $_[0]{product} })->ToArray();
        return { name => $u->{name}, products => \@prods };
    }
)->ToArray();
ok(@{$r32[0]{products}} == 2, 'GroupJoin: inner Select + ToArray in result_selector');

#---------------------------------------------------------------------
# Aggregate on inner group
#---------------------------------------------------------------------

# Test 33: Aggregate on inner group
my @r33 = LTSV::LINQ->From([{id => 1}])->GroupJoin(
    LTSV::LINQ->From(\@orders),
    sub { $_[0]{id} },
    sub { $_[0]{user_id} },
    sub {
        my($u, $g) = @_;
        my $products = $g->Aggregate('', sub {
            my($acc, $item) = @_;
            return ($acc eq '' ? '' : $acc . ',') . $item->{product};
        });
        return { products => $products };
    }
)->ToArray();
ok($r33[0]{products} eq 'Book,Pen', 'GroupJoin: Aggregate on inner_group');

#---------------------------------------------------------------------
# LTSV data (real-world-like)
#---------------------------------------------------------------------

# Test 34: GroupJoin with LTSV-style data
my @access_log = (
    {host => '127.0.0.1', path => '/api/users', status => '200'},
    {host => '10.0.0.1',  path => '/api/items',  status => '200'},
    {host => '127.0.0.1', path => '/api/login',  status => '401'},
);
my @error_log = (
    {host => '127.0.0.1', message => 'auth failed'},
);

my @r34 = LTSV::LINQ->From(\@access_log)->GroupJoin(
    LTSV::LINQ->From(\@error_log),
    sub { $_[0]{host} },
    sub { $_[0]{host} },
    sub {
        my($req, $errors) = @_;
        return { path => $req->{path}, error_count => $errors->Count() };
    }
)->ToArray();
ok($r34[0]{error_count} == 1 && $r34[1]{error_count} == 0,
   'GroupJoin: LTSV-style logs joined by host');

#---------------------------------------------------------------------
# Chaining two GroupJoin calls
#---------------------------------------------------------------------

# Test 35: Nested information (departments -> users -> orders)
my @depts = ({dept => 'Eng'}, {dept => 'Sales'});
my @dept_users = (
    {dept => 'Eng',   uid => 1},
    {dept => 'Eng',   uid => 2},
    {dept => 'Sales', uid => 3},
);

my @r35 = LTSV::LINQ->From(\@depts)->GroupJoin(
    LTSV::LINQ->From(\@dept_users),
    sub { $_[0]{dept} },
    sub { $_[0]{dept} },
    sub {
        my($dept, $members) = @_;
        return { dept => $dept->{dept}, members => $members->Count() };
    }
)->ToArray();
ok($r35[0]{members} == 2 && $r35[1]{members} == 1,
   'GroupJoin: nested department -> members count');


exit($FAIL ? 1 : 0);
