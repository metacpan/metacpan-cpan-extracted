#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr readonly);
use HAMT::Map;

# each: every pair once, in the order keys gives, and safe against whatever
# the callback does - dying, changing the map, dropping the map.

{
    package Local::Counted;
    our %alive; our $made = 0;
    sub new { my $o = bless { id => ++$made }, shift; $alive{ $o->{id} } = 1; $o }
    sub DESTROY { delete $alive{ $_[0]{id} } }
}
sub alive { scalar keys %Local::Counted::alive }

my %src = map { ("key$_" => $_) } 1 .. 300;
my $m = HAMT::Map->new(%src);

# ---- every pair, once, in order ----------------------------------------------
{
    my (@seen, %got);
    my $ret = $m->each(sub { push @seen, $_[0]; $got{ $_[0] } = $_[1]; return });
    is(refaddr($ret), refaddr($m), 'each returns the map');
    is(scalar @seen, 300, 'the sub ran once for each pair');
    is_deeply(\%got, \%src, 'with every key and its value');
    is_deeply(\@seen, [ $m->keys ], 'in the order keys gives');
}
{
    my $calls = 0;
    HAMT::Map->new->each(sub { $calls++ });
    is($calls, 0, 'an empty map calls nothing');
    my @args;
    HAMT::Map->new(k => undef)->each(sub { @args = @_ });
    is(scalar @args, 2, 'the sub gets two arguments');
    is($args[0], 'k', 'the key');
    is($args[1], undef, 'and the value, undef when that is what is stored');
}

# ---- what the sub is handed ---------------------------------------------------
{
    my $one = HAMT::Map->new(k => 'stored');
    my ($key_ro, $val_ro);
    $one->each(sub { $key_ro = readonly($_[0]); $val_ro = readonly($_[1]) });
    ok($val_ro, 'the value is the stored, read-only scalar');
    ok(!eval { $one->each(sub { $_[1] = 'poked' }); 1 }, 'so writing to it dies');
    like($@, qr/Modification of a read-only value/, "with perl's own message");
    is($one->get('k'), 'stored', 'and the map is unchanged');
    ok(eval { $one->each(sub { $_[0] = 'renamed' }); 1 }, 'the key is a fresh scalar, writable');
    ok($one->exists('k') && !$one->exists('renamed'), 'and writing to it renames nothing');
}
{
    my $wide = HAMT::Map->new(chr(0x100) => 1, chr(0xe9) => 2);
    my @k;
    $wide->each(sub { push @k, $_[0] });
    is_deeply([ sort @k ], [ sort chr(0x100), chr(0xe9) ], 'keys come back as characters');
}

# ---- the key is the sub's to keep ----------------------------------------------
#
# A walk writes each key into one scalar rather than making a new one each
# time, unless the sub kept hold of the last. So a sub that keeps a
# REFERENCE to its key must still end up with as many different scalars as
# there were keys, each holding its own.
{
    my (@refs, @copies);
    $m->each(sub { push @refs, \$_[0]; push @copies, $_[0] });
    is(scalar @refs, 300, 'a sub that keeps a reference to every key keeps 300 of them');
    is_deeply([ map { $$_ } @refs ], \@copies, 'each still holding the key it was called with');
    my %distinct = map { (0 + $_ => 1) } @refs;
    is(scalar keys %distinct, 300, 'in 300 different scalars');

    my (@some, @all);
    $m->each(sub { push @all, $_[0]; push @some, \$_[0] if @all % 7 == 0 });
    is_deeply([ map { $$_ } @some ], [ @all[ grep { ($_ + 1) % 7 == 0 } 0 .. $#all ] ],
              'a sub that keeps only some of them keeps the right ones');

    my @seen;
    $m->each(sub { push @seen, $_[0]; $_[0] = 'scribbled over'; });
    is_deeply(\@seen, [ $m->keys ], 'writing over the key in one call does not change what the next is given');
    my $wide = HAMT::Map->new(chr(0x100) => 1, plain => 2, chr(0x101) => 3);
    my @flags;
    $wide->each(sub { push @flags, [ $_[0], utf8::is_utf8($_[0]) ? 1 : 0 ] });
    is_deeply([ sort { $a->[0] cmp $b->[0] } @flags ], [ [ 'plain', 0 ], [ chr(0x100), 1 ], [ chr(0x101), 1 ] ],
              'and a wide key before a plain one does not leave the plain one flagged as wide');
    my @tied;
    $m->each(sub { push @tied, $_[0]; tie $_[0], 'Local::Loud' if @tied == 1 });
    is_deeply(\@tied, [ $m->keys ], 'nor does a sub that ties its key change what the rest are given');
}
{
    package Local::Loud;
    sub TIESCALAR { bless [], shift }
    sub FETCH { 'tied' }
    sub STORE { }
}

# ---- a sub that dies ----------------------------------------------------------
{
    my $calls = 0;
    ok(!eval { $m->each(sub { die "stop\n" if ++$calls == 50 }); 1 }, 'a die in the sub propagates');
    is($@, "stop\n", 'unchanged');
    is($calls, 50, 'and stops the walk there');
    is($m->count, 300, 'the map is still usable');
    is($m->_check, 0, 'and checks out');
    my $again = 0;
    $m->each(sub { $again++ });
    is($again, 300, 'and can be walked again in full');
}
{
    my $before = alive();
    {
        my $held = HAMT::Map->new(map { ("k$_" => Local::Counted->new) } 1 .. 50);
        eval { $held->each(sub { die "stop\n" }) };
        eval { $held->each(sub { die "stop\n" }) } for 1 .. 20;
    }
    is(alive(), $before, 'a walk that dies leaks nothing, twenty-one times over');
}

# ---- a sub that changes the map -------------------------------------------------
{
    my $walked = $m;
    my $calls = 0;
    $m->each(sub {
        $walked = $walked->set("added$calls" => 1)->delete($_[0]);
        $calls++;
    });
    is($calls, 300, 'updating the map inside the walk does not disturb the walk');
    is($m->count, 300, 'the map being walked is unchanged');
    is($walked->count, 300, 'and the updates went to new maps');
    ok(!$walked->exists('key1') && $walked->exists('added0'), 'which hold what was done');
}

# ---- a sub that drops the map ---------------------------------------------------
{
    my $before = alive();
    my $doomed = HAMT::Map->new(map { ("k$_" => Local::Counted->new) } 1 .. 100);
    my ($calls, $alive_during) = (0, 0);
    $doomed->each(sub {
        undef $doomed if $calls++ == 0;
        $alive_during = alive() - $before if $calls == 60;
    });
    is($calls, 100, 'the walk finishes over a map its own sub let go of');
    is($alive_during, 100, 'whose values were all still alive in the middle of it');
    is(alive(), $before, 'and are gone once it ends');
}

# ---- mortals do not pile up -----------------------------------------------------
{
    my $big = HAMT::Map->new(map { ("k$_" => $_) } 1 .. 2000);
    my $before = alive();
    my $peak = 0;
    $big->each(sub {
        my $tmp = Local::Counted->new;      # dies with this call's temporaries
        my $now = alive() - $before;
        $peak = $now if $now > $peak;
        return $tmp;                        # returned, so it is a temporary of the call
    });
    cmp_ok($peak, '<=', 2, 'a value returned by one call is gone before the next');

    # The key handed to each call is a temporary too, and a plain string, so
    # nothing destroys to say it was freed. Count perl's temporaries instead:
    # the same number at every call, not one more each time.
    my ($low, $high);
    $big->each(sub {
        my $t = HAMT::_tmps_ix();
        $low  = $t if !defined $low  || $t < $low;
        $high = $t if !defined $high || $t > $high;
    });
    cmp_ok($high - $low, '<=', 2, 'and 2,000 calls hold no more temporaries than one does')
        or diag("the count ran from $low to $high");

    my $next = $big->set(map { ("n$_" => $_) } 1 .. 2000);
    ($low, $high) = ();
    $big->diff($next, sub {
        my $t = HAMT::_tmps_ix();
        $low  = $t if !defined $low  || $t < $low;
        $high = $t if !defined $high || $t > $high;
    });
    cmp_ok($high - $low, '<=', 2, 'the same for the 2,000 calls of a diff');
}

# ---- errors ---------------------------------------------------------------------
ok(!eval { $m->each('not code'); 1 }, 'each refuses something that is not a sub');
like($@, qr/^HAMT::Map::each: not a code reference/, 'by name');
ok(!eval { $m->each([]); 1 }, 'including another kind of reference');

done_testing;
