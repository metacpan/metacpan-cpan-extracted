use strict;
use Test::More;
BEGIN {
   use_ok('Math::Random::MT', qw(srand rand irand));
}


# Check that it's possible to call rand() without srand()

my ($num1, $num2);

eval { $num1 = rand; };
is $@, '', '$@ should be empty after rand() but it\'s: '.$@;
isnt $num1, undef;
cmp_ok $num1, '>=', 0;
cmp_ok $num1, '<', 1; # rand without argument is like rand(1)
eval { $num2 = rand; };
is $@, '', '$@ should also be empty the second time rand() is called';
isnt $num1, $num2;

eval { $num1 = irand; };
is $@, '', '$@ should be empty after rand()';
isnt $num1, undef;
cmp_ok $num1, '>=', 0;
eval { $num2 = irand; };
is $@, '', '$@ should also be empty the second time rand() is called';
isnt $num1, $num2;

done_testing();
