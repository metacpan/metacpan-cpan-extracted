use strict;
use warnings;
use Test::More;
use t::lib::MyExceptions;

eval {
    MyException2->throw(
        message => 'foo',
    );
};

my $E = $@;
isa_ok($E, 'Exception::Tiny');
isa_ok($E, 'MyException1');
isa_ok($E, 'MyException2');
like "$E", qr/foo at .+03_nest_class\.t line 7./;
like $E->dump, qr/'MyException2'/;

done_testing;
