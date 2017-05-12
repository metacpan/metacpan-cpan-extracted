# 01-method.t
#
# Test suite for Integer::Partition
# Test the module methods
#
# copyright (C) 2007 David Landgren

use strict;

eval qq{use Test::More tests => 453};
if( $@ ) {
    warn "# Test::More not available, no tests performed\n";
    print "1..1\nok 1\n";
    exit 0;
}

use Integer::Partition;

my $Unchanged = 'The scalar remains the same';
$_ = $Unchanged;

{
    my $s = Integer::Partition->new(1);
    my $p = $s->next;
    is_deeply( $p, [1], 'partition of 1' );
    $p = $s->next;
    ok( !defined($p), '...exhausted');

    $s->reset;
    $p = $s->next;
    is_deeply( $p, [1], 'partition of 1 after reset' );

    $s = Integer::Partition->new(1, {lexicographic => 1});
    $p = $s->next;
    is_deeply( $p, [1], 'partition of 1 ZS2' );
    $p = $s->next;
    ok( !defined($p), '...exhausted ZS2');
}

local $/ = "\n\n";

while (defined(my $set = <DATA>)) {
    chomp;
    my @array = map {[split]} split /\n/, $set;
    my $lim = @array;
    my $n = $array[0]->[0];
    my $zs1 = Integer::Partition->new($n);
    my $zs2 = Integer::Partition->new($n, {lexicographic => 1});
    my $p;

    for (my $idx = 0; $idx < $lim; ++$idx) {
        my $sum = 0;
        $sum += $_ for @{$array[$idx]};
        is($sum, $n, "sum $idx of $n");
        $p = $zs1->next;
        is_deeply($p, $array[$idx], "zs1($n:$idx) @{$array[$idx]}");
        $p = $zs2->next;
        is_deeply($p,
            $array[$lim-($idx+1)],
            "zs2($n:$idx) @{$array[$lim-($idx+1)]}"
        );
    }

    $p = $zs1->next;
    ok(!defined($p), 'zs1 exhausted');

    $zs1->reset;
    $p = $zs1->next;
    is_deeply($p, $array[0], "zs1 reset next");

    $p = $zs2->next;
    ok(!defined($p), 'zs2 exhausted');

    $zs2->reset;
    $p = $zs2->next;
    is_deeply($p, $array[$#array], "zs2 reset next");
}

cmp_ok( $_, 'eq', $Unchanged, '$_ has not been altered' );

__DATA__
2
1 1

3
2 1
1 1 1

4
3 1
2 2
2 1 1
1 1 1 1

5
4 1
3 2
3 1 1
2 2 1
2 1 1 1
1 1 1 1 1

6
5 1
4 2
4 1 1
3 3
3 2 1
3 1 1 1
2 2 2
2 2 1 1
2 1 1 1 1
1 1 1 1 1 1

7
6 1
5 2
5 1 1
4 3
4 2 1
4 1 1 1
3 3 1
3 2 2
3 2 1 1
3 1 1 1 1
2 2 2 1
2 2 1 1 1
2 1 1 1 1 1
1 1 1 1 1 1 1

8
7 1
6 2
6 1 1
5 3
5 2 1
5 1 1 1
4 4
4 3 1
4 2 2
4 2 1 1
4 1 1 1 1
3 3 2
3 3 1 1
3 2 2 1
3 2 1 1 1
3 1 1 1 1 1
2 2 2 2
2 2 2 1 1
2 2 1 1 1 1
2 1 1 1 1 1 1
1 1 1 1 1 1 1 1

9
8 1
7 2
7 1 1
6 3
6 2 1
6 1 1 1
5 4
5 3 1
5 2 2
5 2 1 1
5 1 1 1 1
4 4 1
4 3 2
4 3 1 1
4 2 2 1
4 2 1 1 1
4 1 1 1 1 1
3 3 3
3 3 2 1
3 3 1 1 1
3 2 2 2
3 2 2 1 1
3 2 1 1 1 1
3 1 1 1 1 1 1
2 2 2 2 1
2 2 2 1 1 1
2 2 1 1 1 1 1
2 1 1 1 1 1 1 1
1 1 1 1 1 1 1 1 1

10
9 1
8 2
8 1 1
7 3
7 2 1
7 1 1 1
6 4
6 3 1
6 2 2
6 2 1 1
6 1 1 1 1
5 5
5 4 1
5 3 2
5 3 1 1
5 2 2 1
5 2 1 1 1
5 1 1 1 1 1
4 4 2
4 4 1 1
4 3 3
4 3 2 1
4 3 1 1 1
4 2 2 2
4 2 2 1 1
4 2 1 1 1 1
4 1 1 1 1 1 1
3 3 3 1
3 3 2 2
3 3 2 1 1
3 3 1 1 1 1
3 2 2 2 1
3 2 2 1 1 1
3 2 1 1 1 1 1
3 1 1 1 1 1 1 1
2 2 2 2 2
2 2 2 2 1 1
2 2 2 1 1 1 1
2 2 1 1 1 1 1 1
2 1 1 1 1 1 1 1 1
1 1 1 1 1 1 1 1 1 1
