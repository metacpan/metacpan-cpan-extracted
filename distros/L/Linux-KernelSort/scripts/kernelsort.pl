#!/usr/bin/perl -w

use Linux::KernelSort;
my $kernel = new Linux::KernelSort;

$kernel->{debug} = 0;
my $version1 = "2.6.19";
my $version2 = "2.6.19-rc2-git7";

if ($kernel->version_check($version1)) {
    print "Invalid version: $version1\n";
} else {
    print "Valid version:  $version1\n";
}
if ($kernel->version_check("$version2")) {
    print "Invalid version: $version2\n";
} else {
    print "Valid version:  $version2\n";
}
if ($kernel->compare($version1, $version2) == 1) {
    print "GOOD:  $version1 > $version2\n";
} else {
    print "BAD:  tried $version1 > $version2\n";
}
print "------------------\n";
if ($kernel->compare($version2, $version1) == -1) {
    print "GOOD:  $version2 < $version1\n";
} else {
    print "BAD:   tried $version2 < $version1\n";
}
print "------------------\n";
if ($kernel->compare($version1, $version1) == 0) {
    print "GOOD:  $version1 == $version1\n";
} else {
    print "BAD:  tried $version1 == $version1\n";
}
print "------------------\n";
if ($kernel->compare($version2, $version2) == 0) {
    print "GOOD:  $version2 == $version2\n";
} else {
    print "BAD:  tried $version2 == $version2\n";
}
print "------------------\n";
if ($kernel->compare("2.6.18-rc2-git2", "2.6.18-rc2-mm1") > 0) {
    print "GOOD:  2.6.18-rc2-git2 > 2.6.18-rc2-mm1\n";
} else {
    print "BAD:  tried 2.6.18-rc2-git2 > 2.6.18-rc2-mm1\n";
}
print "------------------\n";
if ($kernel->compare("2.6.18-rc2-mm1", "2.6.18-rc2") > 0) {
    print "GOOD:  2.6.18-rc2-mm1 > 2.6.18-rc2\n";
} else {
    print "BAD:  tried 2.6.18-rc2-mm1 > 2.6.18-rc2\n";
}
print "------------------\n";
if ($kernel->compare("2.6.18-mm1", "2.6.18-git1") < 0) {
    print "GOOD:  2.6.18-mm1 < 2.6.18-git1\n";
} else {
    print "BAD:  tried 2.6.18-mm1 < 2.6.18-git1\n";
}
print "------------------\n";
if ($kernel->compare("2.6.18-mm2", "2.6.18-mm1") > 0) {
    print "GOOD:  2.6.18-mm2 > 2.6.18-mm1\n";
} else {
    print "BAD:  tried 2.6.18-mm2 > 2.6.18-mm1\n";
}
print "------------------\n";
if ($kernel->compare("test-2.6.18", "2.6.18") < 0){
   print "GOOD:  test-2.6.18 < 2.6.18\n";
} else {
   print "BAD: test-2.6.18 < 2.6.18\n";
}
print "------------------\n";
if ($kernel->compare("test-2.6.18", "foo-2.6.18-bar") == 0){
   print "GOOD:  test-2.6.18 == foo-2.6.18-bar\n";
} else {
   print "BAD: test-2.6.18 != foo-2.6.18-bar\n";
}
print "------------------\n";
if ($kernel->compare("2.6.18", "2.6.18-foobar") > 0){
   print "GOOD:  2.6.18 > 2.6.18-foobar\n";
} else {
   print "BAD: tried 2.6.18 > 2.6.18-foobar\n";
}
print "------------------\n";
if ($kernel->compare("2.6.18", "2.6.18-scsi-misc4") < 0){
   print "GOOD:  2.6.18 < 2.6.18-scsi-misc4\n";
} else {
   print "BAD: tried 2.6.18 > 2.6.18-scsi-misc4\n";
}
print "------------------\n";
if ($kernel->compare("2.6.18-rc1", "2.6.19-rc1-scsi-misc2") < 0) {
   print "GOOD:  2.6.18-rc1 < 2.6.18-rc1-scsi-misc2\n";
} else {
   print "BAD: tried 2.6.18-rc2 > 2.6.18-rc1-scsi-misc2\n";

}
print "------------------\n";


my @kernel_list = ( '2.6.19',
                    '2.6.15',
                    '2.6.18',
                    '2.6.18-mm2',
                    '2.6.19-mm2',
                    '2.6.18-rc2',
                    '2.6.18-rc2-mm2',
                    '2.6.18-rc2-git2',
                    '2.6.18-rc2-git1',
                    '2.6.18-rc2-git35',
                    '2.6.18-rc2-scsi-misc5',
                    '2.6.18-rc2-scsi-rc-fixes3',
                    '2.6.18-rc10',
                    '2.6.18-mm1',
                    '2.6.18-rc2-mm1',
                    'bad-2.6.18',
                    '2.6.18-foo',
                    '2.6.bad');

my @sorted_list = $kernel->sort(@kernel_list);

print "@sorted_list";


