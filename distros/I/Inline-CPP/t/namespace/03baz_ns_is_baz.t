package Ball; ## no critic (package)

use strict;
use warnings;

# this is needed to avoid false passes if was done first without 'info'
use Inline CPP => config => force_build => 1, clean_after_build => 0,
  namespace => 'Baz';

use Inline CPP => <<'EOCPP';

class Foo {
  private:
    int a;
  public:
    Foo() :a(10) {}
    int fetch () { return a; }
};
EOCPP

use Inline CPP => <<'EOCPP';

class Bar {
  private:
    int a;
  public:
    Bar() :a(20) {}
    int fetch () { return a; }
};
EOCPP

package main;
use Test::More;

can_ok 'Baz::Foo', 'new';
my $f = new_ok 'Baz::Foo';
is ref($f), 'Baz::Foo', 'Our "Foo" is a "Baz::Foo"';

can_ok 'Baz::Bar', 'new';
my $fb = new_ok 'Baz::Bar';
is ref($fb), 'Baz::Bar', 'Our "Bar" is a "Baz::Bar"';

is $f->fetch, 10, 'Proper object method association from Baz::Foo.';
is $fb->fetch, 20, 'Proper object method association from Baz::Bar.';

done_testing();
