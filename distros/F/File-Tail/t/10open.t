BEGIN { $| = 1; print "1..6\n"; }
END {print "not ok 1\n" unless $loaded;}
use File::Copy qw/move/;
use File::Tail;
$loaded = 1;
print "ok 1\n";

$debug=0;

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):


#
# Test 2 - open an existant file
# 

$testname="./test$$";
open(TEST,">$testname");
select TEST;
$|=1;
select STDOUT;
$|=1;
$file=File::Tail->new(name=>$testname,debug=>$debug,interval=>1,maxinterval=>5,
		      adjustafter=>5,errmode=>"return") or
    print "not ok 2\n";
print "ok 2\n" if defined($file);

#
# Test 3 - read a line from the file
#

$teststring="This is a test string\n";
print TEST $teststring;
$t=$file->read;
if ($t eq $teststring) {
    print "ok 3\n";
} else {
    print "not ok 3\n";
}

#
# Test 4 - read an array of lines from file
#
print TEST "0\n1\n2\n3\n4\n";
@t=$file->read;
foreach (0..4) {
    unless ($t[$_] eq "$_\n") {
	print "not ok 4\n - <$t[$_]> at $_";
	last;
    }
}
print "ok 4\n";

#
# Test 5 - Read on reopened file
#
close(TEST);
open(TEST,">$testname");
$teststring="This is another test string\n";
print TEST $teststring;
$t=$file->read;
if ($t eq $teststring) {
    print "ok 5\n";
} else {
    print "not ok 5\n";
}

#
# Test 6 - Read on moved and reopened file
#
if (not $^O =~ /win32/i) {
  move($testname, "$testname-tmp");
  open(TEST,">$testname");
  $teststring="This is yet another test string\n";
  print TEST $teststring;
  $t=$file->read;
  if ($t eq $teststring) {
    print "ok 6\n";
  } else {
    #    print "<$t><$teststring>\n";
    print "not ok 6\n";
  }
} else {
  print "ok 6\n"; # Apparently, in windows, you can not rename opened files?
}
unlink "$testname";
unlink "$testname-tmp";
