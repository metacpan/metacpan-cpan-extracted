use strict;
use warnings;
use Test::More;

use Inline CPP => <<'END';
class Foo {
  public:
    Foo()  {}
    ~Foo() {}
    const char *data() { return "Hello dolly!\n"; }
};

END


is(
    Foo->new->data, "Hello dolly!\n",
    "Instantiate object and invoke member function returning a const char*"
);

done_testing();
