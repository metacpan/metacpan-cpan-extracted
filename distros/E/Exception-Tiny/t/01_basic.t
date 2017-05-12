use strict;
use warnings;
use Test::More;
use t::lib::MyException;

eval {
    t::lib::MyException->throw('error!');
};

my $E = $@;
isa_ok($E, 'Exception::Tiny');
like $E->file, qr/01_basic\.t$/;
is $E->package, 'main';
is $E->line, 7;
is $E->message, 'error!';
like "$E", qr/error! at .+01_basic\.t line 7./;
like $E->dump, qr/'t::lib::MyException'/;

done_testing;
