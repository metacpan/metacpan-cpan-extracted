#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use EO::OpTwin;

sub mk  { join '', 'm', @_ }
sub two { (1, 2) }
sub who { (caller(1))[3] // 'none' }
sub above { (caller(2))[3] // 'none' }

twin_all( 'a list of values',        'my ($x, $y) = @_; ($x, $y, $x + $y)', 2, 3 );
twin_all( 'an array',                'my ($n) = @_; my @a = (1 .. $n); @a', 4 );
twin_all( 'a hash',                  'my ($k) = @_; my %h = ($k => 1); %h', 'a' );
twin_all( 'a sub call in the tail',  'my ($x) = @_; two()', 1 );
twin_all( 'reverse in the tail',     'my ($x) = @_; reverse "ab", $x', 'cd' );
twin_all( 'a ternary over lists',    'my ($x) = @_; $x ? two() : (7, 8, 9)', 0 );
twin_all( 'a list of the same lexical', 'my ($x) = @_; ($x, $x)', 5 );
twin_all( 'mortals from calls',      'my ($x) = @_; (mk($x), mk("b"))', 'a' );
twin_all( 'an empty list',           'my ($x) = @_; ()', 1 );
twin_all( 'undef in a list',         'my ($x) = @_; (undef, $x)', 1 );
twin_all( 'a reference in a list',   'my ($x) = @_; ([$x], {k => $x})', 1 );

{
    my $c = EO::OpTwin::twin(q{my ($x) = @_; (main::above(), $x)});
    my $r = $c->{op}{list}->(9);
    is( $r->[1], 9, q{list context, fast path: the value} );
    is( $r->[0], q{none}, q{... and the op has no frame: two frames up from its body is past its caller} );
    my $p = $c->{plain}{list}->(9);
    isnt( $p->[0], q{none}, q{... where a plain sub has its caller there} );
}

{
    my $c = EO::OpTwin::twin('my ($n) = @_; my @a = (1 .. $n); @a');
    my @r = (1, 2, @{ $c->{op}{list}->(3) }, 9);
    is_deeply( \@r, [1, 2, 1, 2, 3, 9], 'a list result inside a larger list' );
    my @refs = map { \$_ } @{ $c->{op}{list}->(2) };
    ${ $refs[0] } = 'changed';
    is_deeply( $c->{op}{list}->(2), [1, 2], 'a list result is a copy' );
}

done_testing;
