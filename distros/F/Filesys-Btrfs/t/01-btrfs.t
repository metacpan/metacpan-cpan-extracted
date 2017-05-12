#!perl -T

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Deep;
use Try::Tiny;
use File::Temp;

use Filesys::Btrfs;

# Make %ENV safer
delete(@ENV{qw(IFS CDPATH ENV BASH_ENV)});
$ENV{PATH} = '/bin';

#create btrfs volumne in file (use sparse file to save space)
my $btrfs_file = File::Temp->new(TEMPLATE => 'btrfs.XXXX',
                                 DIR      => '/tmp',
                                 SUFFIX   => '.tmp');
my $btrfs_mount = File::Temp->newdir('btrfs.XXXX', DIR => '/tmp');
diag("Creating btrfs filesystem for tests: $btrfs_file, $btrfs_mount");

try {
    use autodie ':all';
    system('/bin/dd', 'if=/dev/zero',
           'of='.$btrfs_file, 'bs=1', 'count=0', 'seek=256M');
    system('/sbin/mkfs.btrfs', $btrfs_file);
    system('/bin/mount', $btrfs_file, $btrfs_mount, '-o', 'loop');
    1;
} catch {
    plan(skip_all => 'cannot create btrfs filesystem to test with: '.$_);
};

unless(-x Filesys::Btrfs::BTRFS_CMD()) {
    plan(skip_all => 'Cannot find executable btrfs util in '
             .Filesys::Btrfs::BTRFS_CMD());
}

#cleanup
END {
    try {
        system('/bin/umount', $btrfs_mount);
    };
}

diag("Testing Filesys::Btrfs $Filesys::Btrfs::VERSION, Perl $], $^X");


#Looks like we managed to create btrfs filesystem and everything is in place.
#Let's do real testing now.
plan(tests => 31);

ok(Filesys::Btrfs::BTRFS_CMD(), 'got default btrfs cmd');

#test constructor with not default value
{
    my $btrfs = Filesys::Btrfs->new('/test/mount/point', btrfs_cmd => '/test/cmd');
    isa_ok($btrfs, 'Filesys::Btrfs', 'created btrfs object');
    is($btrfs->mount_point, '/test/mount/point', 'valid mount point');
    is($btrfs->btrfs_cmd, '/test/cmd', 'valid default btrfs cmd');
}

dies_ok(sub { Filesys::Btrfs->new(); }, 'mount point is required');

my $btrfs = Filesys::Btrfs->new($btrfs_mount);
isa_ok($btrfs, 'Filesys::Btrfs', 'created btrfs object');
is($btrfs->mount_point, $btrfs_mount, 'valid mount point');
is($btrfs->btrfs_cmd, Filesys::Btrfs::BTRFS_CMD(), 'valid default btrfs cmd');
like($btrfs->version, qr/^\d+\.\d+/, 'got valid version');
diag("Testing against ".$btrfs->version." version of btrfs util");

#create different subvolumes
is_deeply($btrfs->subvolume_list, {}, 'no subvolumes');
dies_ok(sub { $btrfs->subvolume_create(); }, 'subvolume_create dies without path');
lives_ok(sub { $btrfs->subvolume_create('aaa'); }, 'create new subvolume');
cmp_deeply([keys(%{$btrfs->subvolume_list})], bag('aaa'), 'got subvolume');
lives_ok(sub { $btrfs->subvolume_create($btrfs_mount.'/bbb'); },
         'create one more subvolume (absolute path)');
cmp_deeply([keys(%{$btrfs->subvolume_list})], bag('aaa', 'bbb'),
           'got subvolumes');
lives_ok(sub { $btrfs->subvolume_create('bbb/ccc'); }, 'create new subsubvolume');
cmp_deeply([keys(%{$btrfs->subvolume_list})], bag('aaa', 'bbb', 'bbb/ccc'),
           'got subvolumes');
cmp_deeply([keys(%{$btrfs->subvolume_list('bbb')})], bag('bbb/ccc'),
           'got subsubvolumes');
cmp_deeply([keys(%{$btrfs->subvolume_list($btrfs_mount.'/bbb')})], bag('bbb/ccc'),
           'got subsubvolumes (absolulte path)');

#delete subvolumes
dies_ok(sub { $btrfs->subvolume_delete(); }, 'subvolume_delete dies without path');
lives_ok(sub { $btrfs->subvolume_delete('aaa'); }, 'delete subvolume');
cmp_deeply([keys(%{$btrfs->subvolume_list})], bag('bbb', 'bbb/ccc'),
           'got subvolumes');
dies_ok(sub { $btrfs->subvolume_delete('bbb'); },
        'try to delete subvolume with subsubvolume');
lives_ok(sub { $btrfs->subvolume_delete('bbb/ccc'); }, 'delete subsubvolume');
lives_ok(sub { $btrfs->subvolume_delete($btrfs_mount.'/bbb'); },
         'delete subvolume (absolute path');
is_deeply($btrfs->subvolume_list, {}, 'no subvolumes');

#set default subvolume
dies_ok(sub { $btrfs->subvolume_set_default(); }, 'set default subvolume - no id');
$btrfs->subvolume_create('aaa');
lives_ok(sub { $btrfs->subvolume_set_default($btrfs->subvolume_list()->{aaa}); },
         'set default subvolume');
lives_ok(sub { $btrfs->subvolume_set_default(0); },
         'set default-default subvolume');
$btrfs->subvolume_delete('aaa');

#filesystem sync
lives_ok(sub { $btrfs->filesystem_sync(); }, 'sync fs');

#filesystem balance
lives_ok(sub { $btrfs->filesystem_balance(); }, 'sync balance');
