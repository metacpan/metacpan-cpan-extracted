package Bur; ## no critic (package)

use strict;
use warnings;

use Inline CPP => config => namespace => '' => classes => { 'Fuu' => 'MyFuu'};

use Inline CPP => <<'EOCPP';

class Fuu {
  private:
    int a;
  public:
    Fuu() :a(10) {}
    int fetch () { return a; }
};
EOCPP

package Buz;

use Test::More;

is __PACKAGE__, 'Buz', "Instantiating from package Buz.";

can_ok 'MyFuu', 'new';
can_ok 'main::MyFuu', 'new';
can_ok 'MyFuu', 'fetch';
can_ok 'main::MyFuu', 'fetch';
my $f = new_ok 'MyFuu';
isa_ok $f, 'MyFuu', 'Our "Fuu" is a "MyFuu"';
is $f->fetch, 10, 'Proper object method association from MyFuu.';

done_testing();

package main;
