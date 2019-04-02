package Fuu; ## no critic (package)

## no critic (eval)

use Test::More;

use strict;
use warnings;

my $res0 = eval q[

  use Inline CPP => config => namespace => 'BurBat' => classes => 'MyFuu',
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

]; # End of eval.

ok !$res0, 'Invalid classes croaks.';
like $@,
  qr/is not a valid code reference or hash reference of class mappings\./,
  'Correct message.';

my $res1 = eval q[

  use Inline CPP => config =>
    force_build => 1, clean_after_build => 0,
    namespace => 'BurBat',
    classes   => { '!@#$' => 'MyFuu'};
    
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

]; # End of eval.

ok !$res1, 'Invalid C++ CLASS croaks.';
like $@, qr/is not a supported C\+\+ class\./, 'Correct message.';

my $res2 = eval q[
  use Inline CPP => config =>
    force_build => 1, clean_after_build => 0,
    namespace => 'BurBat',
    classes   => { 'Fuu' => '!@#$'};
    
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

]; # End of eval.

ok !$res2, 'Invalid Perl CLASS croaks.';
like $@, qr/is not a supported Perl class\./, 'Correct message.';

done_testing();
