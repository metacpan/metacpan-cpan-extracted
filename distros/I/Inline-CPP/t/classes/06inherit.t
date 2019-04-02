## no critic (package)

package Fuu;

use strict;
use warnings;

use Inline CPP => config => namespace => q{} => classes => { 'Fuu' => 'MyFuu'},
    force_build => 1, clean_after_build => 0;

use Inline CPP => <<'EOCPP';

  class Fuu {
    private:
      int a;
    public:
      Fuu() :a(10) {}
      int fetch () { return a; }
  };

EOCPP

1;

package Bur;

our @ISA = ('MyFuu');
sub myfetch { my $self = shift; $self->fetch(); }


package main;
use Test::More;

can_ok 'MyFuu', 'new';
my $f = new_ok 'MyFuu';
is ref($f), 'MyFuu', 'Our "Fuu" is a "MyFuu".';
is $f->fetch, '10', 'Accessor properly associated.';


can_ok 'Bur', 'new';
my $bf = new_ok 'Bur';
is ref($bf), 'Bur', 'Our "Bur" is a "Bur"';
is $bf->fetch, 10, 
   'Inheritance and object method association from Bur.';
is $bf->myfetch, 10, 'Method resolution for subclass.';



done_testing();
