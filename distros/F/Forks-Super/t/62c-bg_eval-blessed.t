use Forks::Super 'bg_eval', ':test';
use Test::More tests => 10;
use Time::HiRes 'time';
use strict;
use warnings;

{
    package Obj_23514242; # http://stackoverflow.com/q/23514242
    sub new { bless {}, shift }
    sub foo { my $z = 42; my $self = shift; $z += $_ for @_; $z }
    sub bar { my $self = shift; $self->foo(-23) }
    1;
}

sub slowly_return_object {
    my $n = shift;
    if ($n >= 1) {
        sleep $n;
    }
    return Obj_23514242->new;
}



my ($foo, $bar, $baz);

{
    my $untaint = ${^TAINT};
    my $t1 = time;
    my $ooo = bg_eval { slowly_return_object(10) } {untaint => $untaint};
    my $t2 = time;
    ok($t2-$t1 < 3, 'bg_eval returns quickly');
    ok(ref($ooo) eq 'Forks::Super::LazyEval::BackgroundScalar',
       'blessed bg_eval return val is BackgroundScalar');
    eval { $foo = $ooo->foo(0) };
    my $t3 = time;
    ok(!$@, 'method call from bg_eval return val ok')
        or diag '$@(',__LINE__,') was ', $@;
    ok($t3-$t1 > 8, '... and is not slow');
    ok($foo == 42, '... and returns the expected result');
    eval { $bar = $ooo->bar(0) };
    my $t4 = time;
    ok(!$@, 'method call from blessed bg_eval return val ok again')
        or diag '$@(',__LINE__,') was ', $@;
    ok($t4-$t3 < 3, 'second method call from bg_eval is fast');
    ok($bar == 19, '... and returns the expected result');
    eval { $baz = $ooo->baz() };
    ok($@ && $@ =~ /Can't locate object method "baz"/,
       'bad method call from blessed bg_eval fails')
        or diag '$@(',__LINE__,') was ', $@;
    ok(!defined $baz, 'no value assigned from bad func call');
}

########
