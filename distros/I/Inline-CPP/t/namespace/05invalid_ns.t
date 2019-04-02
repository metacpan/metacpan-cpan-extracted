package Foo; ## no critic (package)

## no critic (eval)

use Test::More;

use strict;
use warnings;

# this is needed to avoid false passes if was done first without 'info'
use Inline CPP => config => force_build => 1, clean_after_build => 0,
  namespace => '!@#$';

my $res = eval q[
  use Inline CPP => <<'EOCPP';
  class Foo {
    private:
      int a;
    public:
      Foo() :a(10) {}
      int fetch () { return a; }
  };
EOCPP
  1;
];

ok !$res, 'Invalid namespace croaks.';
like $@, qr/is an invalid package name\./, 'Correct message.';

done_testing();
