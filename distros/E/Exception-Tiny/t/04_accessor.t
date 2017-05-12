use strict;
use warnings;
use Test::More;
use t::lib::MyExceptions;

eval {
    MyException4->throw(
        message       => 'foo',
        my_exception3 => '3',
        my_exception4 => '4',
    );
};

my $E = $@;

is $E->my_exception3, '3';
is $E->my_exception4, '4';

done_testing;
