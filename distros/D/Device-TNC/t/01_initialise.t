# Just test that the module loads

$|++; 
print "1..1\n";
my($test) = 1;

# 1 load
use Device::TNC::KISS;
my($loaded) = 1;
$loaded ? print "ok $test\n" : print "not ok $test\n";
$test++;


