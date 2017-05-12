use strict;
use Test::More tests => 42;
use Iterator::Util;

# Check that irange function works.

sub begins_with
{
    my ($actual, $expected, $test_name) = @_;

    $actual = substr($actual, 0, length $expected);
    @_ =  ($actual, $expected, $test_name);
    goto &is;
}

my ($iter, $x, $worked, @vals);

## One-arg irange (infinite) (3)
eval
{
    $iter = irange(52);
};

is $@, q{},   q{Created one-arg iterator; no exception};

# How do you test an infinite iterator?
# Well, let's run through a bunch of iterations, see if it pans out.
$worked = 1;   # assume okay
eval
{
    foreach my $test (52..151)   # try a hundred values
    {
        if ($test != $iter->value  ||  $iter->is_exhausted)
        {
            $worked = 0;
            last;
        }
    }
};

is ($@, q{}, q{Looped over one-arg iterator; no exception});
ok ($worked, q{One-arg iterator gave expected values});


## Two-arg irange (start, end).  (3)
eval
{
    $iter = irange (4, 6);
};

is ($@, q{}, q{Created two-arg iterator; no exception});

@vals = ();
eval
{
    push @vals, $iter->value  while $iter->isnt_exhausted;
};

is ($@, q{}, q{Invoked two-arg iterator until exhausted});
is_deeply (\@vals, [4, 5, 6], q{Two-arg iterator returned expected results});


## Two-arg irange (start, end), end < start.  (3)
eval
{
    $iter = irange (6, 4);
};

is ($@, q{}, q{Created two-arg iterator; no exception});

@vals = ();
eval
{
    push @vals, $iter->value  while $iter->isnt_exhausted;
};

is ($@, q{}, q{Invoked two-arg iterator until exhausted});
is_deeply (\@vals, [], q{Two-arg iterator returned expected results});


## Two-arg irange (start, end), end == start.  (3)
eval
{
    $iter = irange (6, 6);
};

is ($@, q{}, q{Created two-arg iterator; no exception});

@vals = ();
eval
{
    push @vals, $iter->value  while $iter->isnt_exhausted;
};

is ($@, q{}, q{Invoked two-arg iterator until exhausted});
is_deeply (\@vals, [6], q{Two-arg iterator returned expected results});


## Three-arg irange (start, end, step).  (3)
eval
{
    $iter = irange (28, 41, 7);
};

is ($@, q{}, q{Created three-arg iterator; no exception});

@vals = ();
eval
{
    push @vals, $iter->value  while $iter->isnt_exhausted;
};

is ($@, q{}, q{Invoked three-arg iterator until exhausted});
is_deeply (\@vals, [28, 35], q{Three-arg iterator returned expected results});

## Three-arg irange (start, end, step).  (3)
eval
{
    $iter = irange (28, 42, 7);
};

is ($@, q{}, q{Created three-arg iterator; no exception});

@vals = ();
eval
{
    push @vals, $iter->value  while $iter->isnt_exhausted;
};

is ($@, q{}, q{Invoked three-arg iterator until exhausted});
is_deeply (\@vals, [28, 35, 42], q{Three-arg iterator returned expected results});

## Three-arg irange (start, end, step).  (3)
eval
{
    $iter = irange (28, 43, 7);
};

is ($@, q{}, q{Created three-arg iterator; no exception});

@vals = ();
eval
{
    push @vals, $iter->value  while $iter->isnt_exhausted;
};

is ($@, q{}, q{Invoked three-arg iterator until exhausted});
is_deeply (\@vals, [28, 35, 42], q{Three-arg iterator returned expected results});

## Three-arg irange (start, end, negative step).  (3)
eval
{
    $iter = irange (42, 29, -7);
};

is ($@, q{}, q{Created three-arg iterator; no exception});

@vals = ();
eval
{
    push @vals, $iter->value  while $iter->isnt_exhausted;
};

is ($@, q{}, q{Invoked three-arg iterator until exhausted});
is_deeply (\@vals, [42, 35], q{Three-arg iterator returned expected results});

## Three-arg irange (start, end, negative step).  (3)
eval
{
    $iter = irange (42, 28, -7);
};

is ($@, q{}, q{Created three-arg iterator; no exception});

@vals = ();
eval
{
    push @vals, $iter->value  while $iter->isnt_exhausted;
};

is ($@, q{}, q{Invoked three-arg iterator until exhausted});
is_deeply (\@vals, [42, 35, 28], q{Three-arg iterator returned expected results});

## Three-arg irange (start, end, negative step).  (3)
eval
{
    $iter = irange (42, 27, -7);
};

is ($@, q{}, q{Created three-arg iterator; no exception});

@vals = ();
eval
{
    push @vals, $iter->value  while $iter->isnt_exhausted;
};

is ($@, q{}, q{Invoked three-arg iterator until exhausted});
is_deeply (\@vals, [42, 35, 28], q{Three-arg iterator returned expected results});


## Three-arg irange (start, end, zero step).  (3)
eval
{
    $iter = irange (28, 42, 0);
};

is ($@, q{}, q{Created three-arg iterator; no exception});

@vals = ();
eval
{
    push @vals, $iter->value  for (0..9);
};

is ($@, q{}, q{Invoked three-arg (zero) iterator for a while});
is_deeply (\@vals, [28, 28, 28, 28, 28, 28, 28, 28, 28, 28], q{Three-arg iterator returned expected results});

## Three-arg irange (start, end, step) (1 iteration, give or take).  (3)
eval
{
    $iter = irange (28, 27, 7);
};

is ($@, q{}, q{Created three-arg iterator; no exception});

@vals = ();
eval
{
    push @vals, $iter->value  while $iter->isnt_exhausted;
};

is ($@, q{}, q{Invoked three-arg terator until exhausted});
is_deeply (\@vals, [], q{Three-arg iterator returned expected results});

## Three-arg irange (start, end, step) (1 iteration, give or take).  (3)
eval
{
    $iter = irange (28, 28, 7);
};

is ($@, q{}, q{Created three-arg iterator; no exception});

@vals = ();
eval
{
    push @vals, $iter->value  while $iter->isnt_exhausted;
};

is ($@, q{}, q{Invoked three-arg terator until exhausted});
is_deeply (\@vals, [28], q{Three-arg iterator returned expected results});

## Three-arg irange (start, end, step) (1 iteration, give or take).  (3)
eval
{
    $iter = irange (28, 34, 7);
};

is ($@, q{}, q{Created three-arg iterator; no exception});

@vals = ();
eval
{
    push @vals, $iter->value  while $iter->isnt_exhausted;
};

is ($@, q{}, q{Invoked three-arg terator until exhausted});
is_deeply (\@vals, [28], q{Three-arg iterator returned expected results});

