# Test slurpy parameters

use strict;
use warnings;
use Dios;

use Test::More;
use Test::Exception;

{
    package Stuff;
    use Test::More;

    method slurpy(*@that) { return \@that }
    method slurpy_last($this, *@that) { return $this, \@that; }
    method slurpy_required(*@that!) { return \@that }

    method slurpy_named(*:@that) { return \@that }
    method slurpy_named_slurpy(Int *:@this, Int *@that) { return (\@this, \@that) }

    func slurpy_first(*@that, $this)          { return $this, \@that; }
    func slurpy_middle($this, *@that, $other) { return $this, \@that, $other }
}

note "Optional slurpy params accept 0 length list"; {
    is_deeply [Stuff->slurpy()], [[]];
    is_deeply [Stuff->slurpy(1..3)], [[1..3]];

    is_deeply [Stuff->slurpy_last(23)], [23, []];
    is_deeply [Stuff->slurpy_last(23,42,99)], [23, [42,99]];

    is_deeply [Stuff::slurpy_first(23)], [23, []];
    is_deeply [Stuff::slurpy_first(23,42,99)], [23, [42,99]];

    is_deeply [Stuff::slurpy_middle(23,42)], [23, [], 42];
    is_deeply [Stuff::slurpy_middle(23,42,86)], [23, [86], 42];

    is_deeply [Stuff->slurpy_named()], [[]];
    is_deeply [Stuff->slurpy_named(that => 1, that => 2, that => 3 )], [[1..3]];

    is_deeply [Stuff->slurpy_named_slurpy(42,86)], [[],[42,86]];
    is_deeply [Stuff->slurpy_named_slurpy(this => 1, this => 2, this => 3, 42,86)], [[1..3],[42,86]];
}


note "Required slurpy params require an argument"; {
    throws_ok { Stuff->slurpy_required() }
      qr{\QMissing argument for required slurpy parameter \E\*\@that\n\Qin method slurpy_required\E};
}


done_testing;
