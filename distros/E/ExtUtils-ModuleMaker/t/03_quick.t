# t/03_quick.t; just to load ExtUtils::ModuleMaker by using it

$|++; 
print "1..1";
my($test) = 1;

use ExtUtils::ModuleMaker;

chdir 'blib';
&ExtUtils::ModuleMaker::Check_Dir ("testing");
chdir 'testing';
&Quick_Module ("Sample::Module");
chdir 'Sample/Module';

# 1 files exist ?
(-e 'MANIFEST') ? print "ok $test" : print "not ok $test";
$test++;

# end of t/03_quick.t

