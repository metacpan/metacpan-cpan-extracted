use utf8;
use 5.014;

use lib qw(../lib);
use Math::Bacovia qw(
  Log
  Exp
  Power
  Symbol
  Product
  Fraction
  );

my $x = Symbol('x');
my $y = Symbol('y');

say $x+ $y;    #=> Sum(Symbol("x"), Symbol("y"))
say $x- $y;    #=> Sum(Symbol("x"), Product(-1, Symbol("y")))
say $x* $y;    #=> Product(Symbol("x"), Symbol("y"))
say $x/ $y;    #=> Fraction(Symbol("x"), Symbol("y"))

say $x**$y;    #=> Power(Symbol("x"), Symbol("y"))

say Log($x);              #=> Log(Symbol("x"))
say Log($x) + Log($y);    #=> Log(Product(Symbol("x"), Symbol("y")))

say Exp($x);              #=> Exp(Symbol("x"))
say Exp($x) * Exp($y);    #=> Exp(Sum(Symbol("x"), Symbol("y")))

say "\n=> Sum:";
my $sum = Fraction(0, 1);

for my $n (1 .. 10) {
    $sum += Fraction(1, $n);
}
say $sum;                 #=> Fraction(10628640, 3628800)
say $sum->numeric;        #=> 7381/2520

say "\n=> Product:";
my $prod = Product();

for my $n (1 .. 3) {
    $prod *= Exp(Fraction(1, $n));
}

say $prod;                    #=> Product(Fraction(1, 1), Exp(Fraction(1, 1)), Exp(Fraction(1, 2)), Exp(Fraction(1, 3)))
say $prod->simple->pretty;    #=> exp(11/6)
say $prod->numeric;           #=> 6.25470095193632871640207...

say "\n=> Alternative representations:";
say join ', ', Power(3, 5)->alternatives(full => 1);    #=> Power(3, 5), Exp(Product(Log(3), 5))
