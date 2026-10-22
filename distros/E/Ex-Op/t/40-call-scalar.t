#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Ex::Op ();

my $DESTROYED = 0;
{
    package EO::Obj;
    sub new     { my ($class, $v) = @_; bless { v => $v }, $class }
    sub DESTROY { $DESTROYED++ }
}

sub lit    { 'abc' }
sub mk     { join '', 'm', @_ }

BEGIN {
    my %bodies = (
        add      => sub { my ($x, $y) = @_; $x + $y },
        cat      => sub { my ($x, $y) = @_; "$x-$y" },
        same     => sub { my ($x) = @_; $x },
        second   => sub { my ($x, $y) = @_; $y },
        undef_of => sub { my ($x) = @_; undef },
        ref_of   => sub { my ($x) = @_; [$x, $x] },
        call_in_tail    => sub { my ($x) = @_; lit() },
        reverse_in_tail => sub { my ($x) = @_; reverse "ab", $x },
        array_in_tail   => sub { my ($x) = @_; my @a = (1 .. $x); @a },
        ternary_tail    => sub { my ($x) = @_; $x ? lit() : mk($x) },
        or_tail         => sub { my ($x) = @_; $x || mk('z') },
        match_one       => sub { my ($x) = @_; $x =~ /(\d+)/; $1 },
        lexicals        => sub { my ($x, $y) = @_; my $t = $x * 2; my $u = $t + $y; $u },
        keep_obj        => sub { my ($o) = @_; ref $o },
        give_obj        => sub { my ($v) = @_; EO::Obj->new($v) },
        give_lex_obj    => sub { my ($v) = @_; my $o = EO::Obj->new($v); $o },
    );
    for my $name (sort keys %bodies) {
        Ex::Op::make($name, $bodies{$name}) or die "$name: " . Ex::Op::why_not($bodies{$name});
    }
}

sub check {
    my ($desc, $got, $want) = @_;
    is_deeply( $got, $want, $desc );
}

sub inner_void {
    my $a = add(2, 3);
    my $c = cat('a', 'b');
    my $s = same('x');
    my $t = call_in_tail(1);
    my $r = reverse_in_tail('cd');
    my $n = array_in_tail(4);
    my $q = ternary_tail(1) . ternary_tail(0);
    my $o = or_tail(0) . or_tail('y');
    return [$a, $c, $s, $t, $r, $n, $q, $o];
}

{
    my $got = [];
    inner_void();
    $got = inner_void();
    is_deeply( $got, [5, 'a-b', 'x', 'abc', 'dcba', 4, 'abcm0', 'mzy'],
               'scalar results, called from a sub in void context' );
    my @l = (inner_void());
    is_deeply( $l[0], $got, '... and in list context' );
}

{
    my $t = call_in_tail(1);
    is( $t, 'abc', 'a tail that takes its context, at file level' );
    my $n = array_in_tail(3);
    is( $n, 3, '... an array in scalar context' );
}

is( add(1, 2) + add(3, 4), 10, 'two calls in one expression' );
is( add(add(1, 2), add(3, 4)), 10, 'calls as arguments to calls' );
is( mk('a') . add(1, 2) . mk('b'), 'ma3mb', 'the caller\'s temporaries survive the call' );
is( join(',', map { scalar add($_, 1) } 1 .. 3), '2,3,4', 'in a map block' );

{
    my $r1 = \add(5, 6);
    my $r2 = \add(7, 8);
    is( "$$r1 $$r2", '11 15', 'references to two results are distinct' );
    my $x = add(1, 1);
    $x++;
    is( add(1, 1), 2, 'changing a result does not change the next one' );

    my @refs;
    for my $i (1 .. 3) { push @refs, \scalar(add($i, 1)) }
    is( join(q{,}, map { $$_ } @refs), q{2,3,4}, q{a reference to each result from one call site is to its own copy} );
}

is( second(1), undef, 'a missing argument is undef' );
is( same(1, 2, 3), 1, 'extra arguments are dropped' );
is( undef_of(1), undef, 'undef' );
is_deeply( ref_of(4), [4, 4], 'a reference' );
isnt( ref_of(1), ref_of(1), '... a new one each time' );

{
    my $v = 10;
    my $p = same($v);
    $p++;
    is( $v, 10, 'a parameter is a copy' );
}

{
    'q99' =~ /(\d+)/;
    my $m = match_one('a42');
    is( $m, 42, 'a match inside the body' );
    is( $1, 99, '... leaves the caller\'s $1' );
}

{
    tie my $t, 'EO::Tied';
    is( same($t), 'tied', 'a tied argument is fetched' );
}

{
    $DESTROYED = 0;
    {
        my $o = EO::Obj->new(1);
        my $r = keep_obj($o);
        is( $r, 'EO::Obj', 'an object as an argument' );
    }
    is( $DESTROYED, 1, '... is freed when the caller lets go: the parameter does not hold it' );

    $DESTROYED = 0;
    my $o = give_obj(2);
    is( $o->{v}, 2, 'an object as the result' );
    undef $o;
    is( $DESTROYED, 1, '... is freed when the caller lets go: no target holds it' );

    $DESTROYED = 0;
    my $p = give_lex_obj(3);
    is( $p->{v}, 3, q{an object held in a lexical as the result} );
    undef $p;
    is( $DESTROYED, 1, q{... is freed when the caller lets go} );
}

is( lexicals(3, 4), 10, 'lexicals in the body' );
is( lexicals(1, 1), 3, '... are fresh on the next call' );

{
    my $sum = 0;
    for my $i (1 .. 1000) { $sum = add($sum, $i) }
    is( $sum, 500500, '1000 calls in a loop' );
}

done_testing;

package EO::Tied;
sub TIESCALAR { bless [] }
sub FETCH     { 'tied' }
