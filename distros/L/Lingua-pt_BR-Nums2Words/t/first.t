use strict;
use warnings;
use Test::More;
use utf8;

BEGIN { use_ok('Lingua::pt_BR::Nums2Words', 'num2word') };

eval { num2word() };
like($@, '/No argument provided/', 'No argument provided');

eval { num2word('w') };
like($@, '/Not a workable number/', 'Cannot work on argument "w"');

eval { num2word(100000000000000000000) };
like($@, '/Not a workable number/', 'Cannot work on argument 1e+20');

eval { num2word(99999999999999999999) };
like($@, '/Not a workable number/',
     'Maximum workable number is 9999999999999999999');

eval { num2word('99999999999999999999') };
like($@, '/Not a workable number/',
     'Maximum workable number is 9999999999999999999');

is(num2word('0'), 'zero');
is(num2word('1'), 'um');

is(num2word(0), 'zero');
is(num2word(1), 'um');
is(num2word(2), 'dois');
is(num2word(3), 'três');
is(num2word(4), 'quatro');
is(num2word(5), 'cinco');
is(num2word(6), 'seis');
is(num2word(7), 'sete');

is(num2word(1100), 'mil e cem');
is(num2word(1101), 'mil cento e um');
is(num2word(1332), 'mil trezentos e trinta e dois');
is(num2word(3030), 'três mil e trinta');
is(num2word(3330), 'três mil trezentos e trinta');

is(num2word(1003332), 'um milhão, três mil trezentos e trinta e dois');
is(num2word(1_001_032), 'um milhão, mil e trinta e dois');
is(num2word(3003332), 'três milhões, três mil trezentos e trinta e dois');
is(num2word(200000300), 'duzentos milhões e trezentos');
is(num2word(200300000), 'duzentos milhões e trezentos mil');
is(num2word(200300001), 'duzentos milhões, trezentos mil e um');
is(num2word(200300400), 'duzentos milhões, trezentos mil e quatrocentos');
is(num2word(200300401), 'duzentos milhões, trezentos mil quatrocentos e um');

is(num2word(1001003332),
   'um bilhão, um milhão, três mil trezentos e trinta e dois');
is(num2word(200000000001), 'duzentos bilhões e um');
is(num2word(200000001001), 'duzentos bilhões, mil e um');

is(num2word(1_000_000_000_002), 'um trilhão e dois');
is(num2word(1_000_000_001_002), 'um trilhão, mil e dois');
is(num2word(1_000_001_000_002), 'um trilhão, um milhão e dois');
is(num2word(3001001003332),
   'três trilhões, um bilhão, um milhão, três mil trezentos e trinta e dois');
is(num2word(3_000_000_000_002), 'três trilhões e dois');

done_testing;
