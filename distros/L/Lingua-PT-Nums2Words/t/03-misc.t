use Test::More tests => 15;

BEGIN { use_ok('Lingua::PT::Nums2Words', 'num2word') };

@a=num2word(1,2,3);
@b=qw(um dois três);

while ($a = shift @a) {
  $b = shift @b;
  is($a,$b);
}

@a=num2word(1..1000);
@b=(1..1000);
is(@a,@b);

@a=num2word(1..10);
@b=qw(um dois três quatro cinco seis sete oito nove dez);

while ($a = shift @a) {
  $b = shift @b;
  is($a,$b);
}
