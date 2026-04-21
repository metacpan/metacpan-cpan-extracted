######################################################################
#
# 0004-grouping.t - GroupBy, ToLookup, GroupJoin, SelectMany tests
#
######################################################################

use strict;
BEGIN { if ($] < 5.006) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";
use JSON::LINQ;

my ($PASS, $FAIL, $T) = (0, 0, 0);
sub ok { my($c,$n)=@_; $T++; $c ? ($PASS++, print "ok $T - $n\n") : ($FAIL++, print "not ok $T - $n\n") }

my @users = (
    {id => 1, name => 'Alice', dept => 'Eng'},
    {id => 2, name => 'Bob',   dept => 'Sales'},
    {id => 3, name => 'Carol', dept => 'Eng'},
    {id => 4, name => 'Dave',  dept => 'HR'},
);
my @orders = (
    {user_id => 1, product => 'Book',     amount => 15},
    {user_id => 1, product => 'Pen',      amount => 5},
    {user_id => 2, product => 'Notebook', amount => 20},
    {user_id => 3, product => 'Laptop',   amount => 1200},
);

my @tests = (
    # 1: GroupBy group count
    sub {
        my @g = JSON::LINQ->From(\@users)->GroupBy(sub { $_[0]{dept} })->ToArray();
        ok(@g == 3, 'GroupBy: correct group count');
    },

    # 2: GroupBy group sizes
    sub {
        my @g = JSON::LINQ->From(\@users)->GroupBy(sub { $_[0]{dept} })->ToArray();
        my %m = map { $_->{Key} => scalar(@{$_->{Elements}}) } @g;
        ok($m{Eng} == 2 && $m{Sales} == 1 && $m{HR} == 1, 'GroupBy: group sizes correct');
    },

    # 3: GroupBy element selector
    sub {
        my @g = JSON::LINQ->From(\@users)
            ->GroupBy(sub { $_[0]{dept} }, sub { $_[0]{name} })->ToArray();
        my %ng = map { $_->{Key} => $_->{Elements} } @g;
        my ($alice, $carol) = (0, 0);
        for my $n (@{$ng{Eng}}) { $alice = 1 if $n eq 'Alice'; $carol = 1 if $n eq 'Carol' }
        ok($alice && $carol, 'GroupBy element selector: names extracted');
    },

    # 4: ToLookup returns hashref
    sub {
        my $l = JSON::LINQ->From(\@users)->ToLookup(sub { $_[0]{dept} }, sub { $_[0]{name} });
        ok(ref($l) eq 'HASH', 'ToLookup returns hashref');
    },

    # 5: ToLookup Eng count
    sub {
        my $l = JSON::LINQ->From(\@users)->ToLookup(sub { $_[0]{dept} }, sub { $_[0]{name} });
        ok(scalar(@{$l->{Eng}}) == 2, 'ToLookup: Eng has 2 members');
    },

    # 6: ToDictionary
    sub {
        my $d = JSON::LINQ->From(\@users)->ToDictionary(sub { $_[0]{id} }, sub { $_[0]{name} });
        ok($d->{1} eq 'Alice' && $d->{3} eq 'Carol', 'ToDictionary: correct key->value');
    },

    # 7: Join result count
    sub {
        my @j = JSON::LINQ->From(\@users)->Join(
            JSON::LINQ->From(\@orders),
            sub { $_[0]{id} }, sub { $_[0]{user_id} },
            sub { my($u,$o)=@_; {name=>$u->{name},product=>$o->{product}} }
        )->ToArray();
        ok(@j == 4, 'Join: correct result count');
    },

    # 8: Join Alice orders
    sub {
        my @j = JSON::LINQ->From(\@users)->Join(
            JSON::LINQ->From(\@orders),
            sub { $_[0]{id} }, sub { $_[0]{user_id} },
            sub { my($u,$o)=@_; {name=>$u->{name},product=>$o->{product}} }
        )->ToArray();
        my @alice = grep { $_->{name} eq 'Alice' } @j;
        ok(@alice == 2, 'Join: Alice has 2 orders');
    },

    # 9: GroupJoin all outer elements
    sub {
        my @gj = JSON::LINQ->From(\@users)->GroupJoin(
            JSON::LINQ->From(\@orders),
            sub { $_[0]{id} }, sub { $_[0]{user_id} },
            sub { my($u,$g)=@_; {name=>$u->{name},count=>$g->Count()} }
        )->ToArray();
        ok(@gj == 4, 'GroupJoin: all outer elements present');
    },

    # 10: GroupJoin Dave = 0
    sub {
        my @gj = JSON::LINQ->From(\@users)->GroupJoin(
            JSON::LINQ->From(\@orders),
            sub { $_[0]{id} }, sub { $_[0]{user_id} },
            sub { my($u,$g)=@_; {name=>$u->{name},count=>$g->Count()} }
        )->ToArray();
        my %m = map { $_->{name} => $_->{count} } @gj;
        ok($m{Dave} == 0, 'GroupJoin: Dave has 0 orders');
    },

    # 11: GroupJoin Alice = 2
    sub {
        my @gj = JSON::LINQ->From(\@users)->GroupJoin(
            JSON::LINQ->From(\@orders),
            sub { $_[0]{id} }, sub { $_[0]{user_id} },
            sub { my($u,$g)=@_; {name=>$u->{name},count=>$g->Count()} }
        )->ToArray();
        my %m = map { $_->{name} => $_->{count} } @gj;
        ok($m{Alice} == 2, 'GroupJoin: Alice has 2 orders');
    },

    # 12: GroupJoin Sum
    sub {
        my @wt = JSON::LINQ->From(\@users)->GroupJoin(
            JSON::LINQ->From(\@orders),
            sub { $_[0]{id} }, sub { $_[0]{user_id} },
            sub { my($u,$g)=@_; {name=>$u->{name},total=>$g->Sum(sub{$_[0]{amount}})} }
        )->ToArray();
        my %t = map { $_->{name} => $_->{total} } @wt;
        ok($t{Alice} == 20 && $t{Carol} == 1200, 'GroupJoin Sum: correct totals');
    },

    # 13: SelectMany count
    sub {
        my @td = (
            {name=>'p1', tags=>['perl','json']},
            {name=>'p2', tags=>['python']},
            {name=>'p3', tags=>['perl','linq']},
        );
        my @all = JSON::LINQ->From(\@td)->SelectMany(sub { $_[0]{tags} })->ToArray();
        ok(@all == 5, 'SelectMany: flattens tags correctly');
    },

    # 14: SelectMany + Distinct
    sub {
        my @td = (
            {name=>'p1', tags=>['perl','json']},
            {name=>'p2', tags=>['python']},
            {name=>'p3', tags=>['perl','linq']},
        );
        my @u = JSON::LINQ->From(\@td)->SelectMany(sub { $_[0]{tags} })->Distinct()->ToArray();
        ok(@u == 4, 'SelectMany + Distinct: 4 unique tags');
    },

    # 15: GroupBy from FromJSONString
    sub {
        my $json = '[{"g":"x","v":1},{"g":"y","v":2},{"g":"x","v":3}]';
        my @r = JSON::LINQ->FromJSONString($json)
            ->GroupBy(sub { $_[0]{g} })
            ->Select(sub { {k=>$_[0]{Key}, n=>scalar(@{$_[0]{Elements}})} })
            ->ToArray();
        my %rv = map { $_->{k} => $_->{n} } @r;
        ok($rv{x} == 2 && $rv{y} == 1, 'GroupBy from FromJSONString');
    },
);

print "1.." . scalar(@tests) . "\n";
$_->() for @tests;
END { print "# $PASS passed, $FAIL failed out of $T\n" }
