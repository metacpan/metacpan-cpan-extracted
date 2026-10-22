#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use B ();
use Ex::Op ();
use EO::OpTwin;

sub who  { (caller(1))[3] // 'none' }
sub above { (caller(2))[3] // 'none' }
sub lit  { 'L' }
sub depth_of { B::svref_2object($_[0])->DEPTH }

our $G = 'outer';
my $D = 0;
{ package EO::Die::Obj; sub new { bless {}, shift } sub DESTROY { $D++ } }

BEGIN {
    Ex::Op::make(boom      => sub { my ($x) = @_; die "boom $x\n" if $x; 'ok' });
    Ex::Op::make(boom_tail => sub { my ($x) = @_; die "tail\n" if $x; lit() });
    Ex::Op::make(boom_who  => sub { my ($x) = @_; die "who\n" if $x; above() });
    Ex::Op::make(boom_obj  => sub { my ($x) = @_; die EO::Die::Obj->new if $x; 1 });
    Ex::Op::make(boom_local => sub { my ($x) = @_; local $G = 'inner'; die "local\n" if $x; $G });
    Ex::Op::make(boom_inner => sub { my ($x) = @_; boom($x) . '!' });
    Ex::Op::make(keep       => sub { my ($o) = @_; die "keep\n"; 1 });
}
sub plain_boom { my ($x) = @_; die "boom $x\n" if $x; 'ok' }

sub caller_of_boom {
    my $mine = 'mine';
    my $r = eval { boom(1) };
    return [$r, $@, $mine, depth_of(\&boom)];
}
{
    my $got = caller_of_boom();
    is_deeply( $got, [undef, "boom 1\n", 'mine', 0], 'a die in an op: eval returns undef, $@ is set, the caller\'s lexicals are intact, the depth is 0' );
    my $w = do { sub { boom_who(0) } }->();
    is( $w, q{none}, q{... and the next call is frameless again: two frames up from its body is past its caller} );
}

sub stack_after_die {
    my @op    = (5, eval { (7, boom(1)) }, 6);
    my @plain = (5, eval { (7, plain_boom(1)) }, 6);
    my $s_op    = eval { my @t = (8, boom(1)); 1 };
    return [\@op, \@plain, $s_op];
}
is_deeply( stack_after_die(), [[5, 6], [5, 6], undef],
           'values pushed in the eval before the call are gone after the die, as with a plain sub' );

sub die_in_a_loop {
    my ($n, $caught) = (0, 0);
    for my $i (1 .. 100) {
        eval { boom($i % 2); $n++; 1 } or $caught++;
    }
    return [$n, $caught, boom(0)];
}
is_deeply( die_in_a_loop(), [50, 50, 'ok'], 'dies in a loop, every other call' );

sub die_lent { my $r = eval { boom_tail(1) }; [$r, $@, scalar(boom_tail(0))] }
is_deeply( die_lent(), [undef, "tail\n", 'L'], 'a die in a body whose tail borrows its context' );

sub die_obj { eval { boom_obj(1) }; [ref $@] }
$D = 0;
is_deeply( die_obj(), ['EO::Die::Obj'], 'a die with an object' );
$@ = '';
is( $D, 1, '... freed once $@ lets go' );

sub die_local { my $r = eval { boom_local(1) }; [$G, scalar(boom_local(0)), $G] }
is_deeply( die_local(), ['outer', 'inner', 'outer'], 'a local in the body is undone by a die, and by a return' );

sub die_nested { my $r = eval { boom_inner(1) }; [$r, $@, depth_of(\&boom), depth_of(\&boom_inner), scalar(boom_inner(0))] }
is_deeply( die_nested(), [undef, "boom 1\n", 0, 0, 'ok!'], 'a die in an op called by an op' );

sub die_keeps_arg {
    $D = 0;
    { my $o = EO::Die::Obj->new; eval { keep($o) } }
    return $D;
}
is( die_keeps_arg(), 1, 'a die does not keep an argument alive in the parameter' );

{
    my @seen;
    local $SIG{__DIE__} = sub { push @seen, $_[0] };
    sub die_hook { eval { boom(3) }; 1 }
    die_hook();
    is_deeply( \@seen, ["boom 3\n"], '$SIG{__DIE__} sees the die' );
}

{
    package EO::Die::Tied;
    sub TIESCALAR { bless [] }
    sub FETCH { die "fetch\n" }
}
sub die_fetch { tie my $t, 'EO::Die::Tied'; my $r = eval { boom($t) }; [$r, $@, depth_of(\&boom), scalar(boom(0))] }
is_deeply( die_fetch(), [undef, "fetch\n", 0, 'ok'], 'a die in a tied argument\'s FETCH, while the call is being set up' );

twin_all( 'a die',             'my ($x) = @_; die "no $x\n" if $x; "yes"', 1 );
twin_all( 'no die',            'my ($x) = @_; die "no $x\n" if $x; "yes"', 0 );
twin_all( 'a die after a local', 'my ($x) = @_; local $main::G = "in"; die "d\n" if $x; $main::G', 1 );
twin_all( 'a die in a sub the body calls', 'my ($x) = @_; main::plain_boom($x)', 1 );

done_testing;
