use strict;
use warnings;
use Test::More;

# this is needed to avoid false passes if was done first without 'info'
use Inline CPP => config => force_build => 1, clean_after_build => 0;


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
