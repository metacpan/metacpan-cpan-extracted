#!/usr/bin/perl -w

BEGIN {
  use Test::Inter;
  $t = new Test::Inter 'Vars';
}

BEGIN { $t->use_ok('List::Parseable'); }

sub test {
  (@test)=@_;
  $obj->string("a",@test);
  return $obj->eval("a");
}

$obj = new List::Parseable;
%hash = ( "scal1"    => "foo",
          "scal2"    => "bar",
          "num1"     => 7,
          "num2"     => 9,
          "list1"    => [ 'm','n','p' ],
          "list2"    => [ 'h','i','j' ],
          "nlist1"   => [ 5,6,7 ],
          "nlist2"   => [ 20,22,24 ] );
$obj->vars(%hash);

$tests = "

'(getvar scal1)' => foo

'(getvar list2)' => h i j

'(getvar fake)' => __undef__

'( + (getvar nlist1) )' => 18

'(difference (list getvar nlist2) (list 22))' => 20 24

'(getvar scal3)' => __undef__

'(setvar scal3 baz)' => baz

'(getvar scal3)' => baz

'(unsetvar scal3)' => __undef__

'(getvar scal3)' => __undef__

'(popvar list1)' => p

'(getvar list1)' => m n

'(shiftvar list2)' => h

'(getvar list2)' => i j

'(unshiftvar list3 x)' => __undef__

'(getvar list3)' => x

'(unshiftvar list3 y)' => __undef__

'(getvar list3)' => y x

'(pushvar list4 u)' => __undef__

'(getvar list4)' => u

'(pushvar list4 v)' => __undef__

'(getvar list4)' => u v

'(getvar num3)' => __undef__

'(default num3 5)' => 5

'(getvar num3)' => 5

'(setvar num3 10)' => 10

'(getvar num3)' => 10

'(default num3 5)' => 10

'(getvar num3)' => 10

";

$t->tests(func  => \&test,
          tests => $tests);
$t->done_testing();


1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 3
# cperl-continued-statement-offset: 2
# cperl-continued-brace-offset: 0
# cperl-brace-offset: 0
# cperl-brace-imaginary-offset: 0
# cperl-label-offset: -2
# End:

