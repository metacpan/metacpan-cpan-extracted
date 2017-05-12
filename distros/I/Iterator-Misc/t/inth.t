use strict;
use Test::More tests => 3;
use Iterator::Misc;

my ($iter, @vals);

# inth with invalid input
my $countval = 0;
my $count = Iterator->new(sub {$countval++});

eval
{
    $iter = inth(0, $count);
};
ok (Iterator::X::Parameter_Error->caught(), q{Illegal parameter});

# Normal operation
@vals = ();
eval
{
    $iter = inth(5, $count);
    push @vals, $iter->value() for 1..5;
};
is ($@, q{}, q{No error in normal operation});
is_deeply (\@vals, [4, 9, 14, 19, 24], q{inth returned expected values});
