use Test::More;
use Test::Deep;
use Test::Exception;

use Linux::Capabilities;

my $cap = Linux::Capabilities->empty;

$cap->raise([CAP_CHOWN, CAP_KILL], [CAP_EFFECTIVE, CAP_PERMITTED]);

cmp_deeply($cap->get_value(CAP_CHOWN), {
    effective => 1,
    permitted => 1,
    inheritable => 0,
}, "raise(many,many)");

cmp_deeply($cap->get_value(CAP_KILL), {
    effective => 1,
    permitted => 1,
    inheritable => 0,
}, "raise(many,many)");

$cap->raise([CAP_CHOWN, CAP_KILL], CAP_INHERITABLE);

cmp_deeply($cap->get_value(CAP_CHOWN), {
    effective => 1,
    permitted => 1,
    inheritable => 1,
}, "raise(many,one)");

cmp_deeply($cap->get_value(CAP_KILL), {
    effective => 1,
    permitted => 1,
    inheritable => 1,
}, "raise(many,one)");

$cap->raise(CAP_DAC_OVERRIDE, [CAP_INHERITABLE, CAP_EFFECTIVE]);

cmp_deeply($cap->get_value(CAP_DAC_OVERRIDE), {
    effective => 1,
    permitted => 0,
    inheritable => 1,
}, "raise(one,many)");

$cap->raise(CAP_DAC_OVERRIDE, CAP_PERMITTED);

cmp_deeply($cap->get_value(CAP_DAC_OVERRIDE), {
    effective => 1,
    permitted => 1,
    inheritable => 1,
}, "raise(one,one)");

$cap->raise([CAP_FOWNER, CAP_FSETID]);

cmp_deeply($cap->get_value(CAP_FOWNER), {
    effective => 1,
    permitted => 1,
    inheritable => 1,
}, "raise(many)");

cmp_deeply($cap->get_value(CAP_FSETID), {
    effective => 1,
    permitted => 1,
    inheritable => 1,
}, "raise(many)");

$cap->raise(CAP_SETGID);

cmp_deeply($cap->get_value(CAP_FOWNER), {
    effective => 1,
    permitted => 1,
    inheritable => 1,
}, "raise(one)");

$cap->raise;

foreach (1..37) {
    cmp_deeply($cap->get_value($_), {
        effective => 1,
        permitted => 1,
        inheritable => 1,
    }, "raise()");
}

throws_ok(sub { $cap->raise(-1); }, qr/not supported value:/, "raising bad capabilitie");
throws_ok(sub { $cap->raise(0,-1); }, qr/not supported flag:/, "raising bad capabilitie flag");

done_testing;