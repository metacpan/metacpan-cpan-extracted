use strict;
use warnings;
use Test::More;
use t::lib::MyExceptions;

eval {
    MyException1->throw;
};
is $@->message, 'MyException1';
like $@, qr/MyException1 from main/;

eval {
    MyException2->throw;
};
is $@->message, 'MyException2';
like $@, qr/MyException2 from main/;


eval {
    MyException3->throw('');
};
is $@->message, 'MyException3';
like $@, qr/MyException3 from main/;


eval {
    MyException4->throw(0);
};
is $@->message, '0';
like $@, qr/0 from main/;


done_testing;
