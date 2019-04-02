package main; ## no critic (package)

use strict;
use warnings;

# this is needed to avoid false passes if was done first without 'info'
use Inline CPP => config => force_build => 1, clean_after_build => 0,
  namespace => '';

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
can_ok 'Foo', 'fetch';
can_ok 'main::Foo', 'fetch';
my $f = new_ok 'Foo';
ok( ( ref($f) eq 'Foo' || ref($f) eq 'main::Foo' ), 'Our "Foo" is a "Foo"');

can_ok 'Bar', 'new';
my $fb = Bar->new;
ok( ( ref($fb) eq 'Bar' || ref($fb) eq 'main::Bar' ), 'Our "Bar" is a "Bar"');

is $f->fetch, 10, 'Proper object method association from Foo.';
is $fb->fetch, 20, 'Proper object method association from Bar.';

done_testing();
