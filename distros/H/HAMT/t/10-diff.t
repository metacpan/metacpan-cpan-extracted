#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use HAMT::Map;

# diff: what changed between two maps, checked against the same question
# asked of two hashes.

END { HAMT::_hash_bits(64) }

sub hash_diff {
    my ($a, $b) = @_;
    my %d;
    for my $k (keys %$a) {
        if (!exists $b->{$k}) { $d{$k} = [ 'remove', $a->{$k}, undef ] }
        elsif ((defined $a->{$k} ? $a->{$k} : "\0undef") ne (defined $b->{$k} ? $b->{$k} : "\0undef")) {
            $d{$k} = [ 'change', $a->{$k}, $b->{$k} ];
        }
    }
    $d{$_} = [ 'add', undef, $b->{$_} ] for grep { !exists $a->{$_} } keys %$b;
    return \%d;
}
sub map_diff {
    my ($a, $b) = @_;
    my (%d, $dups);
    my $n = $a->diff($b, sub { my ($k, $was, $now, $kind) = @_; $dups++ if $d{$k}; $d{$k} = [ $kind, $was, $now ] });
    return (\%d, $n, $dups);
}

for my $bits (64, 10, 5, 0) {
    HAMT::_hash_bits($bits);
    my $n = $bits ? 600 : 120;
    my %a = map { ("key$_" => "v$_") } 1 .. $n;
    my %b = map { ("key$_" => ($_ % 3 ? "v$_" : "w$_")) } $n / 2 .. $n + $n / 2;
    my $a = HAMT::Map->new(%a);
    my $b = HAMT::Map->new(%b);

    my ($d, $count, $dups) = map_diff($a, $b);
    is_deeply($d, hash_diff(\%a, \%b), "$bits bits: every difference, with its kind and both values");
    is($count, scalar keys %$d, "$bits bits: diff returns how many there were");
    ok(!$dups, "$bits bits: and no key is reported twice");

    my ($r) = map_diff($b, $a);
    is_deeply($r, hash_diff(\%b, \%a), "$bits bits: and the reverse the other way round");

    my ($none, $zero) = map_diff($a, HAMT::Map->new(reverse map { ($a{$_}, $_) } keys %a));
    is($zero, 0, "$bits bits: two equal maps built separately have no differences");

    undef $_ for $a, $b;
}
HAMT::_hash_bits(64);

my $a = HAMT::Map->new(map { ("key$_" => $_) } 1 .. 10_000);

# ---- one step apart ---------------------------------------------------------------
{
    my @calls;
    my $n = $a->diff($a->set(key5000 => 'changed'), sub { push @calls, [@_] });
    is($n, 1, 'two maps one value apart: one difference');
    is_deeply(\@calls, [ [ 'key5000', 5000, 'changed', 'change' ] ],
              'reported as the key, what it was, what it is, and "change"');

    @calls = ();
    $a->diff($a->set(brand_new => 1), sub { push @calls, [@_] });
    is_deeply(\@calls, [ [ 'brand_new', undef, 1, 'add' ] ], 'an added key');

    @calls = ();
    $a->diff($a->delete('key77'), sub { push @calls, [@_] });
    is_deeply(\@calls, [ [ 'key77', 77, undef, 'remove' ] ], 'a removed key');

    is($a->diff($a, sub { die "never called\n" }), 0, 'a map and itself: nothing, and the sub is never called');
    is($a->diff($a->set(key5 => 5), sub { die "never called\n" }), 0,
       'a value replaced by an equal one is not a difference');

    # The same question between two maps that share nothing CAN say more.
    my $apart = HAMT::Map->new(map { ("key$_" => $_ + 1) } 1 .. 10_000);
    is($a->diff($apart, sub { }), 10_000, 'two maps that agree on nothing: 10,000');
}

# ---- undef is a value ---------------------------------------------------------------
{
    my $x = HAMT::Map->new(k => 1, gone => 1, same => undef);
    my $y = HAMT::Map->new(k => undef, came => undef, same => undef);
    my ($d) = map_diff($x, $y);
    is_deeply($d, {
        k    => [ 'change', 1, undef ],
        gone => [ 'remove', 1, undef ],
        came => [ 'add', undef, undef ],
    }, 'a value changed to undef, a key removed and a key added holding undef are told apart by kind');
}

# ---- empty maps ------------------------------------------------------------------------
{
    my $empty = HAMT::Map->new;
    my $three = HAMT::Map->new(a => 1, b => 2, c => 3);
    my ($d, $n) = map_diff($empty, $three);
    is($n, 3, 'everything in a map is an addition to an empty one');
    is_deeply([ sort map { $_->[0] } values %$d ], [ ('add') x 3 ], 'all three adds');
    ($d, $n) = map_diff($three, $empty);
    is_deeply([ sort map { $_->[0] } values %$d ], [ ('remove') x 3 ], 'and a removal the other way');
    is($empty->diff($empty, sub { }), 0, 'two empty maps do not differ');
}

# ---- the sub ------------------------------------------------------------------------------
{
    my $next = $a->set(x => 1, y => 2, z => 3);
    my $calls = 0;
    ok(!eval { $a->diff($next, sub { die "stop\n" if ++$calls == 2 }); 1 }, 'a die in the sub propagates');
    is($@, "stop\n", 'unchanged');
    is($calls, 2, 'and stops the walk');
    is($a->count, 10_000, 'the map is still usable');

    ok(!eval { $a->diff($next, sub { $_[1] = 'poked' if defined $_[1]; $_[2] = 'poked' }); 1 },
       'the values it is handed are read-only');
    is($next->get('x'), 1, 'so neither map can be changed through them');

    my $walked = $a;
    $a->diff($next, sub { $walked = $walked->set($_[0] => $_[2]) });
    ok($walked->equals($next), 'replaying the differences onto the first map makes the second');

    ok(!eval { $a->diff($next, 'x'); 1 }, 'diff refuses something that is not a sub');
    like($@, qr/^HAMT::Map::diff: not a code reference/, 'by name');
    ok(!eval { $a->diff({}, sub { }); 1 }, 'and something that is not a map');
    like($@, qr/^HAMT::Map::diff: not a map/, 'by name');

    my @w;
    local $SIG{__WARN__} = sub { push @w, @_ };
    $a->diff($next, sub { });
    $a->each(sub { }) if 0;
    is(scalar @w, 0, 'diff in void context does not warn: the sub is the point');
}

done_testing;
