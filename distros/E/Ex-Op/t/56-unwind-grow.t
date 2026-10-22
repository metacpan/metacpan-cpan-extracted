#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Ex::Op ();

# Alone in its file, so the call records start at their first size and grow
# while a parameter is being cleared at the end of a call.

BEGIN {
    Ex::Op::make('EO::Grow::c60', sub { my ($x) = @_; $x + 60 });
    for my $i (reverse 1 .. 59) {
        my $next = $i + 1;
        my $code = eval "package main; sub { my (\$x) = \@_; EO::Grow::c$next(\$x + $i) }" or die $@;
        Ex::Op::make("EO::Grow::c$i", $code) or die Ex::Op::why_not($code);
    }
}

{
    package EO::Grow::Obj;
    my $got;
    sub new     { bless {}, shift }
    sub DESTROY { $got = EO::Grow::c1(0) }
    sub got     { $got }
}

BEGIN {
    Ex::Op::make(hold => sub { my ($o) = @_; $o = EO::Grow::Obj->new; ref $o });
    Ex::Op::make(after => sub { my ($x, $y) = @_; "$x/$y" });
}

sub t_hold { my $r = hold(1); my $s = after('a', 'b'); [$r, EO::Grow::Obj::got(), $s] }
is_deeply( t_hold(), ['EO::Grow::Obj', 1830, 'a/b'],
           'a DESTROY 60 ops deep while a parameter is cleared, the records growing under it' );
is( after('c', 'd'), 'c/d', 'and a call after it' );

done_testing;
