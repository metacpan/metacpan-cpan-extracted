use strict;
use warnings;
use Test::More;
use t::lib::MyExceptions;

eval {
    MyException1->throw;
};

my $e = $@;
eval {
    $e->rethrow if MyException1->caught($e);
};

my $e2 = $@;
ok( MyException1->caught($e2) );

done_testing;
