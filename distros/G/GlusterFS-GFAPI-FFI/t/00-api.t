#/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Env;
use POSIX           qw/:fcntl_h/;
use Scalar::Util    qw/weaken/;
use Test::Most;

use FFI::Platypus;
use FFI::Platypus::Buffer;
use FFI::Platypus::Memory   qw/strdup calloc free/;
use FFI::Platypus::Declare;

use constant
{
    S_IFIFO => 0010000,
};

diag('00-api.t');

if (!$ENV{TEST_FUNCTION})
{
    plan(skip_all => 'TEST_FUNCTION not enabled so it will be skipped');
}

use_ok('GlusterFS::GFAPI::FFI');

my $api = GlusterFS::GFAPI::FFI->new();

ok(defined($api) && ref($api) eq 'GlusterFS::GFAPI::FFI'
    , 'GlusterFS::GFAPI::FFI - new()');

# new
my $fs;

subtest 'new' => sub
{
    $fs = GlusterFS::GFAPI::FFI::glfs_new('libgfapi-perl');

    ok(defined($fs), sprintf('glfs_new(): %s', $fs // 'undef'));
};

# set_volfile_server
subtest 'set_volfile_server' => sub
{
    my $retval = GlusterFS::GFAPI::FFI::glfs_set_volfile_server($fs, 'tcp', 'node1', 24007);

    ok($retval == 0, sprintf('glfs_set_volfile_server(): %d', $retval));

    diag("error: $!") if ($retval);
};

# init
subtest 'init' => sub
{
    my $retval = GlusterFS::GFAPI::FFI::glfs_init($fs);

    ok($retval == 0, sprintf('glfs_init(): %d', $retval));

    diag("error: $!") if ($retval);
};

# get_volumeid
subtest 'get_volumeid' => sub
{
    my $expected;

    do {
        my $out = `sudo gluster volume info libgfapi-perl`;

        foreach (split(/\n/, $out))
        {
            if ($_ =~ m/^Volume ID: (?<volid>[^\s]+)$/)
            {
                $expected = $+{volid};
                last;
            }
        }
    };

    my $len = 16;
    my $id  = "\0" x $len;

    my $retval = GlusterFS::GFAPI::FFI::glfs_get_volumeid($fs, $id, $len);

    $id = join('-', unpack('H8 H4 H4 H4 H12', $id));

    cmp_ok($retval, '==', $len, sprintf('glfs_get_volumeid(): %d', $retval));

    diag("error: $!") if ($retval != $len);

    cmp_ok($id, 'eq', $expected, sprintf('	Volume ID : %s', $id // 'undef'));
};

# statvfs
subtest 'statvfs' => sub
{
    my $stat   = GlusterFS::GFAPI::FFI::Statvfs->new();
    my $retval = GlusterFS::GFAPI::FFI::glfs_statvfs($fs, '/', $stat);

    ok(defined($stat), sprintf('glfs_statvfs(): %d', $retval));

    diag("error: $!") if ($retval);

    ok(defined($stat->f_bsize),   "	f_bsize   : " . $stat->f_bsize   // 'undef');
    ok(defined($stat->f_frsize),  "	f_frsize  : " . $stat->f_frsize  // 'undef');
    ok(defined($stat->f_blocks),  "	f_blocks  : " . $stat->f_blocks  // 'undef');
    ok(defined($stat->f_bfree),   "	f bfree   : " . $stat->f_bfree   // 'undef');
    ok(defined($stat->f_bavail),  "	f_bavail  : " . $stat->f_bavail  // 'undef');
    ok(defined($stat->f_files),   "	f_files   : " . $stat->f_files   // 'undef');
    ok(defined($stat->f_ffree),   "	f_ffree   : " . $stat->f_ffree   // 'undef');
    ok(defined($stat->f_favail),  "	f_favail  : " . $stat->f_favail  // 'undef');
    ok(defined($stat->f_fsid),    "	f_fsid    : " . $stat->f_fsid    // 'undef');
    ok(defined($stat->f_flag),    "	f_flag    : " . $stat->f_flag    // 'undef');
    ok(defined($stat->f_namemax), "	f_namemax : " . $stat->f_namemax // 'undef');
    ok(defined($stat->__f_spare)
        , sprintf('	__f_spare : %s'
            , defined($stat->__f_spare)
                ? '[' . join(', ', @{$stat->__f_spare}) . ']'
                : 'undef'));
};

# creat
my $fname = 'testfile';
my $fd;

subtest 'creat' => sub
{
    $fd = GlusterFS::GFAPI::FFI::glfs_creat($fs, "/$fname", O_RDWR, 0644);

    ok(defined($fd), sprintf('glfs_creat(): %s', $fd // 'undef'));

    ok(`ls -al /mnt/libgfapi-perl` =~ m/-rw.+ $fname\n/, "$fname has exsits");
};

# stat
subtest 'stat' => sub
{
    my $stat   = GlusterFS::GFAPI::FFI::Stat->new();
    my $retval = GlusterFS::GFAPI::FFI::glfs_stat($fs, "/$fname", $stat);

    ok($retval == 0, sprintf('glfs_stat(): %d', $retval));

    diag("error: $!") if ($retval);

    ok(defined($stat->st_ino),     "	ino     : " . $stat->st_ino // 'undef');
    ok(defined($stat->st_mode),    "	mode    : " . $stat->st_mode // 'undef');
    ok(defined($stat->st_size),    "	size    : " . $stat->st_size // 'undef');
    ok(defined($stat->st_blksize), "	blksize : " . $stat->st_blksize // 'undef');
    ok(defined($stat->st_uid),     "	uid     : " . $stat->st_uid // 'undef');
    ok(defined($stat->st_gid),     "	gid     : " . $stat->st_gid // 'undef');
    ok(defined($stat->st_atime),   "	atime   : " . $stat->st_atime // 'undef');
    ok(defined($stat->st_mtime),   "	mtime   : " . $stat->st_mtime // 'undef');
    ok(defined($stat->st_ctime),   "	ctime   : " . $stat->st_ctime // 'undef');
};

# lstat
subtest 'lstat' => sub
{
    my $stat   = GlusterFS::GFAPI::FFI::Stat->new();
    my $retval = GlusterFS::GFAPI::FFI::glfs_lstat($fs, "/$fname", $stat);

    ok($retval == 0, sprintf('glfs_lstat(): %d', $retval));

    diag("error: $!") if ($retval);

    ok(defined($stat->st_ino),     "	ino     : " . $stat->st_ino // 'undef');
    ok(defined($stat->st_mode),    "	mode    : " . $stat->st_mode // 'undef');
    ok(defined($stat->st_size),    "	size    : " . $stat->st_size // 'undef');
    ok(defined($stat->st_blksize), "	blksize : " . $stat->st_blksize // 'undef');
    ok(defined($stat->st_uid),     "	uid     : " . $stat->st_uid // 'undef');
    ok(defined($stat->st_gid),     "	gid     : " . $stat->st_gid // 'undef');
    ok(defined($stat->st_atime),   "	atime   : " . $stat->st_atime // 'undef');
    ok(defined($stat->st_mtime),   "	mtime   : " . $stat->st_mtime // 'undef');
    ok(defined($stat->st_ctime),   "	ctime   : " . $stat->st_ctime // 'undef');
};

# from_glfd
subtest 'from_glfd' => sub
{
    my $glfs = GlusterFS::GFAPI::FFI::glfs_from_glfd($fd);

    ok(defined($glfs) && $glfs == $fs
        , sprintf('glfs_from_glfd(): %s', $glfs // 'undef'));
};

undef($fd);

# set_xlator_option
subtest 'set_xlator_option' => sub
{
    my $retval = GlusterFS::GFAPI::FFI::glfs_set_xlator_option(
                $fs,
                '*-write-behind',
                'resync-failed-syncs-after-fsync',
                'on');

    ok($retval == 0, sprintf('glfs_set_xlator_option(): %d', $retval));

    diag("error: $!") if ($retval);
};

# open
subtest 'open' => sub
{
    $fd = GlusterFS::GFAPI::FFI::glfs_open($fs, "/$fname", O_RDWR);

    ok($fd, sprintf('glfs_open(): %d', $fd));
};

# fstat
subtest 'fstat' => sub
{
    my $stat   = GlusterFS::GFAPI::FFI::Stat->new();
    my $retval = GlusterFS::GFAPI::FFI::glfs_fstat($fd, $stat);

    ok($retval == 0, sprintf('glfs_fstat(): %d', $retval));

    diag("error: $!") if ($retval);

    ok(defined($stat->st_ino),     "	ino     : " . $stat->st_ino // 'undef');
    ok(defined($stat->st_mode),    "	mode    : " . $stat->st_mode // 'undef');
    ok(defined($stat->st_size),    "	size    : " . $stat->st_size // 'undef');
    ok(defined($stat->st_blksize), "	blksize : " . $stat->st_blksize // 'undef');
    ok(defined($stat->st_uid),     "	uid     : " . $stat->st_uid // 'undef');
    ok(defined($stat->st_gid),     "	gid     : " . $stat->st_gid // 'undef');
    ok(defined($stat->st_atime),   "	atime   : " . $stat->st_atime // 'undef');
    ok(defined($stat->st_mtime),   "	mtime   : " . $stat->st_mtime // 'undef');
    ok(defined($stat->st_ctime),   "	ctime   : " . $stat->st_ctime // 'undef');
};

# utimens
subtest 'utimens' => sub
{
    sleep 5;

    my $ts     = time;
    my $tspecs = GlusterFS::GFAPI::FFI::Timespecs->new(atime_sec => $ts, mtime_sec => $ts);
    my $retval = GlusterFS::GFAPI::FFI::glfs_utimens($fs, "/$fname", $tspecs);

    ok($retval == 0, sprintf('glfs_utimens(): %d', $retval));

    diag("error: $!") if ($retval);

    my $stat = GlusterFS::GFAPI::FFI::Stat->new();

    $retval = GlusterFS::GFAPI::FFI::glfs_lstat($fs, "/$fname", $stat);

    ok($retval == 0, sprintf('glfs_lstat(): %d', $retval));

    diag("error: $!") if ($retval);

    cmp_ok($stat->st_atime, '==', $ts, "last access time validation");
    cmp_ok($stat->st_mtime, '==', $ts, "modification time validation");
};

# lutimens
subtest 'lutimens' => sub
{
    sleep 5;

    my $ts     = time;
    my $tspecs = GlusterFS::GFAPI::FFI::Timespecs->new(atime_sec => $ts, mtime_sec => $ts);
    my $retval = GlusterFS::GFAPI::FFI::glfs_lutimens($fs, "/$fname", $tspecs);

    ok($retval == 0, sprintf('glfs_lutimens(): %d', $retval));

    diag("error: $!") if ($retval);

    my $stat = GlusterFS::GFAPI::FFI::Stat->new();

    $retval = GlusterFS::GFAPI::FFI::glfs_lstat($fs, "/$fname", $stat);

    ok($retval == 0, sprintf('glfs_lstat(): %d', $retval));

    diag("error: $!") if ($retval);

    cmp_ok($stat->st_atime, '==', $ts, "last access time validation");
    cmp_ok($stat->st_mtime, '==', $ts, "modification time validation");
};

# futimens
subtest 'futimens' => sub
{
    # :TODO 2018/01/29 22:54:29 by P.G.
    # We need the code to check compatibility of futimes().
    # - https://www.mail-archive.com/gluster-devel@nongnu.org/msg11327.html
    diag("Skip glfs_futimens() because compatibility issue");
    diag('- https://www.mail-archive.com/gluster-devel@nongnu.org/msg11327.html');

    ok(1, 'glfs_futimens(): skipped');

    return;

    sleep 5;

    my $ts     = time;
    my $tspecs = GlusterFS::GFAPI::FFI::Timespecs->new(atime_sec => $ts, mtime_sec => $ts);
    my $retval = GlusterFS::GFAPI::FFI::glfs_futimens($fd, $tspecs);

    ok($retval == 0, sprintf('glfs_futimens(): %d', $retval));

    diag("error: $!") if ($retval);

    my $stat = GlusterFS::GFAPI::FFI::Stat->new();

    $retval = GlusterFS::GFAPI::FFI::glfs_lstat($fs, "/$fname", $stat);

    ok($retval == 0, sprintf('glfs_lstat(): %d', $retval));

    diag("error: $!") if ($retval);

    cmp_ok($stat->st_atime, '==', $ts, "last access time validation");
    cmp_ok($stat->st_mtime, '==', $ts, "modification time validation");
};

# posix_lock
subtest 'posix_lock' => sub
{
    my $flock = GlusterFS::GFAPI::FFI::Flock->new(
        l_type   => F_WRLCK,
        l_whence => SEEK_SET,
        l_start  => 0,
        l_len    => 0,
    );

    my $retval = GlusterFS::GFAPI::FFI::glfs_posix_lock($fd, F_SETLKW, $flock);

    ok($retval == 0, sprintf('glfs_posix_lock(): %d', $retval));

    diag("error: $!") if ($retval);
};

# dup
subtest 'dup' => sub
{
    my $retval = GlusterFS::GFAPI::FFI::glfs_dup($fd);

    ok($retval >= 0, sprintf('glfs_dup(): %d', $retval));

    diag("error: $!") if ($retval < 0);
};

# write
subtest 'write' => sub
{
    my $text   = 'This is a lipsum';
    my $len    = length($text);
    my $buffer = strdup($text);
    my $retval = GlusterFS::GFAPI::FFI::glfs_write($fd, $buffer, $len, 0);

    ok($retval > 0, sprintf('glfs_write(): %d', $retval));

    diag("error: $!") if ($retval < 0);

    free($buffer);
};

# lseek
subtest 'lseek' => sub
{
    my $retval = GlusterFS::GFAPI::FFI::glfs_lseek($fd, 0, 0);

    ok($retval == 0, sprintf('glfs_lseek(): %d', $retval));

    diag("error: $!") if ($retval);
};

# read
subtest 'read' => sub
{
    my $buffer = calloc(256, 1);
    my $retval = GlusterFS::GFAPI::FFI::glfs_read($fd, $buffer, 256, 0);

    ok($retval > 0, sprintf('glfs_read(): %s(%d)', cast('opaque' => 'string', $buffer), $retval));

    diag("error: $!") if ($retval < 0);

    free($buffer);
};

# lseek
subtest 'lseek' => sub
{
    my $retval = GlusterFS::GFAPI::FFI::glfs_lseek($fd, 0, 0);

    ok($retval == 0, sprintf('glfs_lseek(): %d', $retval));

    diag("error: $!") if ($retval);
};

# writev
subtest 'writev' => sub
{
    my $retval = GlusterFS::GFAPI::FFI::glfs_writev($fd, ['hello', 'gfapi'], 0);

    ok($retval > 0, sprintf('glfs_writev(): %d', $retval));

    diag("error: $!") if ($retval < 0);
};

# lseek
subtest 'lseek' => sub
{
    my $retval = GlusterFS::GFAPI::FFI::glfs_lseek($fd, 0, 0);

    ok($retval == 0, sprintf('glfs_lseek(): %d', $retval));

    diag("error: $!") if ($retval);
};

# readv
subtest 'readv' => sub
{
    my ($retval, @data) = GlusterFS::GFAPI::FFI::glfs_readv($fd, [5, 5], 0);

    ok($retval > 0, sprintf('glfs_readv(): %d', $retval));

    ok(@data == 2, sprintf('	number of data : %d', scalar(@data)));
    ok($data[0] eq 'hello', sprintf('		data[0] : %s', $data[0]));
    ok($data[1] eq 'gfapi', sprintf('		data[1] : %s', $data[1]));

    diag("error: $!") if (@data != 2);
};

# pwritev
subtest 'pwritev' => sub
{
    my $retval = GlusterFS::GFAPI::FFI::glfs_pwritev($fd, ['hello', 'gfapi'], 10, 0);

    ok($retval > 0, sprintf('glfs_pwritev(): %d', $retval));

    diag("error: $!") if ($retval < 0);
};

# preadv
subtest 'preadv' => sub
{
    my ($retval, @data) = GlusterFS::GFAPI::FFI::glfs_preadv($fd, [5, 5], 10, 0);

    ok($retval > 0, sprintf('glfs_preadv(): %d', $retval));

    ok(@data == 2, sprintf('	number of data : %d', scalar(@data)));
    ok($data[0] eq 'hello', sprintf('		data[0] : %s', $data[0]));
    ok($data[1] eq 'gfapi', sprintf('		data[1] : %s', $data[1]));

    diag("error: $!") if (@data != 2);
};

# truncate
subtest 'truncate' => sub
{
    my $retval = GlusterFS::GFAPI::FFI::glfs_truncate($fs, "/$fname", 0);

    ok($retval == 0, sprintf('glfs_truncate(): %d', $retval));

    diag("error: $!") if ($retval);

    my $stat = GlusterFS::GFAPI::FFI::Stat->new();

    $retval = GlusterFS::GFAPI::FFI::glfs_lstat($fs, "/$fname", $stat);

    ok($retval == 0, sprintf('glfs_lstat(): %d', $retval));

    diag("error: $!") if ($retval);

    cmp_ok($stat->st_size, '==', 0, '	size : ' . $stat->st_size // 'undef');
};

# pwrite
subtest 'pwrite' => sub
{
    my $text   = 'This is a lipsum';
    my $len    = length($text);
    my $buffer = strdup($text);
    my $retval = GlusterFS::GFAPI::FFI::glfs_pwrite($fd, $buffer, $len, 100);

    ok($retval > 0, sprintf('glfs_pwrite(): %d', $retval));

    diag("error: $!") if ($retval < 0);

    free($buffer);
};

# fsync
subtest 'fsync' => sub
{
    my $retval = GlusterFS::GFAPI::FFI::glfs_fsync($fd);

    ok($retval == 0, sprintf('glfs_fsync(): %d', $retval));

    diag("error: $!") if ($retval);
};

# fdatasync
subtest 'fdatasync' => sub
{
    my $retval = GlusterFS::GFAPI::FFI::glfs_fdatasync($fd);

    ok($retval == 0, sprintf('glfs_fdatasync(): %d', $retval));

    diag("error: $!") if ($retval);
};

# pread
subtest 'pread' => sub
{
    my $buffer = calloc(256, 1);
    my $retval = GlusterFS::GFAPI::FFI::glfs_pread($fd, $buffer, 256, 100);

    ok($retval > 0, sprintf('glfs_pread(): %s(%d)', cast('opaque' => 'string', $buffer), $retval));

    diag("error: $!") if ($retval < 0);

    free($buffer);
};

# ftruncate
subtest 'ftruncate' => sub
{
    my $retval = GlusterFS::GFAPI::FFI::glfs_ftruncate($fd, 0);

    ok($retval == 0, sprintf('glfs_ftruncate(): %d', $retval));

    diag("error: $!") if ($retval);

    my $stat = GlusterFS::GFAPI::FFI::Stat->new();

    $retval = GlusterFS::GFAPI::FFI::glfs_lstat($fs, "/$fname", $stat);

    ok($retval == 0, sprintf('glfs_lstat(): %d', $retval));

    diag("error: $!") if ($retval);

    cmp_ok($stat->st_size, '==', 0, '	size : ' . $stat->st_size // 'undef');
};

# chmod
subtest 'chmod' => sub
{
    my $retval = GlusterFS::GFAPI::FFI::glfs_chmod($fs, "/$fname", 0777);

    ok($retval == 0, sprintf('glfs_chmod(): %d', $retval));

    diag("error: $!") if ($retval);

    my $stat = GlusterFS::GFAPI::FFI::Stat->new();

    $retval = GlusterFS::GFAPI::FFI::glfs_lstat($fs, "/$fname", $stat);

    ok($retval == 0, sprintf('glfs_lstat(): %d', $retval));

    diag("error: $!") if ($retval);

    my $perm = $stat->st_mode & (S_IRWXU | S_IRWXG | S_IRWXO);

    cmp_ok($perm, '==', 0777, '	mode : ' . sprintf('%o', $perm));
};

# fchmod
subtest 'fchmod' => sub
{
    my $retval = GlusterFS::GFAPI::FFI::glfs_fchmod($fd, 0644);

    ok($retval == 0, sprintf('glfs_fchmod(): %d', $retval));

    diag("error: $!") if ($retval);

    my $stat = GlusterFS::GFAPI::FFI::Stat->new();

    $retval = GlusterFS::GFAPI::FFI::glfs_lstat($fs, "/$fname", $stat);

    ok($retval == 0, sprintf('glfs_lstat(): %d', $retval));

    diag("error: $!") if ($retval);

    my $perm = $stat->st_mode & (S_IRWXU | S_IRWXG | S_IRWXO);

    cmp_ok($perm, '==', 0644, '	mode : ' . sprintf('%o', $perm));
};

my ($login, $pass, $uid, $gid) = getpwuid($<);

# chown
subtest 'chown' => sub
{
    my $retval = GlusterFS::GFAPI::FFI::glfs_chown($fs, "/$fname", $uid, $gid);

    ok($retval == 0, sprintf('glfs_chown(): %d', $retval));

    diag("error: $!") if ($retval);
};

# lchown
subtest 'lchown' => sub
{
    my $retval = GlusterFS::GFAPI::FFI::glfs_lchown($fs, "/$fname", $uid, $gid);

    ok($retval == 0, sprintf('glfs_lchown(): %d', $retval));

    diag("error: $!") if ($retval);
};

# fchown
subtest 'fchown' => sub
{
    my $retval = GlusterFS::GFAPI::FFI::glfs_fchown($fd, $uid, $gid);

    ok($retval == 0, sprintf('glfs_fchown(): %d', $retval));

    diag("error: $!") if ($retval);
};

# fallocate
subtest 'fallocate' => sub
{
    my $retval = GlusterFS::GFAPI::FFI::glfs_fallocate($fd, 0, 0, 1024);

    ok($retval == 0, sprintf('glfs_fallocate(): %d', $retval));

    diag("error: $!") if ($retval);

    my $stat = GlusterFS::GFAPI::FFI::Stat->new();

    $retval = GlusterFS::GFAPI::FFI::glfs_lstat($fs, "/$fname", $stat);

    ok($retval == 0, sprintf('glfs_fallocate(): %d', $retval));

    diag("error: $!") if ($retval);

    system('ls -al /mnt/libgfapi-perl');
};

# discard
subtest 'discard' => sub
{
    # :TODO 2018/01/31 10:50:02 by P.G.
    # we need to verify discarding of this range
    my $retval = GlusterFS::GFAPI::FFI::glfs_discard($fd, 0, 128);

    ok($retval == 0, sprintf('glfs_discard(): %d', $retval));

    diag("error: $!") if ($retval);
};

# zerofill
subtest 'zerofill' => sub
{
    # :TODO 2018/01/31 10:50:02 by P.G.
    # we need to verify zero-filling of this range
    my $retval = GlusterFS::GFAPI::FFI::glfs_zerofill($fd, 128, 128);

    ok($retval == 0, sprintf('glfs_zerofill(): %d', $retval));

    diag("error: $!") if ($retval);
};

# setxattr
subtest 'setxattr' => sub
{
    my $name   = 'user.key1';
    my $value  = strdup('hello');
    my $retval = GlusterFS::GFAPI::FFI::glfs_setxattr($fs, "/${fname}", $name, $value, length('hello'), 0);

    ok($retval == 0, sprintf('setxattr: %d', $retval));

    diag("error: $!") if ($retval);

    free($value);
};

# getxattr
subtest 'getxattr' => sub
{
    my $name   = 'user.key1';
    my $value  = calloc(1, 256);
    my $retval = GlusterFS::GFAPI::FFI::glfs_getxattr($fs, "/${fname}", $name, $value, 256);

    ok($retval == length('hello'), sprintf('getxattr: %d', $retval));

    diag("error: $!") if ($retval != length('hello'));

    ok(cast('opaque' => 'string', $value) eq 'hello',
        sprintf('	key1 : %s',
            $value ? cast('opaque' => 'string', $value) : 'undef'));

    free($value);
};

# listxattr
subtest 'listxattr' => sub
{
    my $buffer = calloc(1, 4096);
    my $retval = GlusterFS::GFAPI::FFI::glfs_listxattr($fs, "/${fname}", $buffer, 4096);

    ok($retval >= 0, sprintf('listxattr: %d', $retval));

    diag("error: $!") if ($retval < 0);
};

# removexattr
subtest 'removexattr' => sub
{
    my $name   = 'user.key1';
    my $retval = GlusterFS::GFAPI::FFI::glfs_removexattr($fs, "/${fname}", $name);

    ok($retval == 0, sprintf('removexattr: %d', $retval));

    diag("error: $!") if ($retval);
};

# lsetxattr
subtest 'lsetxattr' => sub
{
    my $name   = 'user.key2';
    my $value  = strdup('hello');
    my $retval = GlusterFS::GFAPI::FFI::glfs_lsetxattr($fs, "/${fname}", $name, $value, length('hello'), 0);

    ok($retval == 0, sprintf('lsetxattr: %d', $retval));

    diag("error: $!") if ($retval);

    free($value);
};

# lgetxattr
subtest 'lgetxattr' => sub
{
    my $name   = 'user.key2';
    my $value  = calloc(1, 256);
    my $retval = GlusterFS::GFAPI::FFI::glfs_lgetxattr($fs, "/${fname}", $name, $value, 256);

    ok($retval == length('hello'), sprintf('lgetxattr: %d', $retval));

    diag("error: $!") if ($retval != length('hello'));

    ok(cast('opaque' => 'string', $value) eq 'hello',
        sprintf('	key2 : %s',
            $value ? cast('opaque' => 'string', $value) : 'undef'));

    free($value);
};

# llistxattr
subtest 'llistxattr' => sub
{
    my $buffer = calloc(1, 4096);
    my $retval = GlusterFS::GFAPI::FFI::glfs_llistxattr($fs, "/${fname}", $buffer, 4096);

    ok($retval >= 0, sprintf('llistxattr: %d', $retval));

    diag("error: $!") if ($retval < 0);
};

# lremovexattr
subtest 'lremovexattr' => sub
{
    my $name   = 'user.key2';
    my $retval = GlusterFS::GFAPI::FFI::glfs_lremovexattr($fs, "/${fname}", $name);

    ok($retval == 0, sprintf('lremovexattr: %d', $retval // 'undef'));

    diag("error: $!") if ($retval);
};

# fsetxattr
subtest 'fsetxattr' => sub
{
    my $name   = 'user.key3';
    my $value  = strdup('hello');
    my $retval = GlusterFS::GFAPI::FFI::glfs_fsetxattr($fd, $name, $value, length('hello'), 0);

    ok($retval == 0, sprintf('fsetxattr: %d', $retval));

    diag("error: $!") if ($retval);

    free($value);
};

# fgetxattr
subtest 'fgetxattr' => sub
{
    my $name   = 'user.key3';
    my $value  = calloc(1, 256);
    my $retval = GlusterFS::GFAPI::FFI::glfs_fgetxattr($fd, $name, $value, 256);

    ok($retval == length('hello'), sprintf('fgetxattr: %d', $retval));

    diag("error: $!") if ($retval != length('hello'));

    ok(cast('opaque' => 'string', $value) eq 'hello',
        sprintf('	key3 : %s',
            $value ? cast('opaque' => 'string', $value) : 'undef'));

    free($value);
};

# flistxattr
subtest 'flistxattr' => sub
{
    my $buffer = calloc(1, 4096);
    my $retval = GlusterFS::GFAPI::FFI::glfs_flistxattr($fd, $buffer, 4096);

    ok($retval >= 0, sprintf('flistxattr: %d', $retval));

    diag("error: $!") if ($retval < 0);
};

# fremovexattr
subtest 'fremovexattr' => sub
{
    my $name   = 'user.key3';
    my $retval = GlusterFS::GFAPI::FFI::glfs_fremovexattr($fd, $name);

    ok($retval == 0, sprintf('fremovexattr: %d', $retval));

    diag("error: $!") if ($retval);
};

# close
subtest 'close' => sub
{
    my $retval = GlusterFS::GFAPI::FFI::glfs_close($fd);

    ok($retval == 0, sprintf('glfs_close(): %d', $retval));

    diag("error: $!") if ($retval);
};

# access
subtest 'access' => sub
{
    my $stat = GlusterFS::GFAPI::FFI::Stat->new();

    my $retval = GlusterFS::GFAPI::FFI::glfs_lstat($fs, "/$fname", $stat);

    ok($retval == 0, sprintf('glfs_lstat(): %d', $retval));

    diag("error: $!") if ($retval);

    my $perm = $stat->st_mode & (S_IRWXU | S_IRWXG | S_IRWXO);

    cmp_ok($perm, '==', 0644, '	mode : ' . sprintf('%o', $perm));

    no strict 'refs';

    # This is a trick to invalidate cache for this file
    system('ls -al /mnt/libgfapi-perl 2>&1 1>/dev/null');

    map
    {
        $retval = GlusterFS::GFAPI::FFI::glfs_access($fs, "/$fname", *{"POSIX::$_"}{CODE}->());

        ok(($_ eq 'X_OK' ? abs($retval) : !$retval),
            sprintf('glfs_access(%s): %d', $_, $retval));

        diag("error: $!") if ($_ eq 'X_OK' ? !abs($retval) : $retval);
    } ('F_OK', 'R_OK', 'W_OK', 'X_OK');

    use strict 'refs';

    return;
};

# link
subtest 'link' => sub
{
    my $retval = GlusterFS::GFAPI::FFI::glfs_link($fs, "${fname}", "/${fname}_hardlink");

    ok($retval == 0, sprintf('glfs_link(): %d', $retval));

    diag("error: $!") if ($retval);
};

# symlink
subtest 'symlink' => sub
{
    my $retval = GlusterFS::GFAPI::FFI::glfs_symlink($fs, '/tmp', "/${fname}_symlink");

    ok($retval == 0, sprintf('glfs_symlink(): %d', $retval));

    diag("error: $!") if ($retval);
};

# readlink
subtest 'readlink' => sub
{
    my $buffer = calloc(256, 1);

    my $retval = GlusterFS::GFAPI::FFI::glfs_readlink($fs, "/${fname}_symlink", $buffer, 256);

    my $linkname = substr($buffer, 0, $retval);

    ok($retval == length('/tmp'), sprintf('glfs_readlink(): %d', $retval));
    ok($linkname eq '/tmp', sprintf('	linkname: %s', $linkname // 'undef'));

    diag("error: $!") if ($retval < 0);

    free($buffer);
};

# mknod
subtest 'mknod' => sub
{
    my $retval = GlusterFS::GFAPI::FFI::glfs_mknod($fs, '/mknod', 0644, S_IFIFO | 0644);

    ok($retval == 0, sprintf('glfs_mknod(): %d', $retval));

    diag("error: $!") if ($retval);
};

# rename
subtest 'rename' => sub
{
    my $retval = GlusterFS::GFAPI::FFI::glfs_rename($fs, '/mknod', '/mknod_renamed');

    ok($retval == 0, sprintf('glfs_rename(): %d', $retval));

    diag("error: $!") if ($retval < 0);
};

# mkdir
subtest 'mkdir' => sub
{
    my $retval = GlusterFS::GFAPI::FFI::glfs_mkdir($fs, '/testdir', 0644);

    ok($retval == 0, sprintf('glfs_mkdir(): %d', $retval));

    diag("error: $!") if ($retval);

    map
    {
        $retval = GlusterFS::GFAPI::FFI::glfs_mkdir($fs, "$_", 0644);

        ok($retval == 0, sprintf('glfs_mkdir(): %d', $retval));
        diag("error: $!") if ($retval);

        ok(`ls -al /mnt/libgfapi-perl` =~ m/drw.* $_\n/, "$_ has exists");
    } qw/a b c d/;
};

# chdir
subtest 'chdir' => sub
{
    my $retval = GlusterFS::GFAPI::FFI::glfs_chdir($fs, '/testdir');

    ok($retval == 0, sprintf('glfs_chdir(): %d', $retval));

    diag("error: $!") if ($retval);
};

# getcwd
subtest 'getcwd' => sub
{
    my $buffer = "\0" x 4096;
    my $cwd    = GlusterFS::GFAPI::FFI::glfs_getcwd($fs, $buffer, 4096);

    ok($cwd eq '/testdir', sprintf('glfs_getcwd(): %s', $cwd));
};

# realpath
subtest 'realpath' => sub
{
    my $buffer = "\0" x 4096;

    my $retval = GlusterFS::GFAPI::FFI::glfs_realpath($fs, '.', $buffer);

    ok($retval, sprintf('	realpath: %s', $retval // 'undef'));
};

# opendir
subtest 'opendir' => sub
{
    $fd = GlusterFS::GFAPI::FFI::glfs_opendir($fs, '/');

    ok(defined($fd), sprintf('glfs_opendir(): %s', $fd // 'undef'));

    diag("error: $!") if (!defined($fd));
};

# fchdir
subtest 'fchdir' => sub
{
    my $retval = GlusterFS::GFAPI::FFI::glfs_fchdir($fd);

    ok($retval == 0, sprintf('glfs_fchdir(): %s', $retval));

    diag("error: $!") if ($retval);
};

# getcwd
subtest 'getcwd' => sub
{
    my $buffer = "\0" x 4096;
    my $cwd    = GlusterFS::GFAPI::FFI::glfs_getcwd($fs, $buffer, 4096);

    ok($cwd eq '/', sprintf('glfs_getcwd(): %s', $cwd));
};

my $dirloc;

# telldir
subtest 'telldir' => sub
{
    $dirloc = GlusterFS::GFAPI::FFI::glfs_telldir($fd);

    ok($dirloc >= 0, sprintf('glfs_telldir(): %s', $dirloc));

    diag("error: $!") if ($dirloc < 0);
};

# readdir
subtest 'readdir' => sub
{
    my $entry = GlusterFS::GFAPI::FFI::glfs_readdir($fd);

    ok(defined($entry), sprintf('glfs_readdir(): %s', $entry->d_name));

    map
    {
        ok(defined($entry->$_)
            , sprintf('	%s : %s', $_, $entry->$_ // 'undef'));
    } qw/d_ino d_off d_reclen d_type/;
};

# seekdir
subtest 'seekdir' => sub
{
    GlusterFS::GFAPI::FFI::glfs_seekdir($fd, $dirloc);

    my $err    = $!;
    my $retval = GlusterFS::GFAPI::FFI::glfs_telldir($fd);

    ok($retval == $dirloc, sprintf('glfs_seekdir(): %s', $retval));

    diag("error: $!") if ($retval != $dirloc);
};

# readdir_r
subtest 'readdir_r' => sub
{
    my $entry  = GlusterFS::GFAPI::FFI::Dirent->new(d_reclen => 256);
    my $result = GlusterFS::GFAPI::FFI::Dirent->new();

    while (!(my $retval
            = GlusterFS::GFAPI::FFI::glfs_readdir_r($fd, $entry, \$result)))
    {
        $result = GlusterFS::GFAPI::FFI::cast_Dirent($result);

        last if (!defined($result));

        ok($retval == 0, sprintf("glfs_readdir_r(): %d", $retval));
        ok(defined($result), sprintf('DIR: %s', $result->d_name));

        map
        {
            ok(defined($result->$_)
                , sprintf('	%s : %s', $_, $result->$_ // 'undef'));
        } qw/d_ino d_off d_reclen d_type/;
    }
};

# closedir
subtest 'closedir' => sub
{
    my $retval = GlusterFS::GFAPI::FFI::glfs_closedir($fd);

    ok($retval == 0, sprintf('glfs_closedir(): %d', $retval));

    diag("error: $!") if ($retval);
};

# opendir
subtest 'opendir' => sub
{
    $fd = GlusterFS::GFAPI::FFI::glfs_opendir($fs, '/');

    ok($fd, sprintf('glfs_opendir(): %d', $fd));
};

# telldir
subtest 'telldir' => sub
{
    $dirloc = GlusterFS::GFAPI::FFI::glfs_telldir($fd);

    ok($dirloc >= 0, sprintf('glfs_telldir(): %s', $dirloc));

    diag("error: $!") if ($dirloc < 0);
};

# readdirplus
subtest 'readdirplus' => sub
{
    my $stat  = GlusterFS::GFAPI::FFI::Stat->new();
    my $entry = GlusterFS::GFAPI::FFI::glfs_readdirplus($fd, $stat);

    ok(defined($entry), sprintf('glfs_readdirplus(): %s', $entry->d_name));

    map
    {
        ok(defined($entry->$_)
            , sprintf('	%s : %s', $_, $entry->$_ // 'undef'));
    } qw/d_ino d_off d_reclen d_type/;

    ok(defined($stat), sprintf('STAT: %s', $entry->d_name));

    ok(defined($stat->st_ino),     "	ino     : " . $stat->st_ino // 'undef');
    ok(defined($stat->st_mode),    "	mode    : " . $stat->st_mode // 'undef');
    ok(defined($stat->st_size),    "	size    : " . $stat->st_size // 'undef');
    ok(defined($stat->st_blksize), "	blksize : " . $stat->st_blksize // 'undef');
    ok(defined($stat->st_uid),     "	uid     : " . $stat->st_uid // 'undef');
    ok(defined($stat->st_gid),     "	gid     : " . $stat->st_gid // 'undef');
    ok(defined($stat->st_atime),   "	atime   : " . $stat->st_atime // 'undef');
    ok(defined($stat->st_mtime),   "	mtime   : " . $stat->st_mtime // 'undef');
    ok(defined($stat->st_ctime),   "	ctime   : " . $stat->st_ctime // 'undef');
};

# seekdir
subtest 'seekdir' => sub
{
    GlusterFS::GFAPI::FFI::glfs_seekdir($fd, $dirloc);

    my $err    = $!;
    my $retval = GlusterFS::GFAPI::FFI::glfs_telldir($fd);

    ok($retval == $dirloc, sprintf('glfs_seekdir(): %s', $retval));

    diag("error: $!") if ($retval != $dirloc);
};

# readdirplus_r
subtest 'readdirplus_r' => sub
{
    my $stat   = GlusterFS::GFAPI::FFI::Stat->new();
    my $entry  = GlusterFS::GFAPI::FFI::Dirent->new(d_reclen => 256);
    my $result = GlusterFS::GFAPI::FFI::Dirent->new();

    while (!(my $retval
            = GlusterFS::GFAPI::FFI::glfs_readdirplus_r($fd, $stat, $entry, \$result)))
    {
        $result = GlusterFS::GFAPI::FFI::cast_Dirent($result);

        last if (!defined($result));

        ok($retval == 0, sprintf("glfs_readdirplus_r(): %d", $retval));
        ok(defined($result), sprintf('DIR: %s', $result->d_name));

        map
        {
            ok(defined($result->$_)
                , sprintf('	%s : %s', $_, $result->$_ // 'undef'));
        } qw/d_ino d_off d_reclen d_type/;

        ok(defined($stat), sprintf('STAT: %s', $result->d_name));

        ok(defined($stat->st_ino),     "	ino     : " . $stat->st_ino // 'undef');
        ok(defined($stat->st_mode),    "	mode    : " . $stat->st_mode // 'undef');
        ok(defined($stat->st_size),    "	size    : " . $stat->st_size // 'undef');
        ok(defined($stat->st_blksize), "	blksize : " . $stat->st_blksize // 'undef');
        ok(defined($stat->st_uid),     "	uid     : " . $stat->st_uid // 'undef');
        ok(defined($stat->st_gid),     "	gid     : " . $stat->st_gid // 'undef');
        ok(defined($stat->st_atime),   "	atime   : " . $stat->st_atime // 'undef');
        ok(defined($stat->st_mtime),   "	mtime   : " . $stat->st_mtime // 'undef');
        ok(defined($stat->st_ctime),   "	ctime   : " . $stat->st_ctime // 'undef');
    }
};

# closedir
subtest 'closedir' => sub
{
    my $retval = GlusterFS::GFAPI::FFI::glfs_closedir($fd);

    ok($retval == 0, sprintf('glfs_closedir(): %d', $retval));

    diag("error: $!") if ($retval);
};

# rmdir
subtest 'rmdir' => sub
{
    map
    {
        my $retval = GlusterFS::GFAPI::FFI::glfs_rmdir($fs, "$_", 0644);

        ok($retval == 0, sprintf('glfs_rmdir(): %d', $retval));
        diag("error: $!") if ($retval);

        ok(`ls -al /mnt/libgfapi-perl` !~ m/drw.* $_\n/, "$_ does not exists");
    } qw/a b c d/;
};

# fini
subtest 'fini' => sub
{
    my $retval = GlusterFS::GFAPI::FFI::glfs_fini($fs);

    ok($retval == 0, sprintf('glfs_fini(): %d', $retval));

    diag("error: $!") if ($retval);
};

done_testing();
