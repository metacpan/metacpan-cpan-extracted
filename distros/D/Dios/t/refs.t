use strict;
use warnings;

use lib 't/lib';

use Test::More;

# Test a basic alias.
{
    package Foo;

    use Test::More;

    use Dios;

    method add_one_to_each(@args) {
        $_++ for @args;
        return @args;
    }

    my @input = (1,2,3);
    is_deeply [Foo->add_one_to_each(\@input)], [2,3,4];
    is_deeply \@input, [1,2,3];

    close *STDERR;
    open *STDERR, '>', \my $devnull;
    ok !eval q[@args; 1;], '\@args does not leak out of subroutine';
}


# Try to break the aliasing prototype
{
    package Bar;

    use Test::More;

    use Dios;

    method break_args($foo, @bar, %baz, $num, $biff, *@rest) {
        return {
            foo         => $foo,
            bar         => \@bar,
            baz         => \%baz,
            num         => $num,
            biff        => $biff,
            rest        => \@rest
        }
    }

    is_deeply(
      Bar->break_args(1, [2,3], {4 => 5}, 6, 7, (8,9)),
      { foo => 1, bar => [2,3], baz => {4 => 5}, num => 6,
        biff => 7, rest => [8,9] }
    );
}


# What about closures?
{
    package Stuff;

    use Dios;

    method make_closure(@nums) {
        print \@nums, " - outer\n";
        return sub {
            print \@nums, " - inner\n";
            return @nums;
        };
    }

    my $closure1 = Stuff->make_closure([1,2,3]);
    my $closure2 = Stuff->make_closure([4,5,6]);

    ::is_deeply [$closure1->()], [1,2,3];
    ::is_deeply [$closure2->()], [4,5,6];
}

done_testing;

