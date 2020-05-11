use strict;
use lib 't';
use helper;
use File::Temp qw(tempdir);
use Test::More;
plan skip_all => "You need to be root to run this test" if $> != 0;
plan skip_all => "The scsi_debug kernel module is needed to run this test" if !can_create_fake_media();
plan 'no_plan';

use_ok('Hal::Cdroms');

# Check if a volume manager is going to auto-mount the device.
my $fake_device = create_fake_media();
sleep(2);
my $auto_mounted = 0;
if (find_mount_point($fake_device)) {
    system("umount /dev/$fake_device");
    remove_fake_media();
    $auto_mounted = 1;
}

my $fake_device = create_fake_media(3);

if (!$auto_mounted) {
    my $tmp_dir = tempdir(CLEANUP => 1);
    system("(sleep 4; mount /dev/$fake_device $tmp_dir)&");
}

my $cdroms = Hal::Cdroms->new;

my $udisks_path = $cdroms->wait_for_mounted();
ok($udisks_path eq "/org/freedesktop/UDisks2/block_devices/$fake_device", 'wait_for_mounted returns correct path');
my $mount_point = find_mount_point($fake_device);
ok($mount_point, 'device is mounted');
ok($cdroms->get_mount_point($udisks_path) eq $mount_point, 'get_mount_point returns correct path');

done_testing();

END {
    system("umount /dev/$fake_device") if find_mount_point($fake_device);
    remove_fake_media() if $> == 0;
}
