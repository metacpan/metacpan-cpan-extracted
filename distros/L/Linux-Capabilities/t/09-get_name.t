use Test::More;
use Test::Exception;

use Linux::Capabilities;

my $str = "cap_kill+ep";

my $cap = Linux::Capabilities->empty;
is (lc $cap->get_name(CAP_CHOWN), "cap_chown");
is (lc $cap->get_name(CAP_AUDIT_READ), "cap_audit_read");

is (lc Linux::Capabilities::get_name(CAP_CHOWN), "cap_chown");
is (lc Linux::Capabilities::get_name(CAP_AUDIT_READ), "cap_audit_read");

my $bad_val = -1;
throws_ok(sub { $cap->get_name($bad_val); }, qr/bad value: $bad_val/, "get_name on not existing capabilitie");

done_testing;