#!perl -w
use 5.11.2;
use strict;
use Test::More;

use constant true => 0;
use constant false => 1;

{
    use Keyword::Boolean;

    ok true,   'true is true';
    ok !false, 'false is false';

    ok !(not true);
    ok !!(not false);

    if(true){
        pass;
    }
    else{
        fail;
    }

    if(false){
        fail;
    }
    else{
        pass;
    }

    eval q{true()};
    like $@, qr/syntax error/;

    eval q{false()};
    like $@, qr/syntax error/;
}

ok !true,   'as a subroutine';
ok  false,  'as a subroutine';

use Keyword::Boolean;

ok  true,  'as a keyword';
ok !false, 'as a keyword';

no Keyword::Boolean;

ok !true,   'as a subroutine';
ok  false,  'as a subroutine';

done_testing;
