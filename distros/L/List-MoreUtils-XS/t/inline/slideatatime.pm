
use Test::More;
use Test::LMU;

local $" = " ";
my $it;
my @r;

my @x = ('a' .. 'g');
$it = slideatatime 3, 3, @x;
while (my @vals = $it->())
{
    push @r, "@vals";
}
is(is_deeply(\@r, ['a b c', 'd e f', 'g']), 1, "slideatatime as natatime with 3 elements");

$it = slideatatime 2, 3, @x;
@r  = ();
while (my @vals = $it->())
{
    push @r, "@vals";
}
is(is_deeply(\@r, ['a b c', 'c d e', 'e f g', 'g']), 1, "slideatatime moving 3 elements by 2 items");

$it = slideatatime 1, 3, @x;
@r  = ();
while (my @vals = $it->())
{
    push @r, "@vals";
}
is(is_deeply(\@r, ['a b c', 'b c d', 'c d e', 'd e f', 'e f g', 'f g', 'g']), 1, "slideatatime moving 3 elements by 1 item");

my @a = (1 .. 1000);
$it = slideatatime 1, 1, @a;
@r  = ();
while (my @vals = &$it)
{
    push @r, @vals;
}
is(is_deeply(\@r, \@a), 1, "slideatatime as natatime with 1 element");

leak_free_ok(
    slideatatime => sub {
        my @y  = 1;
        my $it = slideatatime 2, 2, @y;
        while (my @vals = $it->())
        {
            # do nothing
        }
    },
    'slideatatime with exception' => sub {
        my @r;
        eval {
            my $it = slideatatime 1, 3, @x;
            while (my @vals = $it->())
            {
                scalar @vals == 3 or die;
                push @r, "@vals";
            }
        };
    }
);

done_testing;
