use strict;
use lib 't';
use helper;
use Test::More;
plan skip_all => "You need to be root to run this test" if $> != 0;
plan skip_all => "The scsi_debug kernel module is needed to run this test" if !can_create_fake_media();
plan 'no_plan';

use_ok('Hal::Cdroms');

my $fake_device = create_fake_media(3);

my $cdroms = Hal::Cdroms->new;

my $udisks_path = $cdroms->wait_for_insert(10000);
ok($udisks_path eq "/org/freedesktop/UDisks2/block_devices/$fake_device", 'wait_for_insert returns correct path');

done_testing();

END {
    system("umount /dev/$fake_device") if find_mount_point($fake_device);
    remove_fake_media() if $> == 0;
}
