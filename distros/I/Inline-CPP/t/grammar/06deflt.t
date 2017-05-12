use strict;
use warnings;
use Test::More;

use Inline CPP => <<'END';

int foo(int a=10) { return a; }
double pi() { return 3.1415926; }

class Freak {
  public:
    Freak() {}
    ~Freak() {}

    int foo(int a=10, int b=13+4, double c=pi()) { return (a+b)/c; }
    int foo2(int a, int b=15) { return a^b; }
    int foo3(int a, int b, int c=0, int d=-5) { return 2*a - b + 2*c - d; }
    int foo4(int a, char *b="hello") { return a + strlen(b); }
};

END


is(
    Freak->new->foo, 8,
    "Instantiate object and call member with default arguments."
);

is(
    foo, 10,
    "Call simple function with default arguments."
);

done_testing();
