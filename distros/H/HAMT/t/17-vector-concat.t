#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr blessed);
use HAMT::Vector;

# concat, at every pair of the lengths where a vector's shape changes, against
# (@a, @b).

my @len = (0, 1, 2, 31, 32, 33, 63, 64, 65, 1023, 1024, 1025, 1056, 1057, 1089, 2080, 32768, 32801);
my %vec = map { ($_ => HAMT::Vector->new(map { "a$_" } 0 .. $_ - 1)) } @len;
my %oth = map { ($_ => HAMT::Vector->new(map { "b$_" } 0 .. $_ - 1)) } @len;

sub agrees {
    my ($v, $want) = @_;
    return 0 unless $v->count == @$want && $v->_check == 0;
    return join("\0", $v->list) eq join("\0", @$want) if @$want <= 3000;
    for my $i (0, 1, 31, 32, 33, 1023, 1024, 1025, int(@$want / 2), $#$want - 33, $#$want - 1, $#$want) {
        next if $i < 0 || $i > $#$want;
        return 0 unless $v->get($i) eq $want->[$i];
    }
    return 1;
}

my ($bad, $pairs) = (undef, 0);
PAIR: for my $i (@len) {
    my @a = map { "a$_" } 0 .. $i - 1;
    for my $j (@len) {
        my @want = (@a, map { "b$_" } 0 .. $j - 1);
        my $r = $vec{$i}->concat($oth{$j});
        $pairs++;
        $bad = "$i and $j: the result" unless agrees($r, \@want);
        # The seam itself, value by value.
        if (!$bad && $i && $j) {
            for my $k ($i - 2 .. $i + 1) {
                next if $k < 0 || $k > $#want;
                $bad ||= "$i and $j: index $k at the seam" unless $r->get($k) eq $want[$k];
            }
        }
        $bad ||= "$i and $j: the receiver moved" if $vec{$i}->count != $i || ($i && $vec{$i}->last ne 'a' . ($i - 1));
        $bad ||= "$i and $j: the other moved"    if $oth{$j}->count != $j || ($j && $oth{$j}->first ne 'b0');
        last PAIR if $bad;
    }
}
ok(!$bad, "all $pairs pairs of " . @len . ' lengths joined: right values, valid, operands unchanged') or diag($bad);

# ---- answers that are one of the operands -----------------------------------
{
    my $v = $vec{1057};
    my $e = HAMT::Vector->new;
    is(refaddr($v->concat($e)), refaddr($v), 'joining an empty vector on is the receiver');
    is(refaddr($e->concat($v)), refaddr($v), 'joining onto an empty vector is the other vector');
    is($e->concat($e)->count, 0, 'two empty vectors join to an empty one');
    isnt(refaddr($v->concat($v)), refaddr($v), 'a vector joined to itself is a new vector');
    is($v->concat($v)->count, 2114, 'twice as long');
    is($v->concat($v)->get(1057), 'a0', 'starting again at its seam');

    {
        package Local::Seq; our @ISA = ('HAMT::Vector');
    }
    my $s = Local::Seq->new(1, 2);
    isa_ok($s->concat($v), 'Local::Seq', 'the result is of the receiver\'s class');
    my $from_empty = Local::Seq->new->concat($v);
    is(blessed($from_empty), 'Local::Seq', 'even when it is exactly the other vector, which is of another class');
    ok($from_empty->equals($v), 'holding the same values');
    is(blessed($v->concat($s)), 'HAMT::Vector', 'and the other way round');
}

# ---- many joins -----------------------------------------------------------------
{
    my $v = HAMT::Vector->new;
    my @a;
    for my $i (1 .. 600) {
        my @run = map { "r$i.$_" } 1 .. ($i % 7) + 1;
        if ($i % 3) { $v = $v->concat(HAMT::Vector->new(@run)); push @a, @run }
        else        { $v = HAMT::Vector->new(@run)->concat($v); unshift @a, @run }
    }
    ok(agrees($v, \@a), '600 short runs joined on at one end or the other');
    is(join("\0", $v->list), join("\0", @a), 'value for value');

    my $doubling = HAMT::Vector->new('x');
    $doubling = $doubling->concat($doubling) for 1 .. 17;
    is($doubling->count, 131_072, 'a vector joined to itself seventeen times is 131,072 long');
    is($doubling->_check, 0, 'and valid');
    is($doubling->get(131_071), 'x', 'to its last value');
}

# ---- what a joined vector can then do ---------------------------------------------
{
    my @a = (map({ "a$_" } 0 .. 1056), map({ "b$_" } 0 .. 32));
    my $j = $vec{1057}->concat($oth{33});
    my $p = $j->push('p1', 'p2');
    is($p->count, 1092, 'a joined vector can be pushed to');
    is($p->last, 'p2', 'at its end');
    is($p->_check, 0, 'and stays valid');
    is($j->set(1056, 'S')->get(1056), 'S', 'set just before the seam');
    is($j->set(1057, 'S')->get(1057), 'S', 'and just after it');
    is($j->set(1057, 'S')->get(1056), 'a1056', 'without disturbing its neighbour');
    my $q = $j;
    $q = $q->pop for 1 .. 40;
    ok(agrees($q, [ @a[0 .. $#a - 40] ]), 'popped back across the seam');
    my @seen;
    $j->each(sub { push @seen, $_[1] if $_[0] ne $a[ $_[1] ] });
    is(scalar @seen, 0, 'each walks it in order with the right indexes');
    is_deeply($j->to_array, \@a, 'to_array copies it in order');
    my $t = $j->transient;
    $t->push('t')->set(0, 'T')->pop->pop;
    ok(agrees($t->persistent, [ 'T', @a[1 .. $#a - 1] ]), 'and a transient opened on it works');
    ok($j->equals(HAMT::Vector->new(@a)), 'it equals a vector of the same values built by pushing');
    ok(HAMT::Vector->new(@a)->equals($j), 'either way round, though their leaves do not line up');
    ok(!$j->equals(HAMT::Vector->new(@a)->set(1057, 'x')), 'and not one that differs at the seam');
}

# ---- errors, void context -------------------------------------------------------------
ok(!eval { my $r = $vec{1}->concat([1]); 1 } && $@ =~ /^HAMT::Vector::concat: not a vector/, 'concat refuses an array');
ok(!eval { my $r = $vec{1}->concat(undef); 1 } && $@ =~ /^HAMT::Vector::concat: not a vector/, 'and undef');
{
    my @w;
    local $SIG{__WARN__} = sub { push @w, $_[0] };
    $vec{1}->concat($vec{2});
    is(scalar @w, 1, 'concat warns in void context');
    like($w[0], qr/^Useless use of HAMT::Vector::concat in void context/, 'by name');
}

done_testing;
