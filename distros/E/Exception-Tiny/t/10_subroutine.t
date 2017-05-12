use strict;
use warnings;
use Test::More;
use t::lib::MyExceptions;

sub one {
    MyException1->throw('oops');
}

eval { one() };
is $@->subroutine, 'main::one';

eval {
    MyException1->throw('oops');
};
is $@->subroutine, '(eval)';

eval {
    sub {
        MyException1->throw('oops');
    }->();
};
is $@->subroutine, 'main::__ANON__';

{
    local $SIG{__DIE__} = sub {
        my $e = shift;
        is $e->subroutine, undef;
        done_testing;
        exit;
    };
    MyException1->throw('oops');
};

