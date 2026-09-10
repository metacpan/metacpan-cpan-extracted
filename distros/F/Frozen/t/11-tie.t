#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Frozen ();

# The second door. Same registry, same answers, different cost.

my %cat = (
    greeting => 'Hello',
    items    => { one => '1 item', other => '{count} items',
                  deeper => { down => 'here' } },
    list     => ['a', 'b', { inner => 'x' }],
    nothing  => undef,
    n        => 7,
);
my $fz = Frozen->attach(Frozen->freeze(\%cat));

# ---- a hashref that behaves like one --------------------------------------

my $h = $fz->tied;
is(ref $h, 'HASH', 'tied() gives a plain hashref');

is($h->{greeting}, 'Hello', 'FETCH on a leaf');
ok(!defined $h->{nope},     'FETCH on an absent key is undef');
ok(!defined $h->{nothing},  'and a stored undef is undef too');

ok(exists $h->{nothing}, 'EXISTS tells the two apart where FETCH cannot');
ok(!exists $h->{nope},   'and says no for an absent key');

# ---- a branch FETCHes as another tied view -------------------------------
#
# This is what makes {% locale.items.one %} resolve a segment at a time.

is(ref $h->{items}, 'HASH', 'a branch FETCHes as a hashref');
is($h->{items}{one}, '1 item', 'which itself fetches');
is($h->{items}{deeper}{down}, 'here', 'and descends again');

# ---- arrays ---------------------------------------------------------------

is(ref $h->{list}, 'ARRAY', 'an array branch FETCHes as an arrayref');
is(scalar @{ $h->{list} }, 3, 'FETCHSIZE');
is($h->{list}[0], 'a', 'FETCH by index');
is($h->{list}[2]{inner}, 'x', 'and a hash inside an array');

# ---- iteration ------------------------------------------------------------

{
    my @k1 = sort keys %$h;
    my @k2 = sort keys %$h;
    is_deeply(\@k1, \@k2, 'keys are stable across two iterations');
    is_deeply(\@k1, [sort keys %cat], 'and are all of them');

    my $n = 0;
    while (my ($k, $v) = each %$h) { $n++ }
    is($n, scalar keys %cat, 'each() walks every pair exactly once');

    is(scalar(%$h) ? 1 : 0, 1, 'SCALAR is true for a non-empty hash');
}

# ---- the refusals, which explain rather than merely refuse ---------------

{
    eval { $h->{greeting} = 'nope'; 1 };
    like($@, qr/read-only/, 'STORE croaks');
    like($@, qr/private copy|Rebuild/,
         '...and the message says WHY, naming the failure Frozen prevents');

    eval { delete $h->{greeting}; 1 };
    like($@, qr/read-only/, 'DELETE croaks');

    eval { %$h = (); 1 };
    like($@, qr/read-only/, 'CLEAR croaks');

    eval { $h->{list}[0] = 'nope'; 1 };
    like($@, qr/read-only/, 'array STORE croaks');

    eval { push @{ $h->{list} }, 'nope'; 1 };
    like($@, qr/read-only/, 'PUSH croaks');
}

# ---- a tied view outlives the lexical it came from -----------------------
#
# It holds its container by reference, which is what lets a template be handed
# one and used later.

{
    my $view;
    {
        my $inner = Frozen->attach(Frozen->freeze({ k => 'v' }));
        $view = $inner->tied;
    }
    is($view->{k}, 'v', 'a tied view keeps its block alive');
}

# ---- both doors agree -----------------------------------------------------
#
# Two lookup paths that could disagree about what is missing would be a bug
# waiting for a Tuesday, so this asserts they do not.

{
    my $root = $fz->root;
    for my $k (qw(greeting nothing nope items)) {
        my $tied_has = exists $h->{$k} ? 1 : 0;
        my $fast_has = $fz->exists($root, $k) ? 1 : 0;
        is($tied_has, $fast_has, "both doors agree on '$k'");
    }
}

done_testing;
