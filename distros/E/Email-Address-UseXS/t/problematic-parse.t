use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Email::Address::UseXS;

is(exception {
    local $SIG{ALRM} = sub {
        die 'alarm';
    };
    alarm(2);
    Email::Address->parse("\f" x 23);
    alarm(0);
}, undef, 'problematic parse completes quickly');

done_testing;

