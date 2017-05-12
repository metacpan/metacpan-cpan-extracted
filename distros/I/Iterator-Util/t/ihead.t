use strict;
use Test::More tests => 29;
use Iterator::Util;

# Check that ihead works as promised.

sub begins_with
{
    my ($actual, $expected, $test_name) = @_;

    $actual = substr($actual, 0, length $expected);
    @_ =  ($actual, $expected, $test_name);
    goto &is;
}

my ($iter, $x, $next, @vals);

# ihead (3)
eval
{
    $iter = ihead 5, imap { $_ * $_ } irange 4;
};

$x = $@;
is $x, q{},   q{Created ihead iterator, no errors};

@vals = ();
eval
{
    push @vals, $iter->value  while $iter->isnt_exhausted;
};
is $x, q{},   q{Executed ihead iterator, no errors};
is_deeply (\@vals, [16, 25, 36, 49, 64], q{ihead returned expected values});


# ihead, zero (3)
eval
{
    $iter = ihead 0, imap { $_ * $_ } irange 4;
};

$x = $@;
is $x, q{},   q{Created ihead iterator, no errors};

@vals = ();
eval
{
    push @vals, $iter->value  while $iter->isnt_exhausted;
};
is $x, q{},   q{Executed ihead iterator, no errors};
is_deeply (\@vals, [], q{ihead returned expected values});


# ihead, negative (3)
eval
{
    $iter = ihead -77, imap { $_ * $_ } irange 4;
};

$x = $@;
is $x, q{},   q{Created ihead iterator, no errors};

@vals = ();
eval
{
    push @vals, $iter->value  while $iter->isnt_exhausted;
};
is $x, q{},   q{Executed ihead iterator, no errors};
is_deeply (\@vals, [], q{ihead returned expected values});


# ihead, parameter error (4)
eval
{
    $iter = ihead -77, 4;
};

$x = $@;
isnt $x, q{},   q{Created ihead iterator, no errors};
ok (Iterator::X->caught(), q{ihead exception: proper base class});
ok (Iterator::X::Parameter_Error->caught(), q{ihead exception: proper specific class});
begins_with ($x, q{Second parameter for ihead must be an Iterator},
             q{ihead exception formatted properly.});


# ihead (3)
eval
{
    $iter = imap { $_ * $_ } irange 4;
    @vals = ihead 5, $iter;
    $next = $iter->value;
};

is $@, q{},   q{Called ihead, no errors};
is_deeply (\@vals, [16, 25, 36, 49, 64], q{ihead returned expected values});
cmp_ok ($next, '==', 81, q{Iterator advanced correctly});

# ihead, zero (3)
eval
{
    $iter = imap { $_ * $_ } irange 4;
    @vals = ihead 0, $iter;
    $next = $iter->value;
};

is $@, q{},   q{Created ihead iterator, no errors};
is_deeply (\@vals, [], q{ihead returned expected values});
cmp_ok ($next, '==', 16, q{Iterator advanced correctly});

# ihead, negative (3)
eval
{
    $iter = imap { $_ * $_ } irange 4;
    @vals = ihead -64, $iter;
    $next = $iter->value;
};

is $@, q{},   q{Created ihead iterator, no errors};
is_deeply (\@vals, [], q{ihead returned expected values});
cmp_ok ($next, '==', 16, q{Iterator advanced correctly});

# ihead, undef (3)
eval
{
    $iter = imap { $_ * $_ } irange 4, 6;
    @vals = ihead undef, $iter;
};

is $@, q{},   q{Created ihead iterator, no errors};
is_deeply (\@vals, [16, 25, 36], q{ihead returned expected values});
ok ($iter->is_exhausted, q{ihead exhausted the iterator});

# ihead, parameter error (4)
eval
{
    $iter = ihead -77, 4;
};

$x = $@;
isnt $x, q{},   q{Created ihead iterator, no errors};
ok (Iterator::X->caught(), q{ihead exception: proper base class});
ok (Iterator::X::Parameter_Error->caught(), q{ihead exception: proper specific class});
begins_with ($x, q{Second parameter for ihead must be an Iterator},
             q{ihead exception formatted properly.});
