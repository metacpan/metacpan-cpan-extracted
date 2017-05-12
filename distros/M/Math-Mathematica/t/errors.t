use strict;
use warnings;

use Test::More;
use Math::Mathematica;

my $math = Math::Mathematica->new( warn_after => 1 );
isa_ok( $math, 'Math::Mathematica' );

{
  no warnings 'redefine';
  my $delay = 0;
  local *IO::Pty::Easy::read = sub { return $delay++ ? "Out[1]= 7\nIn[2]:= " : undef };
  my $warn = 0;
  local $SIG{__WARN__} = sub { $warn++ };
  $math->evaluate('3+4');
  ok( $warn, "Caught warning" );
}

done_testing;

