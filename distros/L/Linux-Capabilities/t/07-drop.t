use Test::More;
use Test::Deep;
use Test::Exception;

use Linux::Capabilities;

my $cap = Linux::Capabilities->new("all=epi");

$cap->drop([CAP_CHOWN, CAP_KILL], [CAP_EFFECTIVE, CAP_PERMITTED]);

cmp_deeply($cap->get_value(CAP_CHOWN), {
    effective => 0,
    permitted => 0,
    inheritable => 1,
}, "drop(many,many)");

cmp_deeply($cap->get_value(CAP_KILL), {
    effective => 0,
    permitted => 0,
    inheritable => 1,
}, "drop(many,many)");

$cap->drop([CAP_CHOWN, CAP_KILL], CAP_INHERITABLE);

cmp_deeply($cap->get_value(CAP_CHOWN), {
    effective => 0,
    permitted => 0,
    inheritable => 0,
}, "drop(many,one)");

cmp_deeply($cap->get_value(CAP_KILL), {
    effective => 0,
    permitted => 0,
    inheritable => 0,
}, "drop(many,one)");

$cap->drop(CAP_DAC_OVERRIDE, [CAP_INHERITABLE, CAP_EFFECTIVE]);

cmp_deeply($cap->get_value(CAP_DAC_OVERRIDE), {
    effective => 0,
    permitted => 1,
    inheritable => 0,
}, "drop(one,many)");

$cap->drop(CAP_DAC_OVERRIDE, CAP_PERMITTED);

cmp_deeply($cap->get_value(CAP_DAC_OVERRIDE), {
    effective => 0,
    permitted => 0,
    inheritable => 0,
}, "drop(one,one)");

$cap->drop([CAP_FOWNER, CAP_FSETID]);

cmp_deeply($cap->get_value(CAP_FOWNER), {
    effective => 0,
    permitted => 0,
    inheritable => 0,
}, "drop(many)");

cmp_deeply($cap->get_value(CAP_FSETID), {
    effective => 0,
    permitted => 0,
    inheritable => 0,
}, "drop(many)");

$cap->drop(CAP_SETGID);

cmp_deeply($cap->get_value(CAP_FOWNER), {
    effective => 0,
    permitted => 0,
    inheritable => 0,
}, "drop(one)");

$cap->drop;

foreach (0..37) {
    cmp_deeply($cap->get_value($_), {
        effective => 0,
        permitted => 0,
        inheritable => 0,
    }, "drop()");
}

throws_ok(sub { $cap->drop(-1); }, qr/not supported value:/, "droping bad capabilitie");
throws_ok(sub { $cap->drop(0,-1); }, qr/not supported flag:/, "droping bad capabilitie flag");

done_testing;