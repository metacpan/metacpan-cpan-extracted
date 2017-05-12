package main; ## no critic (package)

use strict;
use warnings;

use Inline CPP => config =>
  namespace => '',
  classes   => { 'Fuu' => 'MyFuu', 'Bur' => 'MyBur'};

use Inline CPP => <<'EOCPP';

  class Fuu {
    private:
      int a;
    public:
      Fuu() :a(10) {}
      int fetch () { return a; }
  };
EOCPP

use Inline CPP => <<'EOCPP';

  class Bur {
    private:
      int a;
    public:
      Bur() :a(20) {}
      int fetch () { return a; }
  };
EOCPP

package main;
use Test::More;

can_ok 'MyFuu', 'new';
can_ok 'main::MyFuu', 'new';
can_ok 'MyFuu', 'fetch';
can_ok 'main::MyFuu', 'fetch';
my $f = new_ok 'MyFuu';
is ref($f), 'MyFuu', 'Our "Fuu" is a "MyFuu"';

can_ok 'MyBur', 'new';
my $fb = MyBur->new;
is ref($fb), 'MyBur', 'Our "Bur" is a "MyBur"';

is $f->fetch, 10, 'Proper object method association from MyFuu.';
is $fb->fetch, 20, 'Proper object method association from MyBur.';

done_testing();
