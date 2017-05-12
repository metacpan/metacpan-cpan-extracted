use strict;
use warnings;
use Test::More;

## no critic (eval)

# Test multidimensional arrays as member data.

eval <<'EOILCPP';
  use Inline CPP => q/
    class Foo {
      public:
        Foo()  { a[0][0] = 00; a[9][0] = 90; a[0][9] = 9; a[9][9] = 99; }
        int tl() { return a[0][0]; }
        int bl() { return a[9][0]; }
        int tr() { return a[0][9]; }
        int br() { return a[9][9]; }
      private:
        int a[10][10];
    };
  /;
  1;
EOILCPP

TODO: {
  local $TODO = 'C++ multi-dimensional arrays as member data not supported.';

  is( $@, '', 'Compilation completed without exception.' );

  my $f = new_ok( 'Foo' );
  can_ok( 'Foo', qw( new tl bl tr br ) );

  my( $tl, $bl, $tr, $br ) = eval { ( $f->tl, $f->bl, $f->tr, $f->br ) };

  ok( defined($tl) && $tl == 0, 'tl() fetches proper element.' );
  ok( defined($bl) && $bl == 0, 'bl() fetches proper element.' );
  ok( defined($tr) && $tr == 0, 'tr() fetches proper element.' );
  ok( defined($br) && $br == 0, 'br() fetches proper element.' );

};

done_testing();
