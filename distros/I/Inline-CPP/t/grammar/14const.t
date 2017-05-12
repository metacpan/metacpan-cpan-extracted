use strict;
use warnings;
use Test::More;

use Inline CPP => <<'END';
class Foo {
  public:
    Foo()  {}
    ~Foo() {}
    char *data() const { return "Hello dolly!\n"; }
};

END


is(
    Foo->new->data, "Hello dolly!\n",
    "Constant member function."
);

done_testing();
