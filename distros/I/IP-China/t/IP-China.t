use warnings;
use strict;
use Test::More;
BEGIN { use_ok('IP::China') };
use IP::China 'chinese_ip';

my @tests = (
    # Not Chinese
    ['110.3.244.53' => 0],
    ['68.194.123.246' => 0],
    ['165.79.254.192' => 0],
    # Chinese
    ['101.226.166.226' => -1],
    ['182.118.22.206' => -1],
    ['182.118.20.178' => -1],
    ['182.118.25.237' => -1],
    # Test extrema
    ['255.255.255.255' => 0],
    ['0.0.0.0' => 0],
    # Test IPs listed in the errata.
    ['74.125.16.64' => 0],
    # Test IPs listed in the "additional.txt" file.
    ['218.93.127.117' => -1],
);

for my $test (@tests) {
    my $ip = $test->[0];
    my $out = chinese_ip ($ip);
    is ($out, $test->[1], "Test with $ip");
}
done_testing ();

# Local variables:
# mode: perl
# End:
