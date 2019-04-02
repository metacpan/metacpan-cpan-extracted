use strict;
use warnings;
use Test::More;
# Test declarations of multiple variables in a member data list.

# this is needed to avoid false passes if was done first without 'info'
use Inline CPP => config => force_build => 1, clean_after_build => 0;

use Inline CPP => <<'END';

#define NUMBER 25
#define FOO()  25

class Foo {
  public:
    Foo(double _o) : o(_o) {}
    ~Foo() {}
    int test() { return 10; }
  private:
    int a, b;
    char *c, d;
    char *e, *f;
    char g, **h;
    double i, j, *k, **m, n, &o;

    static const int    aa = 10,
            bb = FOO(),
            cc = NUMBER,
            dd = 1.25
            ;
};

class Bar {
  public:
    Bar() { }
    ~Bar() { }
    int test() { return -1; }
};

END


is(
    Foo->new(1.23)->test, 10,
    "Declaration of multiple variables in a list."
);

is(
    Bar->new->test, -1,
    "Simple case class following multiple variables class."
);

done_testing();
