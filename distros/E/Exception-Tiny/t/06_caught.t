use strict;
use warnings;
use Test::More;
use t::lib::MyExceptions;

subtest 'no exception' => sub {
    my $ok = 0;
    $ok++  unless MyException1->caught;
    $ok++  unless MyException2->caught;
    $ok++  unless MyException3->caught;
    $ok++  unless MyException4->caught;
    is $ok, 4;
};


subtest 'MyException1' => sub {
    my $ok = 0;
    eval {
        MyException1->throw;
    };
    my $e = $@;
    $ok++  if     MyException1->caught($e);
    $ok++  unless MyException2->caught($e);
    $ok++  unless MyException3->caught($e);
    $ok++  unless MyException4->caught($e);
    is $ok, 4;
};

subtest 'MyException2' => sub {
    my $ok = 0;
    eval {
        MyException2->throw;
    };
    my $e = $@;
    $ok++  if     MyException1->caught($e);
    $ok++  if     MyException2->caught($e);
    $ok++  unless MyException3->caught($e);
    $ok++  unless MyException4->caught($e);
    is $ok, 4;
};

subtest 'MyException3' => sub {
    my $ok = 0;
    eval {
        MyException3->throw;
    };
    my $e = $@;
    $ok++  if     MyException1->caught($e);
    $ok++  unless MyException2->caught($e);
    $ok++  if     MyException3->caught($e);
    $ok++  unless MyException4->caught($e);
    is $ok, 4;
};

subtest 'MyException4' => sub {
    my $ok = 0;
    eval {
        MyException4->throw;
    };
    my $e = $@;
    $ok++  if     MyException1->caught($e);
    $ok++  unless MyException2->caught($e);
    $ok++  if     MyException3->caught($e);
    $ok++  if     MyException4->caught($e);
    is $ok, 4;
};

done_testing;
