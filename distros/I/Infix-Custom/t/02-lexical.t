#!perl
use 5.014;
use strict;
use warnings;
use utf8;
use Test::More;

BEGIN {
    plan skip_all => "custom infix operators require perl 5.38+ (have $])"
        unless "$]" >= 5.038;
}

plan tests => 6;

use Infix::Custom ();   # load without declaring anything

sub add  { $_[0] + $_[1] }
sub mul  { $_[0] * $_[1] }

# --- the operator is active only inside its lexical block -------------------
my $inside;
{
    use Infix::Custom op => '⊕', call => \&add, prec => 'add';
    $inside = 2 ⊕ 3;
}
is($inside, 5, 'operator is usable inside its lexical scope');

# Outside the block there is no hint, so compiling a use of ⊕ is an error.
# String eval inherits the (operator-free) hints of this location.
my $out = eval q{ my $y = 2 ⊕ 3; $y };
ok(!defined $out, 'operator is not usable outside its lexical scope');
like($@, qr/\S/, 'out-of-scope use is a compile error');

# --- nested rebinding of the same glyph ------------------------------------
my ($outer, $inner, $restored);
{
    use Infix::Custom op => '⊕', call => \&add, prec => 'add';
    $outer = 5 ⊕ 6;                 # add  -> 11
    {
        use Infix::Custom op => '⊕', call => \&mul, prec => 'add';
        $inner = 5 ⊕ 6;             # mul  -> 30
    }
    $restored = 5 ⊕ 6;             # add again -> 11
}
is($outer,    11, 'outer scope binds the operator to add');
is($inner,    30, 'inner scope rebinds the operator to mul');
is($restored, 11, 'outer binding restored after inner scope exits');
