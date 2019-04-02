use strict;
use warnings;
use Test::More;

# this is needed to avoid false passes if was done first without 'info'
use Inline CPP => config => force_build => 1, clean_after_build => 0;

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
