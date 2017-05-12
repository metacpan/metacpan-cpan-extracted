use File::Tail;
$| = 1; print "1..7\n";

$debug=0;

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$testname="./test$$";
open(TEST,">$testname");
select TEST;
$|=1;
select STDOUT;
#
# Test 1 - read whole file
#
print TEST "0\n1\n2\n3\n4\n";
$file=File::Tail->new(name=>$testname,debug=>$debug,interval=>1,maxinterval=>5,
		      adjustafter=>5,errmode=>"return",tail=>-1) or	
    print "not ok 1\n";
@t=$file->read;
foreach (0..4) {
    unless ($t[$_] eq "$_\n") {
	print "not ok 1\n - <$t[$_]> at $_";
	last;
    }
}
print "ok 1\n";
$file->CLOSE;


open(TEST,">$testname");
select TEST;
$|=1;
select STDOUT;
#
# Test 2 - start at end of file
#
$file=File::Tail->new(name=>$testname,debug=>$debug,interval=>1,maxinterval=>5,
		      adjustafter=>5,errmode=>"return",tail=>0) or	
    print "not ok 2\n";
$teststring="This is a test string\n";
print TEST $teststring;
$t=$file->read;
if ($t eq $teststring) {
    print "ok 2\n";
} else {
    print "not ok 2\n";
}
$file->CLOSE;
close(TEST);

#
# Test 3-7 read the last 1-5 lines
# 
open(TEST,">$testname");
select TEST;
$|=1;
select STDOUT;
print TEST "0\n1\n2\n3\n4\n";

TEST: foreach $test (3..7) {
    undef @t;
#    print "Test no. $test!\n";
    $file=File::Tail->new(name=>$testname,debug=>$debug,interval=>1,
			  maxinterval=>5,adjustafter=>5,errmode=>"return",
			  tail=>($test-2)) or	
    print "not ok $test\n";
    @t=$file->read;
    unless (($test-2) == ($#t+1)) {
	print "not ok $test\n";
	next;
    }
#   my $a=join("",@t);$a=~tr/\n/ /;
#   print "<$a>";
    foreach ((7-$test)..4) {
#	print "\$t[$test+$_-7]=$t[$test+$_-7], should be $_\n";
	unless ($t[$test+$_-7] eq "$_\n") {
	    print "not ok $test\n - <$t[$_]> at $_";
	    next TEST;
	}
    }
    print "ok $test\n";
    $file->CLOSE;
}
unlink "$testname";


