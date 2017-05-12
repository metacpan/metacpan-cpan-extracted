use strict;
use warnings;
use Test::More;
use t::lib::MyExceptions;

my $ok = 0;

eval {
    MyException1->throw;
};

my $e = $@;
$ok++  if MyException1->caught($e);
$ok++  if MyException1->caught($e)->package eq 'main';

is $ok, 2;

done_testing;
