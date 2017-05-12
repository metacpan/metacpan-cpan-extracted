use Test::More tests => 31;

BEGIN { use_ok('Logic::Stack') }
BEGIN { use_ok('Logic::Basic') }
BEGIN { use_ok('Logic::Data', qw<resolve>) }

my $prim;
$prim = Logic::Stack->new(Logic::Basic::Identity->new);
ok($prim->run, "identity succeeds");
ok(!$prim->backtrack, "identity fails on backtrack");

$prim = Logic::Stack->new(Logic::Basic::Fail->new);
ok(!$prim->run, "fail fails");

my $count = 0;
$prim = Logic::Stack->new(Logic::Basic::Assertion->new(sub { ++$count }));
is($count, 0, "assertion doesn't run the code until entered");
ok($prim->run, "assertion succeeds on true");
is($count, 1, "and actually ran the code");
ok(!$prim->backtrack, "assertion fails on backtrack");
is($count, 1, "and didn't run the code");

$prim = Logic::Stack->new(Logic::Basic::Assertion->new(sub { 0 }));
ok(!$prim->run, "assertion fails on false");

$count = 0;
$prim = Logic::Stack->new(Logic::Basic::Rule->new(sub { $count++ }));
ok(!$prim->run, "rule fails on false");
is($count, 1, "and actually ran the code");

$count = 0;
$prim = Logic::Stack->new(Logic::Basic::Rule->new(sub { $count++; Logic::Basic::Identity->new }));
ok($prim->run, "rule delegates identity");
ok(!$prim->backtrack, "even on backtracking");
is($count, 1, "and ran the code once");

my $X = Logic::Variable->new;
$prim = Logic::Stack->new(Logic::Basic::Bound->new($X));
ok(!$prim->run, "unbound variable not bound");

$prim = Logic::Stack->new(Logic::Basic::Sequence->new(
            Logic::Data::Unify->new(
                $X,
                42,
            ),
            Logic::Basic::Bound->new($X),
        ));
ok($prim->run, "bound variable bound");

$count = 0;
$prim = Logic::Stack->new(Logic::Data::Assign->new(sub { $count++; 42 }, $X));
is($count, 0, "code not run before enter");
ok($prim->run, "assignment happened");
is($count, 1, "code was run");
is(resolve($X, $prim->state), 42, "assignment happened correctly");

my $Y = Logic::Variable->new;

$count = 0;
$prim = Logic::Stack->new(Logic::Data::Assign->new(sub { $count++; (42, ['hello']) }, $X, [$Y]));
ok($prim->run, "assignment happened");
is($count, 1, "code was run");
is(resolve($X, $prim->state), 42, "first element worked");
is(resolve($Y, $prim->state), 'hello', "second element/unification assign worked");

$count = 0;
$prim = Logic::Stack->new(Logic::Basic::Sequence->new(
            Logic::Data::For->new($X, 1..10),
            Logic::Basic::Assertion->new(sub { ++$count }),
            Logic::Data::Unify->new($X, 6),
        ));
ok($prim->run, "found one");
is($count, 6, "tried six things");
is(resolve($X, $prim->state), 6, "turns out that it's six");
ok(!$prim->backtrack, "nothing on backtrack");

# vim: ft=perl :
