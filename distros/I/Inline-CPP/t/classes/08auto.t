package Ball;    ## no critic (package)

use strict;
use warnings;

use Inline CPP => config => classes => sub { join('::', split('__', shift)); };

use Inline CPP => <<'EOCPP';
  class MyClass {
    private:
      int a;  
    public:
      MyClass() :a(5) {}
      int fetch () { return a; }
  };
  class Foo__Bar__MyClass {
    private:
      int a;
    public:
      Foo__Bar__MyClass() :a(10) {}
      int fetch () { return a; }
  };
  class Foo__Qux__MyClass {
    private:
      int a;
    public:
      Foo__Qux__MyClass() :a(20) {}
      int fetch () { return a; }
      int other_fetch () { Foo__Bar__MyClass mybar; return mybar.fetch(); }
  };
EOCPP

package main;
use Test::More;

can_ok 'MyClass', 'new';
my $m = new_ok 'MyClass';
is ref($m), 'MyClass', 'Our "MyClass" is a "MyClass"';

can_ok 'Foo::Bar::MyClass', 'new';
my $fb = new_ok 'Foo::Bar::MyClass';
is ref($fb), 'Foo::Bar::MyClass',
  'Our "Foo__Bar__MyClass" is a "Foo::Bar::MyClass"';

can_ok 'Foo::Qux::MyClass', 'new';
my $fq = new_ok 'Foo::Qux::MyClass';
is ref($fq), 'Foo::Qux::MyClass',
  'Our "Foo__Qux__MyClass" is a "Foo::Qux::MyClass"';

is $m->fetch,  5, 'Proper object method association from MyClass.';
is $fb->fetch,  10, 'Proper object method association from Foo::Bar::MyClass.';
is $fq->fetch, 20, 'Proper object method association from Foo::Qux::MyClass.';
is $fq->other_fetch, 10,
  'Proper cross-class method association from Foo::Qux::MyClass.';

done_testing();
