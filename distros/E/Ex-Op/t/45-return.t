#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Ex::Op ();
use EO::OpTwin;

sub note_it { push @EO::OpTwin::LOG, join ',', @_; 'noted' }
sub two     { (1, 2) }

twin_all( 'return at the end',       'my ($x) = @_; return $x + 1', 1 );
twin_all( 'return in a plain if',    'my ($x) = @_; if ($x) { return "yes" } "no"', 1 );
twin_all( '... not taken',           'my ($x) = @_; if ($x) { return "yes" } "no"', 0 );
twin_all( 'or return',               'my ($x) = @_; $x or return "none"; "some $x"', 0 );
twin_all( '... not taken',           'my ($x) = @_; $x or return "none"; "some $x"', 4 );
twin_all( 'a ternary return',        'my ($x) = @_; return $x ? "t" : "f"', 1 );
twin_all( 'a bare return',           'my ($x) = @_; return; 1', 1 );
twin_all( 'return a list',           'my ($x) = @_; return (1, 2, $x)', 3 );
twin_all( 'return an array',         'my ($x) = @_; my @a = ($x) x 3; return @a', 'q' );
twin_all( 'return a sub call',       'my ($x) = @_; return two()', 1 );
twin_all( 'return reverse',          'my ($x) = @_; return reverse "ab", $x', 'cd' );
twin_all( 'an early return skips the rest', 'my ($x) = @_; note_it("a"); return $x if $x; note_it("b"); "end"', 1 );
twin_all( '... and when not taken',  'my ($x) = @_; note_it("a"); return $x if $x; note_it("b"); "end"', 0 );
twin_all( 'two returns',             'my ($x) = @_; return "small" if $x < 10; return "big"', 50 );
twin_all( 'return a lexical',        'my ($x) = @_; my $t = "<$x>"; return $t', 'v' );
twin_all( 'return in a do block',    'my ($x) = @_; my $r = do { $x + 1 }; return $r', 2 );
twin_all( 'return inside a larger expression', 'my ($x) = @_; my @l = (1, 2, return "r"); "not reached"', 7 );
twin_all( 'return as an argument', 'my ($x) = @_; my $s = join(",", "a", "b", return($x, $x)); "not reached"', 3 );

{
    my $code = sub { my ($x) = @_; return $x * 2 };
    ok( Ex::Op::make(ret_op => $code), 'a body with a return is an op' );
    my $r = (eval q{ sub { my $v = ret_op(21); $v } })->();
    is( $r, 42, '... and its call returns' );
    is( ret_op(5), 10, '... and so does a plain call through the glob' );
    is( (\&ret_op)->(6), 12, '... and through a reference' );
}

{
    my $code = sub { my ($n) = @_; return 1 if $n <= 1; return $n * EO::Ret::fact($n - 1) };
    Ex::Op::make('EO::Ret::fact', $code);
    my $r = (eval q{ sub { my $v = EO::Ret::fact(6); $v } })->();
    is( $r, 720, 'recursion through returns: the outer call frameless, the inner ones real' );
}

done_testing;
