use Test::More;

use Linux::Capabilities;

my $obj = Linux::Capabilities->new();

foreach (1..37) {
    is (Linux::Capabilities::is_supported($_), 1, "is_supported($_)");
}
is ($obj->is_supported(0), 1, "is_supported(0) called on object");
is (Linux::Capabilities::is_supported(38), 0, "is_supported(38)");
is (Linux::Capabilities::is_supported(-1), 0, "is_supported(-1)");

done_testing;