use strict;
use warnings;
use Test::More;
# Test static variables

# this is needed to avoid false passes if was done first without 'info'
use Inline CPP => config => force_build => 1, clean_after_build => 0;

use Inline CPP => <<'END';
class Foo {
  public:
    Foo()  {}
    ~Foo() {}
    static int get_thing() { return s_thing; }
  private:
    static int s_thing;
};

int Foo::s_thing = 10;

END

is(
    Foo->new->get_thing, 10,
    "Static variables within a class."
);

done_testing();
