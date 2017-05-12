# IP-Anonymous.t - test script

use Test;
BEGIN { plan tests => 11 };

# Test 1: load module
use IP::Anonymous;
ok(1); # If we made it this far, we are ok.

# Test 2: init simple key and anonymize 0.0.0.0
my @key = (0..31);
my $obj = new IP::Anonymous(@key);
my $result = $obj->anonymize("0.0.0.0");
print ($result eq "254.152.65.220" ? "ok 2\n" : "not ok 2\n");

# Test 3: anonymize 10.0.1.128
$result = $obj->anonymize("10.0.1.128");
print ($result eq "246.35.190.47" ? "ok 3\n" : "not ok 3\n");

# Test 4: anonymize 127.0.0.1
$result = $obj->anonymize("127.0.0.1");
print ($result eq "168.227.160.61" ? "ok 4\n" : "not ok 4\n");

# Test 5: anonymize 169.254.100.50
$result = $obj->anonymize("165.254.100.50");
print ($result eq "90.1.157.13" ? "ok 5\n" : "not ok 5\n");

# Test 6: anonymize 255.255.255.255
$result = $obj->anonymize("255.255.255.255");
print ($result eq "56.0.15.254" ? "ok 6\n" : "not ok 6\n");

# Test 7: change to the sample Crypto-PAn key and anonymize 0.0.0.0
@key = (21,34,23,141,51,164,207,128,19,10,91,22,73,144,125,16,
        216,152,143,131,121,121,101,39,98,87,76,45,42,132,34,2);
$obj = new IP::Anonymous(@key);
$result = $obj->anonymize("0.0.0.0");
print ($result eq "120.255.240.1" ? "ok 7\n" : "not ok 7\n");

# Test 8: anonymize 10.0.1.128
$result = $obj->anonymize("10.0.1.128");
print ($result eq "117.15.1.129" ? "ok 8\n" : "not ok 8\n");

# Test 9: anonymize 127.0.0.1
$result = $obj->anonymize("127.0.0.1");
print ($result eq "33.0.243.129" ? "ok 9\n" : "not ok 9\n");

# Test 10: anonymize 169.254.100.50
$result = $obj->anonymize("169.254.100.50");
print ($result eq "169.251.68.45" ? "ok 10\n" : "not ok 10\n");

# Test 11: anonymize 255.255.255.255
$result = $obj->anonymize("255.255.255.255");
print ($result eq "206.120.97.255" ? "ok 11\n" : "not ok 11\n");
