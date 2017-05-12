package main; ## no critic (package)

use strict;
use warnings;

use Inline CPP => config => namespace => 'main';

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

can_ok 'Foo', 'new';
can_ok 'main::Foo', 'new';
my $f = new_ok 'Foo';
ok( (ref($f) eq 'Foo' || ref($f) eq 'main::Foo'), 'Our "Foo" is a "Foo"');

can_ok 'Bar', 'new';
can_ok 'main::Bar', 'new';
my $fb = new_ok 'Bar';
ok( (ref($fb) eq 'Bar' || ref($fb) eq 'main::Bar' ), 'Our "Bar" is a "Bar"');

is $f->fetch, 10, 'Proper object method association from Foo.';
is $fb->fetch, 20, 'Proper object method association from Bar.';

done_testing();
