use strict;
use warnings;
use Test::More;

# this is needed to avoid false passes if was done first without 'info'
use Inline CPP => config => force_build => 1, clean_after_build => 0;

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
