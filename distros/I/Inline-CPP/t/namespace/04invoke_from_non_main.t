package Bar; ## no critic (package)

use strict;
use warnings;

use Inline CPP => config => namespace => '';

use Inline CPP => <<'EOCPP';

class Foo {
  private:
    int a;
  public:
    Foo() :a(10) {}
    int fetch () { return a; }
};
EOCPP

package Baz;

use Test::More;

is __PACKAGE__, 'Baz', "Instantiating from package Baz.";

can_ok 'Foo', 'new';
can_ok 'main::Foo', 'new';
can_ok 'Foo', 'fetch';
can_ok 'main::Foo', 'fetch';
my $f = new_ok 'Foo';
ok( (ref($f) eq 'Foo' || ref($f) eq 'main::Foo'), 'Our "Foo" is a "Foo"');
is $f->fetch, 10, 'Proper object method association from Foo.';

done_testing();

package main;
