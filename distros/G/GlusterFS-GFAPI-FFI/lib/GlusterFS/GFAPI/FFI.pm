package GlusterFS::GFAPI::FFI::Stat;

use FFI::Platypus::Record;

record_layout(qw/
    ulong   st_dev
    ulong   st_ino
    ulong   st_nlink
    uint    st_mode
    uint    st_uid
    uint    st_gid
    ulong   st_rdev
    ulong   st_size
    ulong   st_blksize
    ulong   st_blocks
    ulong   st_atime
    ulong   st_atimensec
    ulong   st_mtime
    ulong   st_mtimensec
    ulong   st_ctime
    ulong   st_ctimensec
/);

package GlusterFS::GFAPI::FFI::Statvfs;

use FFI::Platypus::Record;

record_layout(qw/
    ulong   f_bsize
    ulong   f_frsize
    ulong   f_blocks
    ulong   f_bfree
    ulong   f_bavail
    ulong   f_files
    ulong   f_ffree
    ulong   f_favail
    ulong   f_fsid
    ulong   f_flag
    ulong   f_namemax
    int[6]  __f_spare
/);

package GlusterFS::GFAPI::FFI::Dirent;

use FFI::Platypus::Record;

record_layout(qw/
    ulong       d_ino
    ulong       d_off
    ushort      d_reclen
    char        d_type
    string(256) d_name
/);

package GlusterFS::GFAPI::FFI::Timespecs;

use FFI::Platypus::Record;

record_layout(qw/
    long    atime_sec
    long    atime_nsec
    long    mtime_sec
    long    mtime_nsec
/);

package GlusterFS::GFAPI::FFI::Iovec;

use FFI::Platypus::Record;

record_layout(qw/
    opaque  iov_base
    size_t  iov_len
/);

#package GlusterFS::GFAPI::FFI::IovecArray;
#
#sub new
#{
#    my ($class, %args) = @_;
#
#    my $self = {
#        list => [],
#    };
#
#    bless $self, $class;
#
#    return $self;
#}
#
#sub list
#{
#    my $self = shift;
#    my %args = @_;
#
#    return @{$self->{list}};
#}
#
#sub count
#{
#    my $self = shift;
#    my %args = @_;
#
#    return scalar(@{$self->{list}});
#}
#
#sub add
#{
#    my $self = shift;
#    my $buff = shift;
#
#    my ($p_buff, $len) = buffer_from_scalar($buff);
#
#    my %vector = (
#        iov_base => $p_buff,
#        iov_len  => $len,
#    );
#
#    return push(@{$self->{list}}, \%vector);
#}
#
#sub del
#{
#    my $self = shift;
#    my $idx  = shift;
#
#    my $vector;
#
#    if (defined($idx) && $idx < $self->count)
#    {
#        $vector = splice(@{$self->{list}}, $idx, 1);
#    }
#
#    return try
#    {
#        if ($vector->{iov_base})
#        {
#            free($vector->{iov_base});
#        }
#
#        return 0;
#    }
#    catch
#    {
#        return -1;
#    };
#}

package GlusterFS::GFAPI::FFI::Flock;

use FFI::Platypus::Record;

record_layout(qw/
    short   l_type
    short   l_whence
    off_t   l_start
    off_t   l_len
    sint32  l_pid
/);

# /* Type of lock: F_RDLCK, F_WRLCK, F_UNLCK */
# /* How to interpret l_start: SEEK_SET, SEEK_CUR, SEEK_END */
# /* Starting offset for lock */
# /* Number of bytes to lock */
# /* PID of process blocking our lock (set by F_GETLK and F_OFD_GETLK) */

package GlusterFS::GFAPI::FFI;

BEGIN
{
    our $AUTHOR  = 'cpan:potatogim';
    our $VERSION = '0.4';
}

use strict;
use warnings;
use utf8;

use FFI::Platypus;
use FFI::Platypus::API;
use FFI::Platypus::Declare  qw/void string opaque/;
use FFI::Platypus::Memory   qw/calloc free memcpy/;
use FFI::Platypus::Buffer   qw/scalar_to_buffer/;

use GlusterFS::GFAPI::FFI::Util qw/libgfapi_soname/;
use Carp;

our $FFI = FFI::Platypus->new(lib => libgfapi_soname());

# Custom type
$FFI->type('int'        => 'ssize_t');
$FFI->type('record(16)' => 'uuid_t');
$FFI->type('opaque'     => 'glfs_t');
$FFI->type('opaque'     => 'glfs_fd_t');
$FFI->type('opaque'     => 'glfs_object');

$FFI->type('record(GlusterFS::GFAPI::FFI::Stat)'      => 'Stat');
$FFI->type('record(GlusterFS::GFAPI::FFI::Statvfs)'   => 'Statvfs');
$FFI->type('record(GlusterFS::GFAPI::FFI::Dirent)'    => 'Dirent');
$FFI->type('record(GlusterFS::GFAPI::FFI::Timespecs)' => 'Timespecs');
$FFI->type('record(GlusterFS::GFAPI::FFI::Iovec)'     => 'Iovec');
$FFI->type('record(GlusterFS::GFAPI::FFI::Flock)'     => 'Flock');

# Closure
$FFI->type('(glfs_fd_t, ssize_t, opaque)->opaque', 'glfs_io_cbk');

# Type-Caster
$FFI->attach_cast('cast_Dirent', 'opaque', 'Dirent');

# Facilities
$FFI->attach(glfs_init => ['glfs_t'], => 'int');
$FFI->attach(glfs_new => ['string'] => 'glfs_t');
$FFI->attach(glfs_set_volfile_server => ['glfs_t', 'string', 'string', 'int'] => 'int');
$FFI->attach(glfs_set_logging => ['glfs_t', 'string', 'int'] => 'int');
$FFI->attach(glfs_fini => ['glfs_t'] => 'int');

# Features
$FFI->attach(glfs_get_volumeid => ['glfs_t', 'uuid_t', 'size_t'] => 'int');
$FFI->attach(glfs_setfsuid => ['unsigned int'] => 'int');
$FFI->attach(glfs_setfsgid => ['unsigned int'] => 'int');
$FFI->attach(glfs_setfsgroups => ['size_t', 'int*'] => 'int');
$FFI->attach(glfs_open => ['glfs_t', 'string', 'int'] => 'glfs_fd_t');
$FFI->attach(glfs_creat => ['glfs_t', 'string', 'int', 'mode_t'] => 'glfs_fd_t');
$FFI->attach(glfs_close => ['glfs_fd_t'] => 'int');
$FFI->attach(glfs_from_glfd => ['glfs_fd_t'] => 'glfs_t');
$FFI->attach(glfs_set_xlator_option => ['glfs_t', 'string', 'string', 'string'] => 'int');
$FFI->attach(glfs_read => ['glfs_fd_t', 'opaque', 'size_t', 'int'] => 'ssize_t');
$FFI->attach(glfs_write => ['glfs_fd_t', 'opaque', 'size_t', 'int'] => 'ssize_t');
$FFI->attach(glfs_read_async => ['glfs_fd_t', 'opaque', 'size_t', 'int', 'glfs_io_cbk', 'opaque'] => 'int');
$FFI->attach(glfs_write_async => ['glfs_fd_t', 'opaque', 'size_t', 'int', 'glfs_io_cbk', 'opaque'] => 'int');
$FFI->attach(glfs_readv => ['glfs_fd_t', 'opaque', 'int', 'int'] => 'ssize_t'
    , sub {
        my ($sub, $fd, $lengths, $flags) = @_;

        my $vsize = $FFI->sizeof('Iovec');
        my $psize = $FFI->sizeof('opaque');
        my $count = scalar(@{$lengths});

        # 버퍼 할당
        my @data   = ();
        my $buffer = calloc($count, $vsize);
        my @ptrs   = ();

        for (my $i=0; $i<$count; $i++)
        {
            $data[$i]      = "\0" x $lengths->[$i];
            $lengths->[$i] = pack('L!', $lengths->[$i]);

            my $p_base  = pack('P', $data[$i]);
            my $p_len   = pack('P', $lengths->[$i]);
            my $pp_base = pack('P', $p_base);

            push(@ptrs, $p_base, $p_len, $pp_base);

            memcpy($buffer + ($i * $vsize), unpack('L!', $pp_base), $psize);
            memcpy($buffer + ($i * $vsize) + $psize, unpack('L!', $p_len), $psize);
        }

        # readv 호출
        my $retval = $sub->($fd, $buffer, $count, $flags);

        free($buffer);

        return $retval, @data;
    });
$FFI->attach(glfs_writev => ['glfs_fd_t', 'opaque', 'int', 'int'] => 'ssize_t'
    , sub {
        my ($sub, $fd, $vectors, $flags) = @_;

        my $vsize = $FFI->sizeof('Iovec');
        my $psize = $FFI->sizeof('opaque');
        my $count = scalar(@{$vectors});

        my $buffer = calloc($count, $vsize);
        my @len    = ();
        my @ptrs   = ();

        for (my $i=0; $i<$count; $i++)
        {
            $len[$i] = pack('L!', length($vectors->[$i]));

            my $p_base  = pack('P', $vectors->[$i]);
            my $p_len   = pack('P', $len[$i]);
            my $pp_base = pack('P', $p_base);

            push(@ptrs, $p_base, $p_len, $pp_base);

            memcpy($buffer + ($vsize * $i), unpack('L!', $pp_base), $psize);
            memcpy($buffer + ($vsize * $i) + $psize, unpack('L!', $p_len), length($len[$i]));
        }

        my $retval = $sub->($fd, $buffer, $count, $flags);

        free($buffer);

        return $retval;
    });
$FFI->attach(glfs_readv_async => ['glfs_fd_t', 'Iovec', 'int', 'int', 'glfs_io_cbk', 'opaque'] => 'int');
$FFI->attach(glfs_writev_async => ['glfs_fd_t', 'Iovec', 'int', 'int', 'glfs_io_cbk', 'opaque'] => 'int');
$FFI->attach(glfs_pread => ['glfs_fd_t', 'opaque', 'size_t', 'int', 'int'] => 'ssize_t');
$FFI->attach(glfs_pwrite => ['glfs_fd_t', 'opaque', 'size_t', 'int', 'int'] => 'ssize_t');
$FFI->attach(glfs_pread_async => ['glfs_fd_t', 'opaque', 'size_t', 'off_t', 'int', 'glfs_io_cbk', 'opaque'] => 'int');
$FFI->attach(glfs_pwrite_async => ['glfs_fd_t', 'opaque', 'size_t', 'off_t', 'int', 'glfs_io_cbk', 'opaque'] => 'int');
$FFI->attach(glfs_preadv => ['glfs_fd_t', 'opaque', 'int', 'off_t', 'int'] => 'ssize_t'
    , sub {
        my ($sub, $fd, $lengths, $offset, $flags) = @_;

        my $vsize = $FFI->sizeof('Iovec');
        my $psize = $FFI->sizeof('opaque');
        my $count = scalar(@{$lengths});

        # 버퍼 할당
        my @data   = ();
        my $buffer = calloc($count, $vsize);
        my @ptrs   = ();

        for (my $i=0; $i<$count; $i++)
        {
            $data[$i]      = "\0" x $lengths->[$i];
            $lengths->[$i] = pack('L!', $lengths->[$i]);

            my $p_base  = pack('P', $data[$i]);
            my $p_len   = pack('P', $lengths->[$i]);
            my $pp_base = pack('P', $p_base);

            push(@ptrs, $p_base, $p_len, $pp_base);

            memcpy($buffer + ($i * $vsize), unpack('L!', $pp_base), $psize);
            memcpy($buffer + ($i * $vsize) + $psize, unpack('L!', $p_len), $psize);
        }

        # readv 호출
        my $retval = $sub->($fd, $buffer, $count, $offset, $flags);

        free($buffer);

        return $retval, @data;
    });
$FFI->attach(glfs_pwritev => ['glfs_fd_t', 'opaque', 'int', 'off_t', 'int'] => 'ssize_t'
    , sub {
        my ($sub, $fd, $vectors, $offset, $flags) = @_;

        my $vsize = $FFI->sizeof('Iovec');
        my $psize = $FFI->sizeof('opaque');
        my $count = scalar(@{$vectors});

        my $buffer = calloc($count, $vsize);
        my @len    = ();
        my @ptrs   = ();

        for (my $i=0; $i<$count; $i++)
        {
            $len[$i] = pack('L!', length($vectors->[$i]));

            my $p_base  = pack('P', $vectors->[$i]);
            my $p_len   = pack('P', $len[$i]);
            my $pp_base = pack('P', $p_base);

            push(@ptrs, $p_base, $p_len, $pp_base);

            memcpy($buffer + ($vsize * $i), unpack('L!', $pp_base), $psize);
            memcpy($buffer + ($vsize * $i) + $psize, unpack('L!', $p_len), length($len[$i]));
        }

        my $retval = $sub->($fd, $buffer, $count, $offset, $flags);

        free($buffer);

        return $retval;
    });
$FFI->attach(glfs_preadv_async => ['glfs_fd_t', 'Iovec', 'int', 'int', 'int', 'off_t', 'glfs_io_cbk', 'opaque'] => 'ssize_t');
$FFI->attach(glfs_pwritev_async => ['glfs_fd_t', 'Iovec', 'int', 'int', 'int', 'off_t', 'glfs_io_cbk', 'opaque'] => 'ssize_t');
$FFI->attach(glfs_lseek => ['glfs_fd_t', 'off_t', 'int'] => 'int');
$FFI->attach(glfs_truncate => ['glfs_t', 'string', 'off_t'] => 'int');
$FFI->attach(glfs_ftruncate => ['glfs_fd_t', 'off_t'] => 'int');
$FFI->attach(glfs_ftruncate_async => ['glfs_fd_t', 'off_t', 'glfs_io_cbk', 'opaque'] => 'int');
$FFI->attach(glfs_lstat => ['glfs_t', 'string', 'Stat'] => 'int');
$FFI->attach(glfs_stat  => ['glfs_t', 'string', 'Stat'] => 'int');
$FFI->attach(glfs_fstat => ['glfs_fd_t', 'Stat'] => 'int');
$FFI->attach(glfs_fsync => ['glfs_fd_t'] => 'int');
$FFI->attach(glfs_fsync_async => ['glfs_fd_t', 'glfs_io_cbk', 'opaque'] => 'int');
$FFI->attach(glfs_fdatasync => ['glfs_fd_t'] => 'int');
$FFI->attach(glfs_fdatasync_async => ['glfs_fd_t', 'glfs_io_cbk', 'opaque'] => 'int');
$FFI->attach(glfs_access => ['glfs_t', 'string', 'int'] => 'int');
$FFI->attach(glfs_symlink => ['glfs_t', 'string', 'string'] => 'int');
$FFI->attach(glfs_readlink => ['glfs_t', 'string', 'string', 'size_t'] => 'int');
$FFI->attach(glfs_mknod => ['glfs_t', 'string', 'mode_t', 'dev_t'] => 'int');
$FFI->attach(glfs_mkdir => ['glfs_t', 'string', 'mode_t'] => 'int');
$FFI->attach(glfs_unlink => ['glfs_t', 'string'] => 'int');
$FFI->attach(glfs_rmdir => ['glfs_t', 'string'] => 'int');
$FFI->attach(glfs_rename => ['glfs_t', 'string', 'string'] => 'int');
$FFI->attach(glfs_link => ['glfs_t', 'string', 'string'] => 'int');
$FFI->attach(glfs_opendir => ['glfs_t', 'string'] => 'glfs_fd_t');
$FFI->attach(glfs_readdir_r => ['glfs_fd_t', 'Dirent', 'opaque*'] => 'int');
$FFI->attach(glfs_readdirplus_r => ['glfs_fd_t', 'Stat', 'Dirent', 'opaque*'] => 'int');
$FFI->attach(glfs_readdir => ['glfs_fd_t'] => 'Dirent');
$FFI->attach(glfs_readdirplus => ['glfs_fd_t', 'Stat'] => 'Dirent');
$FFI->attach(glfs_telldir => ['glfs_fd_t'] => 'long');
$FFI->attach(glfs_seekdir => ['glfs_fd_t', 'long'] => 'long');
$FFI->attach(glfs_closedir => ['glfs_fd_t'] => 'int');
$FFI->attach(glfs_statvfs => ['glfs_t', 'string', 'Statvfs'], => 'int');
$FFI->attach(glfs_chmod => ['glfs_t', 'string', 'mode_t'] => 'int');
$FFI->attach(glfs_fchmod => ['glfs_fd_t', 'mode_t'] => 'int');
$FFI->attach(glfs_chown => ['glfs_t', 'string', 'uid_t', 'gid_t'] => 'int');
$FFI->attach(glfs_lchown => ['glfs_t', 'string', 'uid_t', 'gid_t'] => 'int');
$FFI->attach(glfs_fchown => ['glfs_fd_t', 'uid_t', 'gid_t'] => 'int');
$FFI->attach(glfs_utimens => ['glfs_t', 'string', 'Timespecs'] => 'int');
$FFI->attach(glfs_lutimens => ['glfs_t', 'string', 'Timespecs'] => 'int');
$FFI->attach(glfs_futimens => ['glfs_fd_t', 'Timespecs'] => 'int');
$FFI->attach(glfs_getxattr => ['glfs_t', 'string', 'string', 'opaque', 'size_t'] => 'ssize_t');
$FFI->attach(glfs_lgetxattr => ['glfs_t', 'string', 'string', 'opaque', 'size_t'] => 'ssize_t');
$FFI->attach(glfs_fgetxattr => ['glfs_fd_t', 'string', 'opaque', 'size_t'] => 'ssize_t');
$FFI->attach(glfs_listxattr => ['glfs_t', 'string', 'opaque', 'size_t'] => 'ssize_t');
$FFI->attach(glfs_llistxattr => ['glfs_t', 'string', 'opaque', 'size_t'] => 'ssize_t');
$FFI->attach(glfs_flistxattr => ['glfs_fd_t', 'opaque', 'size_t'] => 'ssize_t');
$FFI->attach(glfs_setxattr => ['glfs_t', 'string', 'string', 'opaque', 'size_t', 'int'] => 'int');
$FFI->attach(glfs_lsetxattr => ['glfs_t', 'string', 'string', 'opaque', 'size_t', 'int'] => 'int');
$FFI->attach(glfs_fsetxattr => ['glfs_fd_t', 'string', 'opaque', 'size_t', 'int'] => 'int');
$FFI->attach(glfs_removexattr => ['glfs_t', 'string', 'string'] => 'int');
$FFI->attach(glfs_lremovexattr => ['glfs_t', 'string', 'string'] => 'int');
$FFI->attach(glfs_fremovexattr => ['glfs_fd_t', 'string'] => 'int');
$FFI->attach(glfs_fallocate => ['glfs_fd_t', 'int', 'off_t', 'size_t'] => 'int');
$FFI->attach(glfs_discard => ['glfs_fd_t', 'off_t', 'size_t'] => 'int');
$FFI->attach(glfs_discard_async => ['glfs_fd_t', 'off_t', 'size_t', 'glfs_io_cbk', 'opaque'] => 'int');
$FFI->attach(glfs_zerofill => ['glfs_fd_t', 'off_t', 'size_t'] => 'int');
$FFI->attach(glfs_zerofill_async => ['glfs_fd_t', 'off_t', 'off_t', 'glfs_io_cbk', 'opaque'] => 'int');
$FFI->attach(glfs_getcwd => ['glfs_t', 'string', 'size_t'] => 'string');
$FFI->attach(glfs_chdir => ['glfs_t', 'string'] => 'int');
$FFI->attach(glfs_fchdir => ['glfs_fd_t'] => 'int');
$FFI->attach(glfs_realpath => ['glfs_t', 'string', 'string'] => 'string');
$FFI->attach(glfs_posix_lock => ['glfs_fd_t', 'int', 'Flock'] => 'int');
$FFI->attach(glfs_dup => ['glfs_fd_t'] => 'glfs_fd_t');

sub new
{
    my $class = shift;
    my %attrs = ();

    bless(\%attrs, __PACKAGE__);
}

1;

__END__

=encoding utf8

=head1 NAME

GlusterFS::GFAPI::FFI - FFI Perl binding for GlusterFS libgfapi

=head1 VERSION

0.4

=head1 SYNOPSIS

    # make GlusterFS Volume instance
    my $fs = GlusterFS::GFAPI::FFI::glfs_new('libgfapi-perl');

    # set server information for a volume
    if (GlusterFS::GFAPI::FFI::glfs_set_volfile_server($fs, 'tcp', 'node1', 24007))
    {
        die "Failed to set volfile server: $!";
    }

    # initialize connection for a GlusterFS Volume
    if (GlusterFS::GFAPI::FFI::glfs_init($fs))
    {
        die "Failed to init connection: $!";
    }

    # get a Volume-ID
    my $len = 16;
    my $id  = "\0" x $len;

    if (GlusterFS::GFAPI::FFI::glfs_get_volumeid($fs, $id, $len) < 0)
    {
        die "Failed to get volume-id: $!";
    }

    printf "Volume-ID: %s\n", join('-', unpack('H8 H4 H4 H4 H12', $id));

    # get stat for a volume
    my $stat = GlusterFS::GFAPI::FFI::Statvfs->new();

    if (GlusterFS::GFAPI::FFI::glfs_statvfs($fs, '/', $stat))
    {
        die "Failed to get statvfs: $!";
    }

    printf "- f_bsize   : %d\n",   $stat->f_bsize;
    printf "- f_frsize  : %d\n",   $stat->f_frsize;
    printf "- f_blocks  : %d\n",   $stat->f_blocks;
    printf "- f bfree   : %d\n",   $stat->f_bfree;
    printf "- f_bavail  : %d\n",   $stat->f_bavail;
    printf "- f_files   : %d\n",   $stat->f_files;
    printf "- f_ffree   : %d\n",   $stat->f_ffree;
    printf "- f_favail  : %d\n",   $stat->f_favail;
    printf "- f_fsid    : %d\n",   $stat->f_fsid;
    printf "- f_flag    : 0x%o\n", $stat->f_flag;
    printf "- f_namemax : %d\n",   $stat->f_namemax;

    # create a file and take file-descriptor
    my $fd = GlusterFS::GFAPI::FFI::glfs_creat($fs, "/potato", O_RDWR, 0644);

    # get stat for a file
    $stat = GlusterFS::GFAPI::FFI::Stat->new();

    if (GlusterFS::GFAPI::FFI::glfs_stat($fs, "/potato", $stat))
    {
        die "Failed to stat: $!";
    }

    printf "- ino     : %d\n",   $stat->st_ino;
    printf "- mode    : 0x%o\n", $stat->st_mode;
    printf "- size    : %d\n",   $stat->st_size;
    printf "- blksize : %d\n",   $stat->st_blksize;
    printf "- uid     : %d\n",   $stat->st_uid;
    printf "- gid     : %d\n",   $stat->st_gid;
    printf "- atime   : %d\n",   $stat->st_atime;
    printf "- mtime   : %d\n",   $stat->st_mtime;
    printf "- ctime   : %d\n",   $stat->st_ctime;

    # write data to a file
    my $buffer = 'this is a lipsum';

    if (GlusterFS::GFAPI::FFI::glfs_write($fd, $buffer, length($buffer), 0) == -1)
    {
        die "Failed to write: $!";
    }

    # seek a file offset
    if (GlusterFS::GFAPI::FFI::glfs_lseek($fd, 0, 0))
    {
        die "Failed to seek: $!";
    }

    # read data from a file
    $buffer = "\0" x 256;

    if (GlusterFS::GFAPI::FFI::glfs_read($fd, $buffer, 256, 0) == -1)
    {
        die "Failed to read: $!";
    }

    printf "read: %s\n", $buffer;

    # close a file
    if (GlusterFS::GFAPI::FFI::glfs_close($fd))
    {
        die "Failed to close: $!";
    }

    # destroy a connection
    if (GlusterFS::GFAPI::FFI::glfs_fini($fs))
    {
        die "Failed to terminate: $!"
    }

=head1 DESCRIPTION

=head1 FUNCTIONS

=head2 C<glfs_init($fs)>

    $retval = glfs_init($fs);

=head2 C<glfs_new($volname)>

    $fs = glfs_new($volname);

=head2 C<glfs_set_volfile_server($fs, $proto, $node, $port)>

    $retval = glfs_set_volfile_server($fs, $proto, $node, $port);

=head2 C<glfs_set_logging($fs, $path, $level)>

    $retval = glfs_set_logging($fs, $path, $level);

=head2 C<glfs_fini($fs)>

    $retval = glfs_fini($fs);

=head2 C<glfs_get_volumeid($fs, $buf, $bufsz)>

    $volid = glfs_get_volumeid($fs, $buf, $bufsz);

=head2 C<glfs_setfsuid($uid)>

    $retval = glfs_setfsuid($uid);

=head2 C<glfs_setfsgid($uid)>

    $retval = glfs_setfsgid($uid);

=head2 C<glfs_setfsgroups($uid, $gids)>

    $retval = glfs_setfsgroups($uid, $gids);

=head2 C<glfs_open($fs, $path, $flags)>

    $fd = glfs_open($fs, $path, $flags);

=head2 C<glfs_creat($fs, $path, $flags, $mode)>

    $fd = glfs_creat($fs, $path, $flags, $mode);

=head2 C<glfs_close($fd)>

    $retval = glfs_close($fd);

=head2 C<glfs_from_glfd($fd)>

    $fs = glfs_from_glfd($fd);

=head2 C<glfs_set_xlator_option($fs, $xlator, $key, $value)>

    $retval = glfs_set_xlator_option($fs, $xlator, $key, $value);

=head2 C<glfs_read($fd, $buf, $count, $flags)>

    $retval = glfs_read($fd, $buf, $count, $flags);

=head2 C<glfs_write($fd, $buf, $count, $flags)>

    $retval = glfs_write($fd, $buf, $count, $flags);

=head2 C<glfs_readv($fd, [$buf1, ...], $flags)>

    ($retval, @data) = glfs_readv($fd, [$buf1, ...], $flags);

=head2 C<glfs_writev($fd, [$buf1, ...], $flags)>

    $retval = glfs_writev($fd, [$buf1, ...], $flags);

=head2 C<glfs_pread($fd, $buf, $count, $offset, $flags)>

    $retval = glfs_pread($fd, $buf, $count, $offset, $flags);

=head2 C<glfs_pwrite($fd, $buf, $count, $offset, $flags)>

    $retval = glfs_pwrite($fd, $buf, $count, $offset, $flags);

=head2 C<glfs_preadv($fd, [$buf1, ...], $offset, $flags)>

    ($retval, @data) = glfs_preadv($fd, [$buf1, ...], $offset, $flags);

=head2 C<glfs_pwritev($fd, [$buf1, ...], $offset, $flags)>

    $retval = glfs_pwritev($fd, [$buf1, ...], $offset, $flags);

=head2 C<glfs_lseek($fd, $offset, $whence)>

    $retval = glfs_lseek($fd, $offset, $whence);

=head2 C<glfs_truncate($fs, $path, $length)>

    $retval = glfs_truncate($fs, $path, $length);

=head2 C<glfs_ftruncate($fd, $length)>

    $retval = glfs_ftruncate($fd, $length);

=head2 C<glfs_lstat($fs, $path, $stat)>

    $retval = glfs_lstat($fs, $path, $stat);

=head2 C<glfs_stat($fs, $path, $stat)>

    $retval = glfs_stat($fs, $path, $stat);

=head2 C<glfs_fstat($fd, $stat)>

    $retval = glfs_fstat($fd, $stat);

=head2 C<glfs_fsync($fd)>

    $retval = glfs_fsync($fd);

=head2 C<glfs_fdatasync($fd)>

    $retval = glfs_fdatasync($fd);

=head2 C<glfs_access($fs, $path, $mode)>

    $retval = glfs_access($fs, $path, $mode);

=head2 C<glfs_symlink($fs, $oldpath, $newpath)>

    $retval = glfs_symlink($fs, $oldpath, $newpath);

=head2 C<glfs_readlink($fs, $path, $buf, $bufsz)>

    $retval = glfs_readlink($fs, $path, $buf, $bufsz);

=head2 C<glfs_mknod($fs, $path, $mode, $dev)>

    $retval = glfs_mknod($fs, $path, $mode, $dev);

=head2 C<glfs_mkdir($fs, $path, $mode)>

    $retval = glfs_mkdir($fs, $path, $mode);

=head2 C<glfs_unlink($fs, $path)>

    $retval = glfs_unlink($fs, $path);

=head2 C<glfs_rmdir($fs, $path)>

    $retval = glfs_rmdir($fs, $path);

=head2 C<glfs_rename($fs, $oldpath, $newpath)>

    $retval = glfs_rename($fs, $oldpath, $newpath);

=head2 C<glfs_link($fs, $oldpath, $newpath)>

    $retval = glfs_link($fs, $oldpath, $newpath);

=head2 C<glfs_opendir($fs, $path)>

    $retval = glfs_opendir($fs, $path);

=head2 C<glfs_readdir_r($fd, $dirent, \$result)>

    $retval = glfs_readdir_r($fd, $dirent, \$result);

=head2 C<glfs_readdirplus_r($fd, $stat, $dirent, \$result)>

    $retval = glfs_readdirplus_r($fd, $stat, $dirent, \$result);

=head2 C<glfs_readdir($fd)>

    $dirent = glfs_readdir($fd);

=head2 C<glfs_readdirplus($fd, $stat)>

    $dirent = glfs_readdirplus($fd, $stat);

=head2 C<glfs_telldir($fd)>

    $retval = glfs_telldir($fd);

=head2 C<glfs_seekdir($fd, $offset)>

    $retval = glfs_seekdir($fd, $offset);

=head2 C<glfs_closedir($fd)>

    $retval = glfs_closedir($fd);

=head2 C<glfs_statvfs($fs, $path, $statvfs)>

    $retval = glfs_statvfs($fs, $path, $statvfs);

=head2 C<glfs_chmod($fs, $path, $mode)>

    $retval = glfs_chmod($fs, $path, $mode);

=head2 C<glfs_fchmod($fd, $mode)>

    $retval = glfs_fchmod($fd, $mode);

=head2 C<glfs_chown($fs, $path, $uid, $gid)>

    $retval = glfs_chown($fs, $path, $uid, $gid);

=head2 C<glfs_lchown($fs, $path, $uid, $gid)>

    $retval = glfs_lchown($fs, $path, $uid, $gid);

=head2 C<glfs_fchown($fd, $uid, $gid)>

    $retval = glfs_fchown($fd, $uid, $gid);

=head2 C<glfs_utimens($fs, $path, $timespecs)>

    $retval = glfs_utimens($fs, $path, $timespecs);

=head2 C<glfs_ltimens($fs, $path, $timespecs)>

    $retval = glfs_ltimens($fs, $path, $timespecs);

=head2 C<glfs_ftimens($fd, $timespecs)>

    $retval = glfs_ftimens($fd, $timespecs);

=head2 C<glfs_getxattr($fs, $path, $key, $value, $valsz)>

    $retval = glfs_getxattr($fs, $path, $key, $value, $valsz);

=head2 C<glfs_lgetxattr($fs, $path, $key, $value, $valsz)>

    $retval = glfs_lgetxattr($fs, $path, $key, $value, $valsz);

=head2 C<glfs_lgetxattr($fd, $key, $value, $valsz)>

    $retval = glfs_lgetxattr($fd, $key, $value, $valsz);

=head2 C<glfs_listxattr($fs, $path, $value, $valsz)>

    $retval = glfs_listxattr($fs, $path, $value, $valsz);

=head2 C<glfs_llistxattr($fs, $path, $value, $valsz)>

    $retval = glfs_llistxattr($fs, $path, $value, $valsz);

=head2 C<glfs_flistxattr($fd, $value, $valsz)>

    $retval = glfs_flistxattr($fd, $value, $valsz);

=head2 C<glfs_setxattr($fs, $path, $key, $value, $valsz, $flags)>

    $retval = glfs_setxattr($fs, $path, $key, $value, $valsz, $flags);

=head2 C<glfs_lsetxattr($fs, $path, $key, $value, $valsz, $flags)>

    $retval = glfs_lsetxattr($fs, $path, $key, $value, $valsz, $flags);

=head2 C<glfs_fsetxattr($fd, $key, $value, $valsz, $flags)>

    $retval = glfs_fsetxattr($fd, $key, $value, $valsz, $flags);

=head2 C<glfs_removexttr($fd, $path, $key)>

    $retval = glfs_removexttr($fd, $path, $key);

=head2 C<glfs_lremovexttr($fd, $path, $key)>

    $retval = glfs_lremovexttr($fd, $path, $key);

=head2 C<glfs_fremovexttr($fs, $key)>

    $retval = glfs_fremovexttr($fs, $key);

=head2 C<glfs_fallocate($fd, $keepsz, $offset, $len)>

    $retval = glfs_fallocate($fd, $keepsz, $offset, $len);

=head2 C<glfs_discard($fd, $offset, $len)>

    $retval = glfs_discard($fd, $offset, $len);

=head2 C<glfs_zerofill($fd, $offset, $len)>

    $retval = glfs_zerofill($fd, $offset, $len);

=head2 C<glfs_getcwd($fs, $buf, $bufsz)>

    $retval = glfs_getcwd($fs, $buf, $bufsz);

=head2 C<glfs_chdir($fs, $path)>

    $retval = glfs_chdir($fs, $path);

=head2 C<glfs_fchdir($fd)>

    $retval = glfs_fchdir($fd);

=head2 C<glfs_realpath($fs, $path, $resolved)>

    $retval = glfs_realpath($fs, $path, $resolved);

=head2 C<glfs_posix_lock($fd, $cmd, $flock)>

    $retval = glfs_posix_lock($fd, $cmd, $flock);

=head2 C<glfs_dup($fd)>

    $fd = glfs_dup($fd);

=head2 C<glfs_read_async($fd, $buf, $bufsz, $flags, $cbk, $data)>

B<This function is not supported yet!>

    $retval = glfs_read_async($fd, $buf, $bufsz, $flags, $cbk, $data);

=head2 C<glfs_write_async($fd, $buf, $bufsz, $flags, $cbk, $data)>

B<This function is not supported yet!>

    $retval = glfs_write_async($fd, $buf, $bufsz, $flags, $cbk, $data);

=head2 C<glfs_readv_async($fd, [$buf1, ...], $flags, $cbk, $data)>

B<This function is not supported yet!>

    $retval = glfs_readv_async($fd, [$buf1, ...], $flags, $cbk, $data);

=head2 C<glfs_writev_async($fd, [$buf1, ...], $flags, $cbk, $data)>

B<This function is not supported yet!>

    $retval = glfs_writev_async($fd, [$buf1, ...], $flags, $cbk, $data);

=head2 C<glfs_pread_async($fd, $buf, $bufsz, $offset, flags, $cbk, $data)>

B<This function is not supported yet!>

    $retval = glfs_pread_async($fd, $buf, $bufsz, $offset, flags, $cbk, $data);

=head2 C<glfs_pwrite_async($fd, $buf, $bufsz, $offset, flags, $cbk, $data)>

B<This function is not supported yet!>

    $retval = glfs_pwrite_async($fd, $buf, $bufsz, $offset, flags, $cbk, $data);

=head2 C<glfs_preadv_async($fd, [$buf1, ...], $offset, $flags, $cbk, $data)>

B<This function is not supported yet!>

    $retval = glfs_preadv_async($fd, [$buf1, ...], $offset, $flags, $cbk, $data);

=head2 C<glfs_pwritev_async($fd, [$buf1, ...], $offset, $flags, $cbk, $data)>

B<This function is not supported yet!>

    $retval = glfs_pwritev_async($fd, [$buf1, ...], $offset, $flags, $cbk, $data);

=head2 C<glfs_ftruncate_async($fd, $length, $cbk, $data)>

B<This function is not supported yet!>

    $retval = glfs_ftruncate_async($fd, $length, $cbk, $data);

=head2 C<glfs_fsync_async($fd, $cbk, $data)>

B<This function is not supported yet!>

    $retval = glfs_fsync_async($fd, $cbk, $data);

=head2 C<glfs_fdatasync_async($fd, $cbk, $data)>

B<This function is not supported yet!>

    $retval = glfs_fdatasync_async($fd, $cbk, $data);

=head2 C<glfs_discard_async($fd, $offset, $len, $cbk, $data)>

B<This function is not supported yet!>

    $retval = glfs_discard_async($fd, $offset, $len, $cbk, $data);

=head2 C<glfs_zerofill_async($fd, $offset, $len, $cbk, $data)>

B<This function is not supported yet!>

    $retval = glfs_zerofill_async($fd, $offset, $len, $cbk, $data);

=head1 BUGS

=head1 SEE ALSO

=over

=item L<https://www.gluster.org>

=item L<https://github.com/gluster/libgfapi-perl>

=item L<overload>

=item L<Fcntl>

=item L<POSIX>

=item L<Carp>

=item L<Tiny::Try>

=item L<File::Spec>

=item L<List::MoreUtils>

=item L<Moo>

=item L<Generator::Object>

=item L<FFI::Platypus>

=item L<FFI::CheckLib>

=back

=head1 AUTHOR

Ji-Hyeon Gim E<lt>potatogim@gluesys.comE<gt>

=head2 CONTRIBUTORS

=over

=item Tae-Hwa Lee E<lt>alghost@gmail.comE<gt>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright 2017-2018 by Ji-Hyeon Gim.

This is free software; you can redistribute it and/or modify it under the same terms as the GPLv2/LGPLv3.

=cut

