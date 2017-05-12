use strict;
use Test::More tests => 13;
use Iterator::Util;

# Check that imap function works (assumes irange works).

sub begins_with
{
    my ($actual, $expected, $test_name) = @_;

    $actual = substr($actual, 0, length $expected);
    @_ =  ($actual, $expected, $test_name);
    goto &is;
}

my ($iter, $x, $worked, @vals);

## Parameter error  (4)
eval
{
    $iter = imap { $_ * 2} 'oops';
};

$x = $@;
isnt ($@, q{},   q{Wrong-type; exception thrown});
ok (Iterator::X->caught(), q{Wrong-type base exception type});
ok (Iterator::X::Parameter_Error->caught(), q{Wrong-type specific exception type});
begins_with ($x, q{Argument to imap must be an Iterator object},
                 q{Wrong-type exception formatted properly});

## run an irange through an imap. (1)
eval
{
    $iter = imap { $_ * 2 } irange (0);
};

is ($@, q{},   q{Normal; no exception thrown});

# pull a few numbers out of the hat.  (2)
@vals = ();
eval
{
    push @vals, $iter->value()  for (1..4);
};

is ($@, q{}, q{No exception when imapping});
is_deeply (\@vals, [0, 2, 4, 6], q{imap transformation returned expected result});

# Now do it with a finite irange (2)
@vals = ();
eval
{
    $iter = imap {$_ * $_} irange (1, 4);
    push @vals, $iter->value  while $iter->isnt_exhausted;
};

is ($@, q{}, q{No exception when imapping.});
is_deeply (\@vals, [1, 4, 9, 16], q{Square imap returned expected results});

# Try pushing it further: (4)
eval
{
    push @vals, $iter->value;
};

$x = $@;
isnt ($@, q{},   q{Imapped too far; exception thrown});
ok (Iterator::X->caught(), q{Too-far base exception type});
ok (Iterator::X::Exhausted->caught(), q{Too-far specific exception type});
begins_with ($x, q{Iterator is exhausted},
                 q{Too-far exception formatted properly});

