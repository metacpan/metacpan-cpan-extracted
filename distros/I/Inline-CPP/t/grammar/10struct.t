use strict;
use warnings;
use Test::More;

use Inline CPP => <<'END';

struct Fizzle {
  int q;
  double foozle;
  int quack;
  Fizzle(int Q=0, double Foozle=0, int Quack=0) {
    q = Q;
    foozle = Foozle;
    quack = Quack;
  }
  int get_q() { return q; }
  double get_foozle() { return foozle; }
  int get_quack() { return quack; }
};

END

my $o = new_ok( 'Fizzle' );

is(
    $o->get_q, 0,
    "Struct with public member function."
);

done_testing();
