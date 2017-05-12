#!/usr/bin/perl 
#===============================================================================
#
#         FILE:  test.pl
#
#        USAGE:  ./test.pl 
#
#  DESCRIPTION:  Script to test install and operation of File::RelDir module
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:   (Dave Roberts), <droberts@cpan.org`>
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  15/04/2010 20:31:01 GMT
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

BEGIN{
	use Test::More qw(no_plan);
}
my($ref,$da,$db);
#...............................................................................
my($modulecode) = "RelDir.pm";
my($return);
ok($return = do $modulecode,   "Loaded local version of File::RelDir")or diag("Failed to load module");
#{	#diag("\tcouldn't parse $modulecode : $@\n") if $@;
	#diag("\tcouldn't do $modulecode : $! \n") unless defined $return;
	#diag("\tcouldn't run $modulecode \n") unless $return;
##diag("oops");
#}
#...............................................................................

print "." x 80;
print "\nFile::RelDir->Version() Tests\n\n";
ok(File::RelDir->Version(),  "Version call test");
#...............................................................................
is(File::RelDir->Version(), 0.1,  "Version test (v0.1)");
#...............................................................................
print "." x 80;
print "\nFile::RelDir::Diff(dira,dirb) Tests\n\n";
# Win32 style tests
$da  = "d:/a/b/c/here";
$db  = "d:/a/b/c/there";
is(File::RelDir::Diff($da, $db),"../there", "relative path test - from $da to $db");
is(File::RelDir::Diff($db, $da),"../here", "relative path test - from $db to $da");
$da  = "d:/here";
is(File::RelDir::Diff($da, $db),"../a/b/c/there", "relative path test - from $da to $db");
is(File::RelDir::Diff($db, $da),"../../../../here", "relative path test - from $db to $da");
# add test with a different drive letter
# these tests fail, so test for undef returned, this makes a pass
# as you can't have a relative directory between drive letters
$da  = "c:/here";
is(File::RelDir::Diff($da, $db),0, "relative path test - from $da to $db");
is(File::RelDir::Diff($db, $da),0, "relative path test - from $db to $da");
#...............................................................................
# *nix style tests
$da  = "/tmp/a/b/c/here";
$db  = "/tmp/a/b/c/there";
is(File::RelDir::Diff($da, $db),"../there", "relative path test - from $da to $db");
is(File::RelDir::Diff($db, $da),"../here", "relative path test - from $db to $da");
$da  = "/tmp/here";
is(File::RelDir::Diff($da, $db),"../a/b/c/there", "relative path test - from $da to $db");
is(File::RelDir::Diff($db, $da),"../../../../here", "relative path test - from $db to $da");
$da  = "/var/here";
is(File::RelDir::Diff($da, $db),"../../tmp/a/b/c/there", "relative path test - from $da to $db");
is(File::RelDir::Diff($db, $da),"../../../../../var/here", "relative path test - from $db to $da");

#...............................................................................
print "." x 80;
print "\nFile::RelDir->New(dira) Tests\n\n";
$da  = "/tmp/a/b/c/here";
$db  = "/tmp/a/b/c/there";
ok($ref=File::RelDir->New($da),   "New call succeeded")or diag("New call Failed");

#...............................................................................
print "." x 80;
print "\nFile::RelDir->Path(dirb) Tests\n\n";
is($ref->Path($db),"../there", "relative path test - from $da to $db");
$da  = "d:/a/b/c/here";
$db  = "d:/a/b/c/there";
ok($ref=File::RelDir->New($da),   "New call succeeded")or diag("New call Failed");
is($ref->Path($db),"../there", "relative path test - from $da to $db");
$da  = 'd:\a\b\c\here';
$db  = 'd:\a\b\c\there';
ok($ref=File::RelDir->New($da),   "New call succeeded - windows path with \\ seperators")or diag("New call Failed");
is($ref->Path($db),"..\\there", "relative path test - from $da to $db");
$db  = 'D:\a\b\c\there';
is($ref->Path($db),"..\\there", "relative path test - different case of drive letter - from $da to $db");
$db  = 'D:/a/b/c/there';
is($ref->Path($db),"..\\there", "relative path test - different case of drive letter - from $da to $db");
$db  = 'D:\A\B\C\THERE';
is($ref->Path($db),"..\\THERE", "relative path test - different case of path - from $da to $db");
$db  = 'D:/A/B/C/THERE';
is($ref->Path($db),"..\\THERE", "relative path test - different case of path - from $da to $db");
$da  = 'd:/a/b/c/here';
$db  = 'd:\a\b\c\there';
ok($ref=File::RelDir->New($da),   "New call succeeded - windows path with / seperators")or diag("New call Failed");
is($ref->Path($db),"../there", "relative path test - from $da to $db");
$db  = 'D:\a\b\c\there';
is($ref->Path($db),"../there", "relative path test - different case of drive letter - from $da to $db");
$db  = 'D:/a/b/c/there';
is($ref->Path($db),"../there", "relative path test - different case of drive letter - from $da to $db");
$db  = 'D:\A\B\C\THERE';
is($ref->Path($db),"../THERE", "relative path test - different case of path - from $da to $db");
$db  = 'D:/A/B/C/THERE';
is($ref->Path($db),"../THERE", "relative path test - different case of path - from $da to $db");

print "." x 80;
print "\n";
$da  = "/tmp/a/b/c/here";
$db  = "/tmp/d/e/f/there";
ok($ref=File::RelDir->New($da),   "New call succeeded")or diag("New call Failed");
is($ref->Path($db),"../../../../d/e/f/there", "relative path test - from $da to $db");

$da  = "/tmp/here";
ok($ref=File::RelDir->New($da),   "New call succeeded")or diag("New call Failed");
is($ref->Path("/tmp/here"),".", "relative path test - from $da to /tmp/here");
is($ref->Path("/tmp"),"../", "relative path test - from $da to /tmp");
is($ref->Path("/tmp/there"),"../there", "relative path test - from $da to /tmp/there");
is($ref->Path("/tmp/there/where"),"../there/where", "relative path test - from $da to /tmp/there/where");
is($ref->Path("/tmp/here/anywhere"),"./anywhere", "relative path test - from $da to /tmp/here/anywhere");
is($ref->Path("/TMP/here"),"../../TMP/here", "relative path test - from $da to /TMP/here");
is($ref->Path("/TMP"),"../../TMP", "relative path test - from $da to /TMP");
is($ref->Path("/TMP/there"),"../../TMP/there", "relative path test - from $da to /TMP/there");
is($ref->Path("/TMP/there/where"),"../../TMP/there/where", "relative path test - from $da to /TMP/there/where");
