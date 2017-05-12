use strict;
use Test::More tests => 33;
use Iterator;

# Check that value() works.
# Also tests is_ and isnt_exhausted.

sub begins_with
{
    my ($actual, $expected, $test_name) = @_;

    $actual = substr($actual, 0, length $expected);
    @_ =  ($actual, $expected, $test_name);
    goto &is;
}

my ($iter, $x, $val, $exh, $nex);

# Create iterator for us to work with (1)
eval
{
    my $i = 1;
    my $max = 3;

    $iter = Iterator->new (
    sub
    {
        Iterator::X::Am_Now_Exhausted->throw()
            if ($i > $max);
        return $i++;
    }
    );
};

is $@, q{},   q{Created simple iterator; no exception};

# That iterator should not be exhausted already. (3)
eval
{
    $exh = $iter->is_exhausted;
    $nex = $iter->isnt_exhausted;
};

is ($@, q{}, q{Exhausted check didn't barf.});
ok (!$exh, q{Not exhausted yet.});
ok ( $nex, q{Not exhausted yet.});

# Fetch a value (2)
eval
{
    $val = $iter->value();
};

is $@, q{},   q{Pulled first value from iterator; no exception};
cmp_ok ($val, '==', 1, q{First value is correct});

# That iterator should not be exhausted yet. (3)
eval
{
    $exh = $iter->is_exhausted;
    $nex = $iter->isnt_exhausted;
};

is ($@, q{}, q{Exhausted check didn't barf.});
ok (!$exh, q{Not exhausted yet.});
ok ( $nex, q{Not exhausted yet.});


# Fetch a value (2)
eval
{
    $val = $iter->value();
};

is $@, q{},   q{Pulled second value from iterator; no exception};
cmp_ok ($val, '==', 2, q{Second value is correct});

# That iterator should not be exhausted yet. (3)
eval
{
    $exh = $iter->is_exhausted;
    $nex = $iter->isnt_exhausted;
};

is ($@, q{}, q{Exhausted check didn't barf.});
ok (!$exh, q{Not exhausted yet.});
ok ( $nex, q{Not exhausted yet.});


# Fetch a value (2)
eval
{
    $val = $iter->value();
};

is $@, q{},   q{Pulled third value from iterator; no exception};
cmp_ok ($val, '==', 3, q{Third value is correct});


# Iterator should now be exhausted. (3)
eval
{
    $exh = $iter->is_exhausted;
    $nex = $iter->isnt_exhausted;
};

is ($@, q{}, q{Exhausted check didn't barf.});
ok ( $exh, q{Now exhausted.});
ok (!$nex, q{Now exhausted.});


# Attempt to fetch a value from it (4)
eval
{
    $val = $iter->value();
};

$x = $@;
isnt $@, q{},   q{Pulled fourth value from iterator; got exception};

ok (Iterator::X->caught(), q{Exhausted exception base class ok});

ok (Iterator::X::Exhausted->caught(),  q{Exhausted exception specific class ok});

begins_with $x,
    q{Iterator is exhausted},
    q{Exhausted exception works as a string, too};


# Should still be able to check exhausted state. (3)
eval
{
    $exh = $iter->is_exhausted;
    $nex = $iter->isnt_exhausted;
};

is ($@, q{}, q{Exhausted check didn't barf.});
ok ( $exh, q{Now exhausted.});
ok (!$nex, q{Now exhausted.});


# Test user exception. (7)
eval
{
    my $internal = 1;
    $iter = Iterator->new(sub
    {
        die "what the heck?"
            if $internal > 2;
        return $internal++;
    });
};
is ($@, q{}, q{User-error iterator created fine.});

eval
{
    $val = $iter->value;
};
is ($@, q{}, q{User-error iterator; first value no error.});
cmp_ok ($val, '==', 1, q{User-error iterator; first value correct});

eval
{
    $val = $iter->value;
};
isnt ($@, q{}, q{User-error iterator blew up on time});
$x = $@;
ok (Iterator::X->caught(), q{User-error base exception caught});
ok (Iterator::X::User_Code_Error->caught(), q{User-error specific exception caught});
begins_with ($x, "what the heck?", q{User-error; proper string value.});
