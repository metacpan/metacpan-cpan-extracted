use Test::More tests => 26;

BEGIN { use_ok('Logic::Stack'); }
BEGIN { use_ok('Logic::Basic'); }
BEGIN { use_ok('Logic::Data', 'resolve'); }


my $uni;
$uni = Logic::Stack->new(Logic::Data::Unify->new(1, 1));
ok($uni->run, "1 == 1");


$uni = Logic::Stack->new(Logic::Data::Unify->new(1, 2));
ok(!$uni->run, "1 != 2");


my $x = Logic::Variable->new;
$uni = Logic::Stack->new(Logic::Data::Unify->new($x, 1));
ok($uni->run, "X = 1");
is(resolve($x, $uni->state), 1, "X === 1");


$uni = Logic::Stack->new(Logic::Data::Unify->new(42, $x));
ok($uni->run, "42 = X");
is(resolve($x, $uni->state), 42, "X === 42");


my $seq;
my $y = Logic::Variable->new;
$seq = Logic::Stack->new(Logic::Basic::Sequence->new(
         Logic::Data::Unify->new(144, $x),
         Logic::Data::Unify->new($x, $y),
       ));

ok($seq->run, "144 = X, X = Y");
is(resolve($x, $seq->state), 144, "X === 144");
is(resolve($y, $seq->state), 144, "Y === 144");

$seq = Logic::Stack->new(Logic::Basic::Sequence->new(
         Logic::Data::Unify->new($x, $y),
         Logic::Data::Unify->new($y, 13),
       ));

ok($seq->run, "X = Y, Y = 13");
is(resolve($y, $seq->state), 13, "Y === 13");
is(resolve($x, $seq->state), 13, "X === 13");

$seq = Logic::Stack->new(Logic::Basic::Sequence->new(
         Logic::Data::Unify->new($x, [ 1, $y, 3 ]),
         Logic::Data::Unify->new([1, 2, 3], $x),
       ));

ok($seq->run, "X = [1, Y, 3], [1, 2, 3] = X");
is(resolve($y, $seq->state), 2, "Y === 2");
is_deeply(resolve($x, $seq->state), [1, 2, 3], "X === [1, 2, 3]");

$uni = Logic::Stack->new(Logic::Data::Unify->new(
         Logic::Data::Cons->new($x, $y),
         [ 1, 2, 3 ],
       ));

ok($uni->run, "[X|Y] = [1, 2, 3]");
is(resolve($x, $uni->state), 1, "X === 1");
is_deeply(resolve($y, $uni->state), [2, 3], "Y === [2, 3]");

$uni = Logic::Stack->new(Logic::Data::Unify->new(
         [ $x, 4, 5 ],
         Logic::Data::Cons->new($x, $y),
       ));

ok($uni->run, "[ X, 4, 5 ] = [X|Y]");

is_deeply(resolve($y, $uni->state), [4, 5], "Y === [4, 5]");
ok(!eval { resolve($x, $uni->state); 1 }, "X is unbound");

my $j = Logic::Data::Disjunction->new(1,2,3);
$uni = Logic::Stack->new(Logic::Data::Unify->new(2, $j));
ok($uni->run, "2 = 1|2|3");

$j = Logic::Data::Disjunction->new(1,2,3);
$uni = Logic::Stack->new(Logic::Data::Unify->new(4, $j));
ok(!$uni->run, "2 /= 1|2|3");

# vim: ft=perl :
