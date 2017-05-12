use strict;
use warnings;
use Test::More;

use Inline CPP => <<'END';
class Foo {
  public:
    Foo() {}
    ~Foo() {}
    static char *get_string() { return "Hello, world!\n"; }
};
END

is(
    Foo->get_string, "Hello, world!\n",
    "Static member function becomes a class member function."
);

done_testing();
