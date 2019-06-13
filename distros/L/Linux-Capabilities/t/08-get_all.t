use Test::More;
use Test::Deep;
use Test::Exception;

use Linux::Capabilities;

my $cap = Linux::Capabilities->new("cap_chown=pi cap_kill=e");

cmp_deeply($cap->get_all, {
    cap_chown => {
        effective => 0,
        permitted => 1,
        inheritable => 1,
    },
    cap_kill => {
        effective => 1,
        permitted => 0,
        inheritable => 0,
    },
}, "get_all capabilities");

done_testing;