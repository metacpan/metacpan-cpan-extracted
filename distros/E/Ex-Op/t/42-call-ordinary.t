#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Ex::Op ();

sub early { add(10, 20) }

BEGIN { Ex::Op::make(add => sub { my ($x, $y) = @_; $x + $y }) }
BEGIN { Ex::Op::make(fact => sub { my ($n) = @_; $n <= 1 ? 1 : $n * fact($n - 1) }) }
BEGIN { Ex::Op::make(one => sub ($) { my ($x) = @_; "<$x>" }) }
BEGIN { Ex::Op::make(list_of => sub { my ($n) = @_; my @l = (1 .. $n); @l }) }

is( &add(1, 2), 3, '&add(...)' );
is( (\&add)->(3, 4), 7, q{a call through a reference} );
sub via_goto { goto &add }
is( via_goto(5, 6), 11, 'goto &add' );
is( early(), 30, 'a call compiled before make' );

my @l = add(1, 2);
is_deeply( \@l, [3], 'list context' );
is_deeply( [list_of(3)], [1, 2, 3], '... where the body returns a list' );
is( scalar(list_of(3)), 3, '... and the same body in scalar context' );
add(1, 2);
pass( 'void context' );

is( fact(5), 120, 'recursion: the inner calls are ordinary' );
is( fact(1), 1, '... and the outer one is not' );

{
    my @a = (7, 8, 9);
    is( one(@a), '<3>', 'a prototype is applied: ($) makes an array its count' );
}

{
    no warnings 'redefine';
    local *add = sub { 'replaced' };
    is( add(1, 2), 'replaced', 'a sub put in the glob at run time is called' );
}
is( add(1, 2), 3, '... and the op is back after local' );

{
    my $r = eval { add(1, 2) };
    is( $r, 3, 'inside eval' );
}

done_testing;
