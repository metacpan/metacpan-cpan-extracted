use Test::More tests => 12;

BEGIN { delete $::{'fail'}; }   # we export a 'fail'

BEGIN { use_ok('Logic::Easy') }

{
    is(ref var my $X, 'Logic::Variable', 'var');
    is(ref $X, 'Logic::Variable', 'var as mutator');

    is(scalar(vars my ($x, $y, $z)), 3, 'three variables declared');
    is(ref $x, 'Logic::Variable', 'x is a var');
    is(ref $y, 'Logic::Variable', 'y is a var');
    is(ref $z, 'Logic::Variable', 'z is a var');
}

eval {
    var my $X;
    Logic->is($X, 42)->bind($X);
    is($X, 42, 'Simple unification bind');
    1;
} or ok(0, 'Simple unification bind');

eval {
    Logic->is(2, 3)->bind;
    1;
} ? ok(0, 'Void failing bind')
  : ok(1, 'Void failing bind');

eval {
    var my $X;
    if (Logic->is($X, 42)->bind($X)) {
        is($X, 42, 'conditional binding');
    }
    else {
        ok(0, 'conditional binding');
    }
    1;
} || ok(0, 'conditional binding');

eval {
    var my $X;
    unless (Logic->is($X, 42)->is($X, 43)->bind($X)) {
        is(ref $X, 'Logic::Variable', 'variables stay variables after a failed binding');
    }
    else {
        ok(0, "it shouldn't have succeeded");
    }
} || ok(0, 'bind threw exception when should have returned false');

eval {
    print "A\n";
    var my $X;
    print "B\n";
    my $count = 0;
    print "C\n";
    Logic->for($X, 1..10)->bind($X, sub {
    print "D\n";
        $count++;
        fail unless $X == 6;
    });
    print "E\n";
    is($count, 6, 'bind with closure');
    print "F\n";
    1;
} || ok(0, "for predicate failed when it shouldn't have");
    

# vim: ft=perl :
