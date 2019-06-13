use Test::More;
use Test::Deep;

use Linux::Capabilities;

my $str = "cap_chown+ep cap_kill=i";

my $cap = Linux::Capabilities->new($str);

cmp_deeply($cap->get_value(CAP_CHOWN), {
    effective => 1,
    permitted => 1,
    inheritable => 0,
}, "get cap_chown flags");

is $cap->get_value_flag(CAP_CHOWN, CAP_EFFECTIVE), 1;
is $cap->get_value_flag(CAP_CHOWN, CAP_PERMITTED), 1;
is $cap->get_value_flag(CAP_CHOWN, CAP_INHERITABLE), 0;

cmp_deeply($cap->get_value(CAP_KILL), {
    effective => 0,
    permitted => 0,
    inheritable => 1,
}, "get cap_kill flags");

is $cap->get_value_flag(CAP_KILL, CAP_EFFECTIVE), 0;
is $cap->get_value_flag(CAP_KILL, CAP_PERMITTED), 0;
is $cap->get_value_flag(CAP_KILL, CAP_INHERITABLE), 1;

done_testing;