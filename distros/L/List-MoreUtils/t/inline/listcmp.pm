
use Test::More;
use Test::LMU;
use Tie::Array ();

SCOPE:
{
    my @a = qw(one two three four five six seven eight nine ten eleven twelve thirteen);
    my @b = qw(two three five seven eleven thirteen seventeen);
    my @c = qw(one one two three five eight thirteen twentyone);

    my %expected = (
        one   => [0, 2],
        two   => [0, 1, 2],
        three => [0, 1, 2],
        four => [0],
        five => [0, 1, 2],
        six  => [0],
        seven  => [0, 1],
        eight  => [0, 2],
        nine   => [0],
        ten    => [0],
        eleven => [0, 1],
        twelve => [0],
        thirteen  => [0, 1, 2],
        seventeen => [1],
        twentyone => [2],
    );

    my %cmped = listcmp @a, @b, @c;
    is_deeply(\%cmped, \%expected, "Sequence vs. Prime vs. Fibonacci sorted out correctly");
}

SCOPE:
{
    my @a = ("one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve", "thirteen");
    my @b = (undef, "two", "three", undef,  "five", undef, "seven", undef,   undef,  undef, "eleven", undef,    "thirteen");

    my %expected = (
        one      => [0],
        two      => [0, 1],
        three    => [0, 1],
        four     => [0],
        five     => [0, 1],
        six      => [0],
        seven    => [0, 1],
        eight    => [0],
        nine     => [0],
        ten      => [0],
        eleven   => [0, 1],
        twelve   => [0],
        thirteen => [0, 1],
    );

    my %cmped = listcmp @a, @b;
    is_deeply(\%cmped, \%expected, "Sequence vs. Prime filled with undef sorted out correctly");
}

leak_free_ok(
    listcmp => sub {
        my @a = ("one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve", "thirteen");
        my @b = (undef, "two", "three", undef,  "five", undef, "seven", undef,   undef,  undef, "eleven", undef,    "thirteen");

        my %expected = (
            one      => [0],
            two      => [0, 1],
            three    => [0, 1],
            four     => [0],
            five     => [0, 1],
            six      => [0],
            seven    => [0, 1],
            eight    => [0],
            nine     => [0],
            ten      => [0],
            eleven   => [0, 1],
            twelve   => [0],
            thirteen => [0, 1],
        );

        my %cmped = listcmp @a, @b;
    }
);

# This test (and the associated fix) are from Kevin Ryde; see RT#49796
leak_free_ok(
    'listcmp with exception in overloading stringify at begin' => sub {
        eval {
            my @a = ("one", "two", "three");
            my @b = (DieOnStringify->new, "two", "three");

            my %expected = (
                one   => [0],
                two   => [0, 1],
                three => [0, 1],
            );

            my %cmped = listcmp @a, @b;
        };
    },
    'listcmp with exception in overloading stringify at end' => sub {
        eval {
            my @a = ("one", "two",   "three");
            my @b = ("two", "three", DieOnStringify->new);

            my %expected = (
                one   => [0],
                two   => [0, 1],
                three => [0, 1],
            );

            my %cmped = listcmp @a, @b;
        };
    }
);

done_testing;
