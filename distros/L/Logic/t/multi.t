use Test::More tests => 13;

no warnings 'redefine';

BEGIN { delete $::{fail} }  # we export a fail
BEGIN { use_ok('Logic::Easy') }

sub a : Multi(a) {
    sig([1])->bind;
    "One";
}

sub a : Multi(a) {
    sig([2])->bind;
    "Two";
}

sub a : Multi(a) {
    var my $x;
    sig([$x])->bind($x);
    $x;
}

is(a(1), "One", "variant one");
is(a(2), "Two", "variant two");
is(a(3), 3,     "variant three");

sub b : Multi(b) {
    SIG [1];
    "one";
}

sub b : Multi(b) {
    SIG [2];
    "two";
}

sub b : Multi(b) {
    SIG [$x];
    $x;
}

is(b(1), "one", "variant one");
is(b(2), "two", "variant two");
is(b(3), 3,     "variant three");

sub fibo : Multi(fibo) {
    print "fibo- @_\n";
    SIG [$x] where { $x < 2 };
    1;
}

sub fibo : Multi(fibo) {
    print "fibo+ @_\n";
    SIG [$x];
    fibo($x-1) + fibo($x-2);
}

is(fibo(0), 1, "fibo(0) == 1");
is(fibo(1), 1, "fibo(1) == 1");
is(fibo(2), 2, "fibo(2) == 2");
is(fibo(3), 3, "fibo(3) == 3");
is(fibo(4), 5, "fibo(4) == 5");

sub qsort : Multi(qsort) {
    SIG [];
    return ();
}

sub qsort : Multi(qsort) {
    SIG cons($x, $xs);
    my @pre  = grep { $_ < $x } @$xs;
    my @post = grep { $_ >= $x } @$xs;
    return (qsort(@pre), $x, qsort(@post));
}

is_deeply([ qsort(6,2,1,5,3,4) ], [ 1,2,3,4,5,6 ], "quicksort");

# vim: ft=perl :
