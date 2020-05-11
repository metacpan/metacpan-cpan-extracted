use strict;
use lib 't';
use helper;
use Test::More;
plan skip_all => "You need to be root to run this test" if $> != 0;
plan skip_all => "The scsi_debug kernel module is needed to run this test" if !can_create_fake_media();

use_ok('Hal::Cdroms');

my $fake_device = create_fake_media();

my $cdroms = Hal::Cdroms->new;

my @udisks_paths = grep { $_ eq "/org/freedesktop/UDisks2/block_devices/$fake_device" } $cdroms->list;
ok(@udisks_paths == 1, 'device is listed');

# If a volume manager is running, the device may get auto-mounted.
# Allow this to settle before proceeding.
sleep(2);

# Ensure the device is mounted.
ok($cdroms->ensure_mounted($udisks_paths[0]), 'ensure_mounted returns success');
my $mount_point = find_mount_point($fake_device);
ok($mount_point, 'device is mounted');

# Test that we can eject it.
ok($cdroms->eject($udisks_paths[0]), 'eject returns success');
$mount_point = find_mount_point($fake_device);
ok(!$mount_point, 'device is unmounted');
ok(!$cdroms->get_mount_point($udisks_paths[0]), 'get_mount_point returns no path');

# It appears the scsi_debug module doesn't support eject, so we have to skip this.
# ok(! -e "/dev/$fake_device", 'device has been ejected');

ok(!$cdroms->eject($udisks_paths[0]), 'repeated eject fails');

done_testing();

END {
    remove_fake_media() if $> == 0;
}
