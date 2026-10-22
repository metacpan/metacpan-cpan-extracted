#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Ex::Op ();
use EO::OpTwin;

sub who { (caller(1))[3] // 'none' }
sub above { (caller(2))[3] // 'none' }

BEGIN {
    Ex::Op::make(add   => sub { my ($x, $y) = @_; $x + $y });
    Ex::Op::make(add3  => sub { my ($x, $y, $z) = @_; add(add($x, $y), $z) });
    Ex::Op::make(via   => sub { my ($x) = @_; main::plain_calls_add($x) });
    Ex::Op::make(selfy => sub { my ($x) = @_; $x ? main::plain_calls_selfy($x - 1) + 1 : 0 });
    Ex::Op::make(seen  => sub { my ($x) = @_; [who(), above()] });
}
sub plain_calls_add   { my ($x) = @_; my $r = add($x, 1); $r }
sub plain_calls_selfy { my ($x) = @_; my $r = selfy($x); $r }

sub t_nested { my $r = add3(1, 2, 3); $r }
is( t_nested(), 6, 'an op calling an op' );

sub t_via { my $r = via(5); $r }
is( t_via(), 6, 'an op calling a plain sub calling another op' );

sub t_selfy { my $r = selfy(4); $r }
is( t_selfy(), 4, 'an op calling a plain sub calling the same op: the inner call is ordinary' );

# A chain of 40 different ops, each calling the next, so the records
# outgrow their first allocation in the middle of a call.
BEGIN {
    Ex::Op::make('EO::Chain::c40', sub { my ($x) = @_; $x + 40 });
    for my $i (reverse 1 .. 39) {
        my $next = $i + 1;
        my $code = eval "package main; sub { my (\$x) = \@_; EO::Chain::c$next(\$x + $i) }" or die $@;
        Ex::Op::make("EO::Chain::c$i", $code) or die Ex::Op::why_not($code);
    }
}
sub t_chain { my $r = EO::Chain::c1(0); $r }
is( t_chain(), 820, '40 ops deep, each calling the next' );
is( t_chain(), 820, '... and again' );

sub t_chain_list { my @r = (1, EO::Chain::c1(0), 2); \@r }
is_deeply( t_chain_list(), [1, 820, 2], '... inside a list' );

{
    package EO::Chain::Obj;
    my $got;
    sub new { bless {}, shift }
    sub DESTROY { $got = EO::Chain::c1(0) }
    sub got { $got }
}
BEGIN { Ex::Op::make(hold => sub { my ($o) = @_; $o = EO::Chain::Obj->new; ref $o }) }
sub t_destroy_chain { my $r = hold(1); [$r, EO::Chain::Obj::got()] }
is_deeply( t_destroy_chain(), [q{EO::Chain::Obj}, 820], q{a parameter holding the only reference, whose DESTROY runs 40 ops deep as the parameter is cleared} );
is( add(2, 2), 4, q{... and calls work after} );

sub t_seen { my @r = map { seen($_) } 1 .. 3; \@r }
{
    my $s = t_seen()->[0];
    like( $s->[0], qr/__ANON__$/, q{an op called from a map block: code it calls sees the op as its caller} );
    is( $s->[1], q{none}, q{... and the op has no frame of its own} );
}

{
    my @warn;
    local $SIG{__WARN__} = sub { push @warn, $_[0] };
    sub leaver { no warnings 'exiting'; last }
    my $c = EO::OpTwin::twin('my ($x) = @_; main::leaver(); "not reached"');
    my (@op, @plain);
    for my $kind (qw(op plain)) {
        my $f = $c->{$kind}{scalar};
        my @got;
        for my $i (1 .. 3) {
            push @got, "i$i";
            my $r = $f->($i);
            push @got, "after $i";
        }
        push @got, 'loop done';
        $kind eq 'op' ? (@op = @got) : (@plain = @got);
    }
    is_deeply( \@op, \@plain, 'last from a sub the body calls leaves the caller\'s loop, as with a plain sub' );
    is( add(1, 2), 3, '... and calls work after' );
}

done_testing;
