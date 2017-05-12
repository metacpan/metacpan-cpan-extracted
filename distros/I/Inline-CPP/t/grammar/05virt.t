use strict;
use warnings;
use Test::More;


use Inline CPP => <<'END';
class Foo {
  public:
    Foo() { }
    ~Foo() { }

    virtual const char *get_data_ro() { return "Hello Sally!\n"; }
};
END


is(
    Foo->new->get_data_ro, "Hello Sally!\n",
    "Define and invoke virtual function."
);

done_testing();
