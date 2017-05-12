use strict;

use Test::More;
use HTTP::Exception;

################################################################################
# wasn't sure whether $@ survives a subcall, but it seems it does
sub _run_tests_for_exception {
    my $e = HTTP::Exception->caught;
    ok defined $e                                   , 'HTTP::Exception caught' ;
    is $e->code, 200                                , 'HTTP::Exception has right code';
    ok defined HTTP::Exception::2XX->caught         , '2XX caught' ;
    ok defined HTTP::Exception::200->caught         , '200 caught' ;
    ok defined HTTP::Exception::OK->caught          , 'OK caught' ;
    ok !(defined HTTP::Exception::4XX->caught)      , '4XX not caught' ;
    ok !(defined HTTP::Exception::NOT_FOUND->caught), 'NOT_FOUND not caught' ;
    ok !(defined HTTP::Exception::404->caught)      , '404 not caught' ;
    ok defined Exception::Class->caught             , 'Exception::Class caught' ;
}

################################################################################
eval { HTTP::Exception::200->throw };
_run_tests_for_exception;

eval { HTTP::Exception::OK->throw };
_run_tests_for_exception;

eval { HTTP::Exception->throw(200) };
_run_tests_for_exception;

done_testing;