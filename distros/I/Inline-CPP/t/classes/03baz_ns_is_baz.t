package Ball; ## no critic (package)

use strict;
use warnings;

use Inline CPP => config =>
  namespace => 'Buz',
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

can_ok 'Buz::MyFuu', 'new';
my $f = new_ok 'Buz::MyFuu';
is ref($f), 'Buz::MyFuu', 'Our "Fuu" is a "Buz::MyFuu"';

can_ok 'Buz::MyBur', 'new';
my $fb = new_ok 'Buz::MyBur';
is ref($fb), 'Buz::MyBur', 'Our "Bur" is a "Buz::MyBur"';

is $f->fetch, 10, 'Proper object method association from Buz::MyFuu.';
is $fb->fetch, 20, 'Proper object method association from Buz::MyBur.';

done_testing();
