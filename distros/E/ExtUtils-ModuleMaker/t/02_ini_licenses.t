# t/02_ini_licenses.t; just to load ExtUtils::ModuleMaker::Licenses by using it

$|++; 
print "1..1
";
my($test) = 1;

# 1 load
use ExtUtils::ModuleMaker::Licenses;
my($loaded) = 1;
$loaded ? print "ok $test
" : print "not ok $test
";
$test++;

# end of t/02_ini_licenses.t

