use strict;
use Test::More tests => 13;
use Iterator;

# Check that the documentation examples work.

sub begins_with
{
    my ($actual, $expected, $test_name) = @_;

    $actual = substr($actual, 0, length $expected);
    @_ =  ($actual, $expected, $test_name);
    goto &is;
}

my ($iter, $it, $x, @vals);

# from the README (13)

sub upto
{
    my ($m, $n) = @_;

    return Iterator->new( sub {
                              return $m++  if $m <= $n;
                              Iterator::X::Am_Now_Exhausted->throw();
                          });
}

@vals = ();
eval
{
    $it = upto (3, 5);
};

is ($@, q{}, q{README iterator created, no exception});

eval
{
    push @vals, $it->value;     #  returns 3
    push @vals, $it->value;     #  returns 4
    push @vals, $it->value;     #  returns 5
};

is ($@, q{}, q{README iterator; first three okay});
is_deeply (\@vals, [3, 4, 5], q{README iterator: expected values ok});

eval
{
    my $i = $it->value;     #  throws an Iterator::X::Exhausted exception.
};

isnt ($@, q{}, q{README iterator: exception thrown});
ok (Iterator::X->caught(), q{README exception: correct base type});
ok (Iterator::X::Exhausted->caught(), q{README exception: correct specific type});
begins_with ($@, q{Iterator is exhausted}, q{README iterator exception formatted propertly.});

{
    my $another_it;

    @vals = ();
    eval
    {
        $another_it = upto (7, 10);
        while ($another_it->isnt_exhausted)
        {
            push @vals, $another_it->value;
        }
        # The above [pushes] 7, 8, 9, 10 and throws no exceptions.
    };

    is ($@, q{}, q{$another_it: no exception thrown});
    is_deeply (\@vals, [7, 8, 9, 10], q{$another_it: expected values});

    eval
    {
        # Another call to $another_it->value would throw an exception.
        $another_it->value
    };

    isnt ($@, q{}, q{$another_it iterator: exception thrown});
    ok (Iterator::X->caught(), q{$another_it exception: correct base type});
    ok (Iterator::X::Exhausted->caught(), q{$another_it exception: correct specific type});
    begins_with ($@, q{Iterator is exhausted}, q{$another_it iterator exception formatted propertly.});
}
