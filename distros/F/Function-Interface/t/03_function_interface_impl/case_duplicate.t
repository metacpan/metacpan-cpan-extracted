use Test2::V0;
our $COUNT_ASSERT_VALID;

BEGIN {
    require Function::Interface::Impl;

    no strict qw(refs);
    no warnings qw(redefine);
    *{Function::Interface::Impl::assert_valid} = sub {
        $COUNT_ASSERT_VALID++;
    }
}

BEGIN {
    is @Function::Interface::Impl::CHECK_LIST, 0;
    is $COUNT_ASSERT_VALID, undef;
}

use Function::Interface::Impl qw(IFoo);

is @Function::Interface::Impl::CHECK_LIST, 0;
is $COUNT_ASSERT_VALID, 1;

done_testing;
