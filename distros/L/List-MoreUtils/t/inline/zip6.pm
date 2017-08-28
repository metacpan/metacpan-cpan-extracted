
use Test::More;
use Test::LMU;

SCOPE:
{
    my @x = qw/a b c d/;
    my @y = qw/1 2 3 4/;
    my @z = zip6 @x, @y;
    is_deeply(\@z, [['a', 1], ['b', 2], ['c', 3], ['d', 4]], "zip6 two lists with same count of elements");
}

SCOPE:
{
    my @a = ('x');
    my @b = ('1', '2');
    my @c = qw/zip zap zot/;
    my @z = zip6 @a, @b, @c;
    is_deeply(
        \@z,
        [['x', 1, 'zip'], [undef, 2, 'zap'], [undef, undef, 'zot']],
        "zip6 three list with increasing count of elements"
    );
}

# Make array with holes
SCOPE:
{
    my @a = (1 .. 10);
    my @d;
    $#d = 9;
    my @z = zip6 @a, @d;
    is_deeply(
        \@z,
        [[1, undef], [2, undef], [3, undef], [4, undef], [5, undef], [6, undef], [7, undef], [8, undef], [9, undef], [10, undef]],
        "zip6 one list with 9 elements with an empty list"
    );
}

leak_free_ok(
    zip6 => sub {
        my @x = qw/a b c d e/;
        my @y = qw/1 2 3 4/;
        my @z = zip6 @x, @y;
    }
);
is_dying('zip6 with a list, not at least two arrays' => sub { &zip6(1, 2); });

done_testing;
