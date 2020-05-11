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
# Wait to see if this happens, and if so, unmount it.
sleep(2);
my $mount_point = find_mount_point($fake_device);
if ($mount_point) {
    ok($cdroms->get_mount_point($udisks_paths[0]) eq $mount_point, 'get_mount_point returns correct path');
    ok($cdroms->unmount($udisks_paths[0]), 'unmount returns success');
    $mount_point = find_mount_point($fake_device);
    ok(!$mount_point, 'unmount works');
}
ok(!$cdroms->get_mount_point($udisks_paths[0]), 'get_mount_point returns no path');

# Now test we can mount it.
my $udisks_mount_point = $cdroms->mount($udisks_paths[0]);
$mount_point = find_mount_point($fake_device);
ok($mount_point, 'mount works');
ok($udisks_mount_point eq $mount_point, 'mount returns correct path');
ok($cdroms->get_mount_point($udisks_paths[0]) eq $mount_point, 'get_mount_point returns correct path');

ok(!$cdroms->mount($udisks_paths[0]), 'repeated mount fails');

# And that we can unmount it.
ok($cdroms->unmount($udisks_paths[0]), 'unmount returns success');
$mount_point = find_mount_point($fake_device);
ok(!$mount_point, 'unmount works');
ok(!$cdroms->get_mount_point($udisks_paths[0]), 'get_mount_point returns no path');

ok(!$cdroms->unmount($udisks_paths[0]), 'repeated unmount fails');

ok(-e "/dev/$fake_device", 'device has not been ejected');

done_testing();

END {
    remove_fake_media() if $> == 0;
}
