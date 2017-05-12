use strict;
use warnings;
BEGIN {
  $ENV{DEVEL_CONFESS_OPTIONS} = '';
}
use Test::More tests => 1;
use lib 't/lib';
use Capture capture_color => ['-MDevel::Confess=color=force'];

is capture_color <<"END_CODE",
package A;

sub f {
#line 1 test-block.pl
    die "Beware!";
}

sub g {
#line 2 test-block.pl
    f();
}

package main;

#line 3 test-block.pl
A::g();
END_CODE
  <<"END_OUTPUT",
\e[31mBeware!\e[m at test-block.pl line 1.
\tA::f() called at test-block.pl line 2
\tA::g() called at test-block.pl line 3
END_OUTPUT
  'error message properly colorized';
