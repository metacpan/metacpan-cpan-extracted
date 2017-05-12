#!/usr/bin/perl -w

BEGIN {
  use Test::Inter;
  $t = new Test::Inter 'List';
}

BEGIN { $t->use_ok('List::Parseable'); }

sub test {
  (@test)=@_;
  my $obj = new List::Parseable;
  $obj->list("a",@test);
  return $obj->eval("a");
}

$tests = "
  scalar a b  => a b

  [ a ] [ b ] => a b

  count => 0

  count a b => 2

  count [ list a b ] c => 2

  compact a '' [ c ] [a 0] => a c a 0

  compact a __blank__ [ c ] [a 0] => a c a 0

  true a '' [c] [a 0] => a c a

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

