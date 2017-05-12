# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Linux-KernelSort.t'

use Test::More tests => 20;
BEGIN { use_ok('Linux::KernelSort') };

#########################

use Linux::KernelSort;
my $kernel = new Linux::KernelSort;

$kernel->{debug} = 0;
my $version1 = "2.6.19";
my $version2 = "2.6.19-rc2-git7";
my $bad_version = "bad-2.6.19-version";

ok ($kernel->version_check($version1) eq 0, "Valid:  $version1");
ok ($kernel->version_check($version2) eq 0, "Valid:  $version2");
ok ($kernel->version_check($bad_version) eq 1, "Invalid:  $version2");

ok ($kernel->rank("2.6.19") eq '2619.0.0.0.0.0', "Rank 2.6.19");
ok ($kernel->rank("2.6.19-mm1") eq '2619.0.0.0.0.1', "Rank 2.6.19-mm1");
ok ($kernel->rank("2.6.19-rc1") eq '2618.1.0.0.0.0', "Rank 2.6.19-rc1");
ok ($kernel->rank("2.6.19-rc1-git7") eq '2618.1.7.0.0.0', "Rank 2.6.19-rc1-git7");
ok ($kernel->rank("2.6.19-rc1-mm2") eq '2618.1.0.0.0.2', "Rank 2.6.19-rc1-mm2");
ok ($kernel->rank("2.6.19-rc1-scsi-misc2") eq '2618.1.0.2.0.0', "Rank 2.6.19-rc1-scsi-misc2");
ok ($kernel->rank("2.6.19-rc1-scsi-rc-fixes5") eq '2618.1.0.0.5.0', "Rank 2.6.19-rc1-scsi-rc-fixes5");
ok ( !defined ($kernel->rank($bad_version)), "Invalid Kernel");

ok ($kernel->compare($version1, $version2) == 1, "$version1 > $version2");
ok ($kernel->compare($version2, $version1) == -1, "$version2 < $version1");
ok ($kernel->compare($version1, $version1) == 0, "$version1 == $version2");
ok ($kernel->compare($bad_version, $version1) == -1, "$bad_version < $version1");
ok ($kernel->compare($version1, $bad_version) == 1, "$version1 > $bad_version");
ok ($kernel->compare($bad_version, $bad_version) == 0, "$bad_version == $bad_version");


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
                    '2.6.18-rc10',
                    '2.6.18-mm1',
                    '2.6.18-rc2-mm1' );

my @kernel_sorted = ( '2.6.15',
                      '2.6.18-rc2',
                      '2.6.18-rc2-mm1',
                      '2.6.18-rc2-mm2',
                      '2.6.18-rc2-git1',
                      '2.6.18-rc2-git2',
                      '2.6.18-rc2-git35',
                      '2.6.18-rc10',
                      '2.6.18',
                      '2.6.18-mm1',
                      '2.6.18-mm2',
                      '2.6.19',
                      '2.6.19-mm2' );

my @sorted_list = $kernel->sort(@kernel_list);

my $size1 = @sorted_list;
my $size2 = @kernel_sorted;

if ($size1 != $size2) {
    fail("Kernel Sort (containing only valid kernel names)");
}

my $i;
for ($i = 0; $i < $size1; $i++) {
    if ($kernel_sorted[$i] ne $sorted_list[$i]) {
        fail ("Kernel Sort (containing only valid kernel names)");
        last;
    }
}

if ($i == $size1) {
    pass ("Kernel Sort (containing only valid kernel names)");
}

my @bad_kernel_list = ( '2.6.19',
                        '2.6.18-mm2',
                        '2.6.0',
                        'bad-2.6.0',
                        '2.6.0-foo',
                        '2.bad.version' );

my @bad_kernel_sorted = ( 'bad-2.6.0',
                          '2.6.0-foo',
                          '2.bad.version',
                          '2.6.0',
                          '2.6.18-mm2',
                          '2.6.19' );

@sorted_list = $kernel->sort (@bad_kernel_list);

$size1 = @sorted_list;
$size2 = @bad_kernel_sorted;

if ($size1 != $size2) {
    fail("Kernel Sort (containing invalid kernel names)");
}

for ($i = 0; $i < $size1; $i++) {
    if ($bad_kernel_sorted[$i] ne $sorted_list[$i]) {
        fail ("Kernel Sort (containing invalid kernel names)");
        last;
    }
}

if ($i == $size1) {
    pass ("Kernel Sort (containing invalid kernel names)");
}
