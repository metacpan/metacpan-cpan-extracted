package main; ## no critic (package)

use strict;
use warnings;

use Inline CPP => config =>
  force_build => 1, clean_after_build => 0,
  namespace => 'main',
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
my $f = new_ok 'MyFuu';
is ref($f), 'MyFuu', 'Our "Fuu" is a "MyFuu"';

can_ok 'MyBur', 'new';
can_ok 'main::MyBur', 'new';
my $fb = new_ok 'MyBur';
is ref($fb), 'MyBur', 'Our "Bur" is a "MyBur"';

is $f->fetch, 10, 'Proper object method association from main::MyFuu.';
is $fb->fetch, 20, 'Proper object method association from main::MyBur.';

done_testing();
