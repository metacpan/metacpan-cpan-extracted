use strict;
use Test;
BEGIN { plan tests => 3 }
use Filesys::ZFS;

my $zfs = Filesys::ZFS->new({no_root_check => 1, zfs => 'test/zfs_fake.pl', zpool => 'test/zpool_fake.pl'});

ok($zfs);
ok($zfs->init);
ok($zfs->is_healthy);


