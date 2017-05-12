# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..9\n"; }
END {print "not ok 1\n" unless $loaded;}
use File::Descriptions;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $test = 1;
my $description = new File::Descriptions('/');
print 'not ' if ($description->directory ne '/');
print 'ok ',++$test,"\n";
my %result = $description->gethash('.');
print 'not ' if ($description->directory ne '.');
print 'ok ',++$test,"\n";

%result = $description->gethash('./simtelnet/');
print 'not ' if ($result{'ada'} ne 'Ada programming language');
print 'ok ',++$test,"\n";

print 'not ' if ($result{'1cat.zip'} ne '4DOS & NDOS command line disk catalog program');
print 'ok ',++$test,"\n";

%result = $description->gethash('./debian/files/');
print 'not ' if ($result{'9menu_1.4-6.deb'} ne 'Creates X menus from the shell.');
print 'ok ',++$test,"\n";

print 'not ' if ($result{'9fonts_1-4.deb'} ne '');
print 'ok ',++$test,"\n";

%result = $description->gethash('./freebsd/archivers/');
print 'not ' if ($result{'arc-5.21e.tgz'} ne 'Create & extract files from DOS .ARC files.');
print 'ok ',++$test,"\n";

print 'not ' if ($result{'bzip-0.21.tgz'} ne '');
print 'ok ',++$test,"\n";
