package GlusterFS::GFAPI::FFI::Volume;

BEGIN
{
    our $AUTHOR  = 'cpan:potatogim';
    our $VERSION = '0.4';
}

use strict;
use warnings;
use utf8;

use Moo;
use Fcntl                       qw/:mode/;
use File::Spec;
use File::Basename;
use POSIX                       qw/modf :fcntl_h/;
use Errno                       qw/EEXIST/;
use Scalar::Util::Numeric       qw/isint/;
use List::MoreUtils             qw/natatime/;
use Generator::Object;
use Try::Tiny;
use Carp;

use GlusterFS::GFAPI::FFI;
use GlusterFS::GFAPI::FFI::Util qw/libgfapi_soname/;
use GlusterFS::GFAPI::FFI::Dir;
use GlusterFS::GFAPI::FFI::DirEntry;

use constant
{
    PATH_MAX => 4096,
};


#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has 'mounted' =>
(
    is => 'rwp',
);

has 'fs' =>
(
    is => 'rwp',
);

has 'host' =>
(
    is => 'rwp',
);

has 'volname' =>
(
    is => 'rwp',
);

has 'protocol' =>
(
    is => 'rwp',
);

has 'port' =>
(
    is => 'rwp',
);

has 'log_file' =>
(
    is => 'rwp',
);

has 'log_level' =>
(
    is => 'rwp',
);


#---------------------------------------------------------------------------
#   Contructor/Destructor
#---------------------------------------------------------------------------
sub BUILD
{
    my $self = shift;
    my $args = shift;

    if (!defined($args->{volname}) || !defined($args->{host}))
    {
        confess('Host and Volume name should not be undefined');
    }

    if (defined($args->{proto}) && $args->{proto} !~ m/^(tcp|rdma)$/)
    {
        confess('Invalid protocol specified');
    }

    if (defined($args->{port}) && $args->{port} !~ m/^\d+$/)
    {
        confess('Invalid port specified');
    }

    $args->{proto}     = 'tcp' if (!defined($args->{proto}));
    $args->{port}      = 24007 if (!defined($args->{port}));
    $args->{log_level} = 7     if (!defined($args->{log_level}));

    $self->_set_mounted(0);
    $self->_set_fs(undef);
    $self->_set_log_file($args->{log_file});
    $self->_set_log_level($args->{log_level});
    $self->_set_host($args->{host});
    $self->_set_volname($args->{volname});
    $self->_set_protocol($args->{proto});
    $self->_set_port($args->{port});
}

sub DEMOLISH
{
    my ($self, $is_global) = @_;

    $self->umount();
}


#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub mount
{
    my $self = shift;
    my %args = @_;

    if ($self->fs && $self->mounted)
    {
        # Already mounted
        return 0;
    }

    $self->{fs} = GlusterFS::GFAPI::FFI::glfs_new($self->volname);

    if (!defined($self->fs))
    {
        confess("glfs_new(${\$self->volname}) failed: $!");
    }

    my $retval = GlusterFS::GFAPI::FFI::glfs_set_volfile_server(
                $self->fs,
                $self->protocol,
                $self->host,
                $self->port);

    if ($retval < 0)
    {
        confess(sprintf('glfs_set_volfile_server(%s, %s, %s, %s) failed: %s'
                , $self->fs // 'undef'
                , $self->protocol // 'undef'
                , $self->host // 'undef'
                , $self->port // 'undef'
                , $!));
    }

    $self->set_logging(log_file => $self->log_file, log_level => $self->log_level);

    if ($self->fs && !$self->mounted)
    {
        $retval = GlusterFS::GFAPI::FFI::glfs_init($self->fs);

        if ($retval < 0)
        {
            confess("glfs_init(${\$self->fs}) failed: $!");
        }
        else
        {
            $self->_set_mounted(1);
        }
    }

    return $retval;
}

sub umount
{
    my $self = shift;
    my %args = @_;

    if ($self->fs)
    {
        if (GlusterFS::GFAPI::FFI::glfs_fini($self->fs) < 0)
        {
            confess("glfs_fini(${\$self->fs}) failed: $!");
        }
        else
        {
            $self->_set_mounted(0);
            $self->_set_fs(undef);
        }
    }

    return 0;
}

sub set_logging
{
    my $self = shift;
    my %args = @_;

    my $retval;

    if ($self->fs)
    {
        $retval = GlusterFS::GFAPI::FFI::glfs_set_logging(
                    $self->fs,
                    $self->log_file,
                    $self->log_level);

        if ($retval < 0)
        {
            confess(
                sprintf("glfs_set_logging(%s, %s) failed: %s"
                    , $self->log_file  // 'undef'
                    , $self->log_level // 'undef'
                    , $!));
        }

        $self->_set_log_file($args{log_file});
        $self->_set_log_level($args{log_level});
    }

    return $retval;
}

sub access
{
    my $self = shift;
    my %args = @_;

    my $retval = GlusterFS::GFAPI::FFI::glfs_success(
                    $self->fs,
                    $args{path},
                    $args{mode});

    return $retval ? 0 : 1;
}

sub chdir
{
    my $self = shift;
    my %args = @_;

    my $retval = GlusterFS::GFAPI::FFI::glfs_chdir($self->fs, $args{path});

    if ($retval < 0)
    {
        confess('glfs_chdir(%s, %s) failed: %s'
            , $self->fs, $args{path}, $!);
    }

    return $retval;
}

sub chmod
{
    my $self = shift;
    my %args = @_;

    my $retval = GlusterFS::GFAPI::FFI::glfs_chmod(
                    $self->fs,
                    $args{path},
                    $args{mode});

    if ($retval < 0)
    {
        confess(
            sprintf('glfs_chmod(%s, %s, %s) failed: %s'
                , $self->fs // 'undef'
                , $args{path} // 'undef'
                , $args{mode} ? sprintf('0%o', $args{mode}) : 'undef'
                , $!));
    }

    return $retval;
}

sub chown
{
    my $self = shift;
    my %args = @_;

    my $retval = GlusterFS::GFAPI::FFI::glfs_chown(
                    $self->fs,
                    $args{path},
                    $args{uid},
                    $args{gid});

    if ($retval < 0)
    {
        confess(
            sprintf('glfs_chown(%s, %s, %s, %s) failed: %s'
                , $self->fs // 'undef'
                , $args{path} // 'undef'
                , $args{uid} // 'undef'
                , $args{gid} // 'undef'
                , $!));
    }

    return $retval;
}

sub exists
{
    my $self = shift;
    my %args = @_;

    return try
    {
        $self->stat(path => $args{path}) ? 1 : 0;
    }
    catch
    {
        return 0;
    };
}

sub getatime
{
    my $self = shift;
    my %args = @_;

    return $self->stat(path => $args{path})->st_atime;
}

sub getctime
{
    my $self = shift;
    my %args = @_;

    return $self->stat(path => $args{path})->st_atime;
}

sub getcwd
{
    my $self = shift;
    my %args = @_;

    my $buf    = "\0" x PATH_MAX;
    my $ptr    = pack('P', $buf);
    my $retval = GlusterFS::GFAPI::FFI::glfs_getcwd(
                    $self->fs,
                    unpack('L!', $ptr),
                    PATH_MAX);

    if ($retval < 0)
    {
        confess(sprintf('glfs_getcwd(%s, %s, %d) failed: %s'
                        , $self->fs, 'buf', PATH_MAX, $!));
    }

    return $buf;
}

sub getmtime
{
    my $self = shift;
    my %args = @_;

    return $self->stat(path => $args{path})->st_mtime;
}

sub getsize
{
    my $self = shift;
    my %args = @_;

    return $self->stat(path => $args{path})->st_size;
}

sub getxattr
{
    my $self = shift;
    my %args = @_;

    if ($args{size} == 0)
    {
        $args{size} = GlusterFS::GFAPI::FFI::glfs_getxattr(
                        $self->fs,
                        $args{path},
                        $args{key},
                        undef,
                        0);

        if ($args{size} < 0)
        {
            confess(
                sprintf('glfs_getxattr(%s, %s, %s, %s, %d) failed: %s'
                    , $self->fs // 'undef'
                    , $args{path} // 'undef'
                    , $args{key} // 'undef'
                    , 'undef'
                    , 0
                    , $!));
        }
    }

    my $buf    = "\0" x $args{size};
    my $ptr    = pack('P', $buf);
    my $retval = GlusterFS::GFAPI::FFI::glfs_getxattr(
                $self->fs,
                $args{path},
                $args{key},
                unpack('L!', $ptr),
                $args{size});

    if ($retval < 0)
    {
        confess(
            sprintf('glfs_getxattr(%s, %s, %s, %s, %d) failed: %s'
                , $self->fs // 'undef'
                , $args{path} // 'undef'
                , $args{key} // 'undef'
                , 'buf'
                , $args{size} // 'undef'
                , $!));
    }

    return substr($buf, 0, $retval);
}

sub isdir
{
    my $self = shift;
    my %args = @_;

    my $s;

    try
    {
        $s = $self->stat(path => $args{path});
    }
    catch
    {
        $s = undef;
    };

    return $s ? S_ISDIR($s->st_mode) : 0;
}

sub isfile
{
    my $self = shift;
    my %args = @_;

    my $s;

    try
    {
        $s = $self->stat(path => $args{path});
    }
    catch
    {
        $s = undef;
    };

    return $s ? S_ISREG($s->st_mode) : 0;
}

sub islink
{
    my $self = shift;
    my %args = @_;

    my $s = try
    {
        $self->lstat(path => $args{path});
    }
    catch
    {
        undef;
    };

    return $s ? S_ISLNK($s->st_mode) : 0;
}

sub listdir
{
    my $self = shift;
    my %args = @_;

    my @dirs;

    my $dir = $self->opendir(path => $args{path});

    while (my $entry = $dir->next())
    {
        if (ref($entry) ne 'GlusterFS::GFAPI::FFI::Dirent')
        {
            last;
        }

        my $name = substr($entry->d_name, 0, $entry->d_reclen);

        if ($name ne '.' && $name ne '..')
        {
            push(@dirs, $name);
        }
    }

    return @dirs;
}

sub listdir_with_stat
{
    my $self = shift;
    my %args = @_;

    my @entries_with_stat;

    my $dir = $self->opendir(path => $args{path}, readdirplus => 1);

    while (my ($entry, $stat) = $dir->next())
    {
        if (ref($entry) ne 'GlusterFS::GFAPI::FFI::Dirent'
            || ref($stat) ne 'GlusterFS::GFAPI::FFI::Stat')
        {
            last;
        }

        my $name = substr($entry->d_name, 0, $entry->d_reclen);

        if ($name ne '.' && $name ne '..')
        {
            push(@entries_with_stat, [$name, $stat]);
        }
    }

    return @entries_with_stat;
}

sub scandir
{
    my $self = shift;
    my %args = @_;

    return generator {
        my $path = $args{path};
        my $dir  = $self->opendir(path => $path, readdirplus => 1);

        while (my ($entry, $lstat) = $dir->next())
        {
            if (!defined($entry))
            {
                undef($dir);
                $_->yield(undef);
            }

            my $name = substr($entry->d_name, 0, $entry->d_reclen);

            if ($name ne '.' && $name ne '..')
            {
                $_->yield(GlusterFS::GFAPI::FFI::DirEntry->new(
                            vol   => $self,
                            path  => $path,
                            name  => $name,
                            lstat => $lstat));
            }
        }
    };
}

sub listxattr
{
    my $self = shift;
    my %args = @_;

    if (!defined($args{size}) || $args{size} == 0)
    {
        $args{size} = GlusterFS::GFAPI::FFI::glfs_listxattr(
                        $self->fs,
                        $args{path},
                        undef,
                        0);

        if ($args{size} < 0)
        {
            confess(
                sprintf('glfs_listxattr(%s, %s, %s, %d) failed: %s'
                    , $self->fs // 'undef'
                    , $args{path} // 'undef'
                    , 'undef'
                    , 0
                    , $!));
        }
    }

    my $buf    = "\0" x $args{size};
    my $ptr    = pack('P', $buf);
    my $retval = GlusterFS::GFAPI::FFI::glfs_listxattr(
                    $self->fs,
                    $args{path},
                    unpack('L!', $ptr),
                    $args{size});

    if ($retval < 0)
    {
        confess(sprintf('glfs_listxattr(%s, %s, %s, %d) failed: %s'
                , $self->fs // 'undef'
                , $args{path} // 'undef'
                , 'buf'
                , $args{size}
                , $!));
    }

    return sort { $a cmp $b; } split("\0", $buf);
}

sub lstat
{
    my $self = shift;
    my %args = @_;

    my $stat   = GlusterFS::GFAPI::FFI::Stat->new();
    my $retval = GlusterFS::GFAPI::FFI::glfs_lstat($self->fs, $args{path}, $stat);

    if ($retval < 0)
    {
        confess(sprintf('glfs_lstat(%s, %s, %s) failed: %s'
                , $self->fs // 'undef'
                , $args{path} // 'undef'
                , $stat // 'undef'
                , $!));
    }

    return $stat;
}

sub makedirs
{
    my $self = shift;
    my %args = @_;

    $args{mode} //= 0777;

    my @path = split(/\//, $args{path});
    my $tail = @path > 1 ? pop(@path) : undef;
    my $head = join('/', @path);

    if (defined($head) && length($head)
        && defined($tail) && length($tail)
        && !$self->exists(path => $head))
    {
        try
        {
            $self->makedirs(path => $head, mode => $args{mode});
        };

        if ($! != EEXIST)
        {
            confess(sprintf('makedirs(%s, %s) failed: %s'
                    , $head // 'undef'
                    , defined($args{mode}) ? sprintf('0%o', $args{mode}) : 'undef'
                    , $!));
        }

        if (!defined($tail) && length($tail) eq File::Spec->curdir())
        {
            return 0;
        }
    }

    $self->mkdir(path => $args{path}, mode => $args{mode});

    return 0;
}

sub mkdir
{
    my $self = shift;
    my %args = @_;

    $args{mode} //= 0777;

    my $retval = GlusterFS::GFAPI::FFI::glfs_mkdir(
                    $self->fs,
                    $args{path},
                    $args{mode});

    if ($retval < 0)
    {
        confess(sprintf('glfs_mkdir(%s, %s, %s) failed: %s'
                , $self->fs // 'undef'
                , $args{path} // 'undef'
                , defined($args{mode}) ? sprintf('0%o', $args{mode}) : 'undef'
                , $!));
    }

    return 0;
}

sub fopen
{
    my $self = shift;
    my %args = @_;

    $args{mode} //= 'r';

    my $fd;

    if ((O_CREAT & $args{flags}) == O_CREAT)
    {
        $fd = GlusterFS::GFAPI::FFI::glfs_creat(
                $self->fs,
                $args{path},
                $args{flags},
                0666);

        if (!defined($fd))
        {
            confess(sprintf('glfs_creat(%s, %s, %o, 0666) failed: %s'
                    , $self->fs, $args{path}, $args{flags}, $!));
        }
    }
    else
    {
        $fd = GlusterFS::GFAPI::FFI::glfs_open($self->fs, $args{path}, $args{flags});

        if (!defined($fd))
        {
            confess(sprintf('glfs_open(%s, %s, %o) failed: %s'
                    , $self->fs, $args{path}, $args{flags}, $!));
        }
    }

    return GlusterFS::GFAPI::FFI::File->new($fd, path => $args{path}, mode => $args{mode});
}

sub open
{
    my $self = shift;
    my %args = @_;

    $args{mode} //= 0777;

    my $fd;

    if ((O_CREAT & $args{flags}) == O_CREAT)
    {
        $fd = GlusterFS::GFAPI::FFI::glfs_creat(
                $self->fs,
                $args{path},
                $args{flags},
                $args{mode});

        if (!defined($fd))
        {
            confess(sprintf('glfs_creat(%s, %s, %o, 0666) failed: %s'
                    , $self->fs // 'undef'
                    , $args{path} // 'undef'
                    , $args{flags} // 'undef'
                    , $!));
        }
    }
    else
    {
        $fd = GlusterFS::GFAPI::FFI::glfs_open(
                $self->fs,
                $args{path},
                $args{flags});
    }

    if (!defined($fd))
    {
        confess(sprintf('glfs_open(%s, %s, %o) failed: %s'
                , $self->fs // 'undef'
                , $args{path} // 'undef'
                , $args{flags} // 'undef'
                , $!));
    }

    return $fd;
}

sub opendir
{
    my $self = shift;
    my %args = @_;

    $args{readdirplus} //= 0;

    my $fd = GlusterFS::GFAPI::FFI::glfs_opendir($self->fs, $args{path});

    if (!defined($fd))
    {
        confess(sprintf('glfs_opendir(%s, %s) failed: %s'
                , $self->fs // 'undef'
                , $args{path} // 'undef'
                , $!));
    }

    return GlusterFS::GFAPI::FFI::Dir->new(fd => $fd, readdirplus => $args{readdirplus});
}

sub readlink
{
    my $self = shift;
    my %args = @_;

    my $buf    = "\0" x PATH_MAX;
    my $ptr    = pack('P', $buf);
    my $retval = GlusterFS::GFAPI::FFI::glfs_readlink(
                    $self->fs,
                    $args{path},
                    unpack('L!', $ptr),
                    PATH_MAX);

    if ($retval < 0)
    {
        confess(sprintf('glfs_readlink(%s, %s, %s, %d) failed: %s'
                , $self->fs, $args{path}, 'buf', PATH_MAX, $!));
    }

    return substr($buf, 0, $retval);
}

sub remove
{
    my $self = shift;
    my %args = @_;

    return $self->unlink(path => $args{path});
}

sub removexattr
{
    my $self = shift;
    my %args = @_;

    my $retval = GlusterFS::GFAPI::FFI::glfs_removexattr(
                    $self->fs,
                    $args{path},
                    $args{key});

    if ($retval < 0)
    {
        confess(sprintf('glfs_removexattr(%s, %s, %s) failed: %s'
                , $self->fs, $args{path}, $args{key}, $!));
    }

    return 0;
}

sub rename
{
    my $self = shift;
    my %args = @_;

    my $retval = GlusterFS::GFAPI::FFI::glfs_rename(
                    $self->fs,
                    $args{src},
                    $args{dst});

    if ($retval < 0)
    {
        confess(sprintf('glfs_rename(%s, %s, %s) failed: %s'
                , $self->fs, $args{src}, $args{dst}, $!));
    }

    return 0;
}

sub rmdir
{
    my $self = shift;
    my %args = @_;

    my $retval = GlusterFS::GFAPI::FFI::glfs_rmdir(
                    $self->fs,
                    $args{path});

    if ($retval < 0)
    {
        confess(sprintf('glfs_rmdir(%s, %s) failed: %s'
                , $self->fs, $args{path}, $!));
    }

    return 0;
}

sub rmtree
{
    my $self = shift;
    my %args = @_;

    $args{ignore_errors} //= 0;

    if ($args{ignore_errors})
    {
        $args{onerror} = sub { return; };
    }

    if (!defined($args{onerror}))
    {
        $args{onerror} = sub { confess($_[3]); };
    }

    if ($self->islink(path => $args{path}))
    {
        confess('Cannot call rmtree on a symbolic link');
    }

    try
    {
        my $direntry = $self->scandir(path => $args{path});

        while (my $entry = $direntry->next)
        {
            my $fullname = join('/', $args{path}, $entry->name);

            if ($entry->is_dir(follow_symlinks => 0))
            {
                $self->rmtree(
                    path          => $fullname,
                    ignore_errors => $args{ignore_errors},
                    onerror       => $args{onerror});
            }
            else
            {
                try
                {
                    $self->unlink(path => $fullname);
                }
                catch
                {
                    my $e = shift;

                    $args{onerror}->($self, \&unlink, $fullname, $e)
                        if (ref($args{onerror}) eq 'CODE');
                };
            }
        }
    }
    catch
    {
        my $e = shift;

        $args{onerror}->($self, \&scandir, $args{path}, $e)
            if (ref($args{onerror}) eq 'CODE');
    };

    try
    {
        $self->rmdir(path => $args{path});
    }
    catch
    {
        my $e = shift;

        $args{onerror}->($self, \&rmdir, $args{path}, $e)
            if (ref($args{onerror}) eq 'CODE');
    };

    return 0;
}

sub setfsuid
{
    my $self = shift;
    my %args = @_;

    my $retval = GlusterFS::GFAPI::FFI::glfs_setfsuid($args{uid});

    if ($retval < 0)
    {
        confess(sprintf('glfs_setfsuid(%d) failed: %s'
                , $args{uid}, $!));
    }

    return 0;
}

sub setfsgid
{
    my $self = shift;
    my %args = @_;

    my $retval = GlusterFS::GFAPI::FFI::glfs_setfsgid($args{gid});

    if ($retval < 0)
    {
        confess(sprintf('glfs_setfsgid(%d) failed: %s'
                , $args{gid}, $!));
    }

    return 0;
}

sub setxattr
{
    my $self = shift;
    my %args = @_;

    $args{flags} //= 0;

    my $retval = GlusterFS::GFAPI::FFI::glfs_setxattr(
                    $self->fs, $args{path},
                    $args{key}, $args{value},
                    length($args{value}), $args{flags});

    if ($retval < 0)
    {
        confess(sprintf('glfs_setxattr(%s, %s, %s, %s, %d, 0%o) failed: %s'
                , $self->fs // 'undef'
                , $args{path} // 'undef'
                , $args{key} // 'undef'
                , $args{value} // 'undef'
                , length($args{value})
                , $args{flags}
                , $!));
    }

    return 0;
}

sub stat
{
    my $self = shift;
    my %args = @_;

    my $stat   = GlusterFS::GFAPI::FFI::Stat->new();
    my $retval = GlusterFS::GFAPI::FFI::glfs_stat($self->fs, $args{path}, $stat);

    if ($retval < 0)
    {
        confess(sprintf('glfs_stat(%s, %s, %s) failed: %s'
                , $self->fs // 'undef'
                , $args{path} // 'undef'
                , $stat // 'undef'
                , $!));
    }

    return $stat;
}

sub statvfs
{
    my $self = shift;
    my %args = @_;

    my $stat   = GlusterFS::GFAPI::FFI::Statvfs->new();
    my $retval = GlusterFS::GFAPI::FFI::glfs_statvfs(
                    $self->fs,
                    $args{path},
                    $stat);

    if ($retval < 0)
    {
        confess(sprintf('glfs_statvfs(%s, %s, %s) failed: %s'
                , $self->fs, $args{path}, $stat, $!));
    }

    return $stat;
}

sub link
{
    my $self = shift;
    my %args = @_;

    my $retval = GlusterFS::GFAPI::FFI::glfs_link(
                    $self->fs,
                    $args{src},
                    $args{link});

    if ($retval < 0)
    {
        confess(sprintf('glfs_link(%s, %s, %s) failed: %s'
                , $self->fs, $args{src}, $args{link}, $!));
    }

    return 0;
}

sub symlink
{
    my $self = shift;
    my %args = @_;

    my $retval = GlusterFS::GFAPI::FFI::glfs_symlink(
                    $self->fs,
                    $args{src},
                    $args{link});

    if ($retval < 0)
    {
        confess(sprintf('glfs_symlink(%s, %s, %s) failed: %s'
                , $self->fs, $args{src}, $args{link}, $!));
    }

    return 0;
}

sub unlink
{
    my $self = shift;
    my %args = @_;

    my $retval = GlusterFS::GFAPI::FFI::glfs_unlink($self->fs, $args{path});

    if ($retval < 0)
    {
        confess(sprintf('glfs_unlink(%s, %s) failed: %s'
                , $self->fs, $args{path}, $!));
    }

    return 0;
}

sub utime
{
    my $self = shift;
    my %args = @_;

    $args{atime} = time if (!defined($args{atime}));
    $args{mtime} = time if (!defined($args{mtime}));

    map {
        if (!isint($args{$_}))
        {
            confess("Invalid type: $_");
        }
    } qw/atime mtime/;

    my $tspecs = GlusterFS::GFAPI::FFI::Timespecs->new();

    # Set atime
    my ($fractional, $integral) = modf($args{atime});

    $tspecs->atime_sec(int($integral));
    $tspecs->atime_nsec(int($fractional * 1e9));

    # Set mtime
    ($fractional, $integral) = modf($args{mtime});

    $tspecs->mtime_sec(int($integral));
    $tspecs->mtime_nsec(int($fractional * 1e9));

    my $retval = GlusterFS::GFAPI::FFI::glfs_utimens(
                    $self->fs,
                    $args{path},
                    $tspecs);

    if ($retval < 0)
    {
        confess(sprintf('glfs_utimens(%s, %s, %s) failed: %s'
                , $self->fs, $args{path}, $tspecs, $!));
    }

    return 0;
}

sub walk
{
    my $self = shift;
    my %args = @_;

    return generator {
        my $gen         = $_;
        my $top         = $args{top};
        my $topdown     = $args{topdown};
        my $followlinks = $args{followlinks};
        my $onerror     = $args{onerror};

        if (!defined($topdown))
        {
            $topdown = 1;
        }

        if (!defined($onerror))
        {
            $onerror = undef;
        }

        if (!defined($followlinks))
        {
            $followlinks = 0;
        }

        my @dirs    = ();
        my @nondirs = ();

        try
        {
            my $direntry = $self->scandir(path => $top);

            while (my $entry = $direntry->next)
            {
                if ($entry->is_dir(follow_symlinks => $followlinks))
                {
                    push(@dirs, $entry);
                }
                else
                {
                    push(@nondirs, $entry->name);
                }
            }
        }
        catch
        {
            $onerror->(@_) if (defined($onerror));

            return;
        };

        if ($topdown)
        {
            $gen->yield($top, [ map { $_->name; } @dirs ], \@nondirs);
        }

        foreach my $dir (@dirs)
        {
            # NOTE: Both is_dir() and is_symlink() can be true for the same path
            # when follow_symlinks is set to True
            if ($followlinks || !$dir->is_symlink())
            {
                my $new_path = join('/', $top, $dir->name);

                my $c_gen = $self->walk(
                            top         => $new_path,
                            topdown     => $topdown,
                            onerror     => $onerror,
                            followlinks => $followlinks);

                while (my ($c_path, $c_dirs, $c_nondirs) = $c_gen->next)
                {
                    $gen->yield($c_path, $c_dirs, $c_nondirs);
                }
            }
        }

        if (!$topdown)
        {
            $gen->yield($top, [ map { $_->name; } @dirs ], \@nondirs);
        }
    };

    return 0;
}

sub samefile
{
    my $self = shift;
    my %args = @_;

    my $s1 = $self->stat(path => $args{path1});
    my $s2 = $self->stat(path => $args{path2});

    return $s1->st_ino == $s2->st_ino && $s1->st_dev == $s2->st_dev;
}

sub copyfileobj
{
    my $self = shift;
    my %args = @_;

    if (!defined($args{length}))
    {
        $args{length} = 128 * 1024;
    }

    my $buf = "\0" x $args{length};

    while (1)
    {
        my $nread = $args{fsrc}->readinto(buf => $buf);

        if (!$nread || $nread <= 0)
        {
            last;
        }

        if ($nread == $args{length})
        {
            $args{fdst}->write($buf);
        }
        else
        {
            # TODO:
            # Use memoryview to avoid internal copy done on slicing.
            $args{fdst}->write(substr($buf, 0, $nread));
        }
    }

    return 0;
}

sub copyfile
{
    my $self = shift;
    my %args = @_;

    my $samefile = 0;

    try
    {
        $samefile = $self->samefile(path1 => $args{src}, path2 => $args{dst});
    }
    catch
    {
        return;
    };

    if ($samefile)
    {
        confess(sprintf('`%s` and `%s` are the same file', $args{src}, $args{dst}));
    }

    my $fsrc = $self->fopen(path => $args{src}, mode => 'rb');
    my $fdst = $self->fopen(path => $args{dst}, mode => 'wb');

    return $self->copyfileobj(fsrc => $fsrc, fdst => $fdst);
}

sub copymode
{
    my $self = shift;
    my %args = @_;

    my $st   = $self->stat(path => $args{src});
    my $mode = S_IMODE($st->st_mode);

    return $self->chmod(path => $args{dst}, mode => $mode);
}

sub copystat
{
    my $self = shift;
    my %args = @_;

    my $st   = $self->stat(path => $args{src});
    my $mode = S_IMODE($st->st_mode);

    my $retval = 0;

    $retval |= $self->utime(path  => $args{dst},
                            atime => $st->st_atime,
                            mtime => $st->st_mtime);
    $retval |= $self->chmod(path => $args{dst}, mode => $mode);

    # TODO: Handle st_flags on FreeBSD
    return $retval;
}

sub copy
{
    my $self = shift;
    my %args = @_;

    if ($self->isdir(path => $args{dst}))
    {
        $args{dst} = join($args{dst}, basename($args{src}));
    }

    my $retval = 0;

    $retval |= $self->copyfile(src => $args{src}, dst => $args{dst});
    $retval |= $self->copymode(src => $args{src}, dst => $args{dst});

    return $retval;
}

sub copy2
{
    my $self = shift;
    my %args = @_;

    if ($self->isdir(path => $args{dst}))
    {
        $args{dst} = join($args{dst}, basename($args{src}));
    }

    my $retval = 0;

    $retval |= $self->copyfile($args{src}, $args{dst});
    $retval |= $self->copystat($args{src}, $args{dst});

    return $retval;
}

sub copytree
{
    my $self = shift;
    my %args = @_;

    if (!defined($args{symlinks}))
    {
        $args{symlinks} = 0;
    }

    if (!defined($args{ignore}))
    {
        $args{ignore} = undef;
    }

    my @names_with_stat = $self->listdir_with_stat(path => $args{src});

    my @ignored_names;

    if (defined($args{ignore}))
    {
        @ignored_names = $args{ignore}->($args{src}, @names_with_stat);
    }
    else
    {
        @ignored_names = ();
    }

    $self->makedirs(path => $args{dst});

    my $_isdir = sub
    {
        my $self = shift;
        my %args = @_;

        if (S_ISDIR($args{statinfo}->st_mode))
        {
            return 1;
        }

        if ($args{follow_symlinks} && S_ISLNK($args{statinfo}->st_mode))
        {
            return $self->isdir(path => $args{path});
        }

        return 0;
    };

    my @errors = ();

    my $iter = natatime(2, @names_with_stat);

    while (my ($name, $st) = $iter->())
    {
        if (grep { $name eq $_; } @ignored_names)
        {
            next;
        }

        my $srcpath = join($args{src}, $name);
        my $dstpath = join($args{dst}, $name);

        try
        {
            if ($args{symlinks} && S_ISLNK($st->st_mode))
            {
                my $linkto = $self->readlink($srcpath);

                $self->symlink($linkto, $dstpath);
            }
            elsif ($_isdir->(
                    $self,
                    path            => $srcpath,
                    statinfo        => $st,
                    follow_symlinks => !$args{symlinks}))
            {
                $self->copytree(
                    src      => $srcpath,
                    dst      => $dstpath,
                    symlinks => $args{symlinks});
            }
            else
            {
                my $fsrc = $self->fopen(path => $srcpath, 'rb');
                my $fdst = $self->fopen(path => $dstpath, 'wb');

                $self->copyfileobj(fsrc => $fsrc, fdst => $fdst);

                $self->utime(path => $dstpath, ($st->st_atime, $st->st_mtime));
                $self->chmod(path => $dstpath, S_IMODE($st->st_mode));
            }
        }
        catch
        {
            push(@errors, { src => $srcpath, dst => $dstpath, reason => \@_ });
        };
    }

    try
    {
        $self->copystat(src => $args{src}, dst => $args{dst});
    }
    catch
    {
        push(@errors, { src => $args{src}, dst => $args{dst}, reason => \@_ });
    };

    return @errors;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

GlusterFS::GFAPI::FFI::Volume - GFAPI Volume API

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head2 C<mounted>

Read-only attribute that returns True if the volume is mounted.

The value of the attribute is internally changed on invoking C<mount()> and C<umount()> functions.

=head2 C<fs>

=head2 C<host>

Host with glusterd management daemon running OR path to socket file which glusterd is listening on.

=head2 C<volname>

Name of GlusterFS volume to be mounted and used.

=head2 C<protocol>

Transport protocol to be used to connect to management daemon. Permitted values are "tcp" and "rdma".

=head2 C<port>

Port number where gluster management daemon is listening.

=head2 C<log_file>

Path to log file. When this is set to None, a new logfile will be created in default log directory

i.e /var/log/glusterfs

=head2 C<log_level>

Integer specifying the degree of verbosity. Higher the value, more verbose the logging.

=head1 CONSTRUCTOR

=head2 new

=head3 options

=over

=item C<host>

Host with glusterd management daemon running OR path to socket file which glusterd is listening on.

=item C<volname>

Name of GlusterFS volume to be mounted and used.

=item C<proto>

Transport protocol to be used to connect to management daemon. Permitted values are "tcp" and "rdma".

=item C<port>

Port number where gluster management daemon is listening.

=item C<log_file>

Path to log file. When this is set to None, a new logfile will be created in default log directory

i.e /var/log/glusterfs

=item C<log_level>

Integer specifying the degree of verbosity. Higher the value, more verbose the logging.

=back

=head1 METHODS

=head2 C<mount>

Mount a GlusterFS volume for use.

=head2 C<umount>

Unmount a mounted GlusterFS volume.

Provides users a way to free resources instead of just waiting for perl to call C<DEMOLISH()> at refcnt to be zero.

=head2 C<set_logging>

Set logging parameters. Can be invoked either before or after invoking C<mount()>.

When invoked before C<mount()>, the preferred log file and log level choices are recorded and then later enforced internally as part of C<mount()>.

When invoked at any point after C<mount()>, the change in log file and log level is instantaneous.

=head3 parameters

=over

=item C<log_file>

Path of log file.

If set to "/dev/null", nothing will be logged.
If set to None, a new logfile will be created in default log directory (C</var/log/glusterfs>)

=item C<log_level>

Integer specifying the degree of verbosity. Higher the value, more verbose the logging.

=back

=head2 C<get_volume_id>

Returns the volume ID (of type UUID) for the currently mounted volume.

=head2 C<access>

Use the real uid/gid to test for access to path.

=head3 parameters

=over

=item C<path>

Path to be checked.

=item C<mode>

mode should be C<F_OK> to test the existence of path, or it can be the inclusive OR of one or more of C<R_OK>, C<W_OK>, and C<X_OK> to test permissions

=back

=head3 returns

True if access is allowed, False if not

=head2 C<chdir>

Change the current working directory to the given path.

=head3 parameters

=over

=item C<path>

Path to change current working directory to

=back

=head2 C<chmod>

Change mode of path

=head3 parameters

=over

=item C<path>

the item to be modified

=item C<mode>

new mode

=back

=head2 C<chown>

Change owner and group id of path

=head3 parameters

=over

=item C<path>

the path to be modified

=item C<uid>

new user id for path

=item C<gid>

new group id for path

=head2 C<exists>

Returns True if path refers to an existing path.

Returns False for broken symbolic links.

This function may return False if permission is not granted to execute C<stat()> on the requested file, even if the path physically exists.

=head2 C<getatime>

Returns the last access time as reported by C<stat()>

=head2 C<getctime>

Returns the time when changes were made to the path as reported by C<stat()>.
This time is updated when changes are made to the file or dir's inode or the contents of the file.

=head2 C<getcwd>

Returns current working directory.

=head2 C<getmtime>

Returns the time when changes were made to the content of the path as reported by C<stat()>.

=head2 C<getsize>

Return the size of a file in bytes, reported by stat()

=head2 C<getxattr>

Retrieve the value of the extended attribute identified by key for path specified.

=head3 parameters

=over

=item C<path>

Path to file or directory

=item C<key>

Key of extended attribute

=item C<size>

If size is specified as zero, we first determine the size of xattr and then allocate a buffer accordingly.

If size is non-zero, it is assumed the caller knows the size of xattr.

=back

=head3 returns

Value of extended attribute corresponding to key specified.

=head2 C<isdir>

Returns True if path is an existing directory.

Returns False on all failure cases including when path does not exist.

=head2 C<isfile>

Return True if path is an existing regular file.

Returns False on all failure cases including when path does not exist.

=head2 C<islink>

Return True if path refers to a directory entry that is a symbolic link.

Returns False on all failure cases including when path does not exist.

=head2 C<listdir>

Return a list containing the names of the entries in the directory given by path.

The list is in arbitrary order.

It does not include the special entries '.' and '..' even if they are present in the directory.

=head3 parameters

=over

=item C<path>

Path to directory

=back

=head3 returns

List of names of directory entries

=head2 C<listdir_with_stat>

Return a list containing the name and stat of the entries in the directory given by path.

The list is in arbitrary order.

It does not include the special entries '.' and '..' even if they are present in the directory.

=head3 paramters

=over

=item C<path>

Path to directory

=back

=head3 returns

A list of hashref. The hashref is of the form (name, stat) where name is a string indicating name of the directory entry and stat contains stat info of the entry.

=head2 C<scandir>

Return an iterator of C<GlusterFS::GFAPI::FFI::DirEntry> objects corresponding to the entries in the directory given by path.

The entries are yielded in arbitrary order, and the special entries '.' and '..' are not included.

Using C<scandir()> instead of C<listdir()> can significantly increase the performance of code that also needs file type or file attribute information, because C<GlusterFS::GFAPI::FFI::DirEntry> objects expose this information.

C<scandir() provides same functionality as C<listdir_with_stat()> except that C<scandir()> does not return a list and is an iterator.

Hence scandir is less memory intensive on large directories.

=head3 parameters

=over

=item C<path>

Path to directory

=back

=head2 C<listxattr>

Retrieve list of extended attribute keys for the specified path.

=head3 parameters

=over

=item C<path>

Path to file or directory.

=item C<size>

If size is specified as zero, we first determine the size of list and then allocate a buffer accordingly.

If size is non-zero, it is assumed the caller knows the size of the list.

=back

=head3 returns

List of extended attribute keys.

=head2 C<lstat>

Return stat information of path. If path is a symbolic link, then it returns information about the link itself, not the file that it refers to.

=head2 C<makedirs>

Recursive directory creation function. Like C<mkdir()>, but makes all intermediate-level directories needed to contain the leaf directory.

The default mode is C<0777> (octal).

=head2 C<mkdir>

Create a directory named path with numeric mode mode.

The default mode is C<0777> (octal).

=head2 C<fopen>

Similar to Perl's built-in File object returned by Perl's C<open()>.

Unlike Perl's C<open()>, C<fopen()> provided here is only for convenience and it does NOT invoke glibc's fopen and does NOT do any kind of I/O bufferring as of today.

The most commonly-used values of mode are 'r' for reading, 'w' for writing (truncating the file if it already exists), and 'a' for appending. If mode is omitted, it defaults to 'r'.

Modes 'r+', 'w+' and 'a+' open the file for updating (reading and writing); note that 'w+' truncates the file.

Append 'b' to the mode to open the file in binary mode but this has no effect as of today.

=head3 parameters

=over

=item C<path>

Path of file to be opened

=item C<mode>

Mode to open the file with. This is a string.

=back

=head3 returns

an instance of File class

=head2 C<open>

Similar to Perl's C<open()>

As of today, the only way to consume the raw glfd returned is by passing it to File class.

=head3 parameters

=over

=item C<path>

Path of file to be opened

=item C<flags>

Integer which flags must include one of the following access modes: C<O_RDONLY>, C<O_WRONLY>, or C<O_RDWR>.

=item C<mode>

specifies the permissions to use in case a new file is created.

The default mode is 0777 (octal)

=back

=head3 returns

the raw glfd (pointer to memory in C, number in perl)

=head2 C<opendir>

Open a directory.

=head3 parameters

=over

Path to the directory

=back

=item C<readdirplus>

Enable readdirplus which will also fetch stat information for each entry of directory.

=head3 returns

Returns a instance of Dir class

=head2 C<readlink>

Return a string representing the path to which the symbolic link points.

The result may be either an absolute or relative pathname.

=head2 C<remove>

Remove (delete) the file path. If path is a directory. This is identical to the C<unlink()> function.

=head2 C<removexattr>

Remove a extended attribute of the path.

=head3 parameters

=over

=item C<path>

Path to the file or directory.

=item C<key>

The key of extended attribute.

=back

=item C<path>

Path of symbolic link

=back

=head3 returns

Contents of symlink

=head2 C<rename>

Rename the file or directory from src to dst. If dst is a directory, will be raised.

If dst exists and is a file, it will be replaced silently if the user has permission.

=head3 parameters

=head3 C<src>

=head3 C<dst>

=head2 C<rmdir>

Remove (delete) the directory path. Only works when the directory is empty, otherwise, is raised. In order to remove whole
        directory trees, rmtree() can be used.

=head3 parameters

=over

=item C<path>

=back

=head2 C<rmtree>

Delete a whole directory tree structure. Raises error if C<path> is a symbolic link.

=head3 parameters

=over

=item C<path>

If True, errors are ignored

=item C<ignore_errors>

=item C<onerror>

If set, it is called to handle the error with arguments (C<func>, C<path>, C<exc>) where C<func> is the function that raised the error, C<path> is the argument that caused it to fail; and C<exc> is the exception that was raised.

If C<ignore_errors> is False and onerror is None, an exception is raised

=head2 C<setfsuid>

C<setfsuid()> changes the value of the caller's filesystem user ID-the user ID that the Linux kernel uses to check for all accesses to the filesystem.

=head3 parameters

=over

=item C<uid>

user id to be changed

=back

=head2 C<setfsgid>

setfsgid() changes the value of the caller's filesystem group ID-the group ID that the Linux kernel uses to check for all accesses to the filesystem.

=head3 parameters

=over

=item C<gid>

group id to be changed

=back

=head2 C<setxattr>

Set extended attribute of the C<path>.

=head3 parameters

=over

=item C<path>

Path to file or directory.

=item C<key>

The key of extended attribute.

=item C<value>

The valiue of extended attribute.

=item C<flags>

Possible values are 0 (default), 1 and 2.

If 0 - xattr will be created if it does not exist, or the value will be replaced if the xattr exists.
If 1 - it performs a pure create, which fails if the named attribute already exists.
If 2 - it performs a pure replace operation, which fails if the named attribute does not already exist.

=back

=head2 C<stat>

Returns stat information of path.

=head3 parameters

=over

=item C<path>

Path to file or directory.

=back

=head2 C<statvfs>

Returns information about a mounted glusterfs volume. C<path> is the pathname of any file within the mounted filesystem.

=head3 parameters

=over

=item C<path>

Path to file or directory.

=back

=head3 returns

An object whose attributes describe the filesystem on the given C<path>, and correspond to the members of the statvfs structure, namely:

C<f_bsize>, C<f_frsize>, C<f_blocks>, C<f_bfree>, C<f_bavail>, C<f_files>, C<f_ffree>, C<f_favail>, C<f_fsid, C<f_flag>, and C<f_namemax>.

=head2 C<link>

Create a hard link pointing to C<source> named C<link>.

=head3 parameters

=over

=item C<source>

=item C<link>

=back

=head2 C<symlink>

Create a symbolic link C<link> which points to C<source>

=head3 parameters

=over

=item C<source>

=item C<link>

=back

=head2 C<unlink>

Delete the file C<path>

=head3 parameters

=over

=item C<path>

Path to file or directory.

=back

=head2 C<utime>

Set the access and modified times of the file specified by path.
If C<times> is C<undef>, then the file's access and modified times are set to the current time. (The effect is similar to running the Unix program touch on the path.)
Otherwise, C<times> must be a instance of C<GlusterFS::GFAPI::FFI::Timespecs>, which is used to set the access and modified times, respectively.

=head2 C<walk>

Generate the file names in a directory tree by walking the tree either top-down or bottom-up.

=head3 parameters

=over

=item C<top>

Directory path to walk

=item C<topdown>

If topdown is True or not specified, the triple for a directory is generated before the triples for any of its subdirectories.
If topdown is False, the triple for a directory is generated after the triples for all of its subdirectories.

=item C<onerror>

If optional argument onerror is specified, it should be a function; it will be called with one argument, an exception data.
It can report the error to continue with the walk, or raise exception to abort the walk.

=item C<followlinks>

Set followlinks to True to visit directories pointed to by symlinks.

=back

=head2 C<samefile>

Return True if both pathname arguments refer to the same file or directory (as indicated by device number and inode number).
Raise an exception if a C<stat()> call on either pathname fails.

=head3 parameters

=over

=item C<path1>

Path to one file

=item C<path2>

Path to another file

=back

=head2 C<copyfileobj>

Copy the contents of the file-like object C<fsrc> to the file-like object C<fdst>. The integer length, if given, is the buffer size.
Note that if the current file position of the C<fsrc> object is not 0, only the contents from the current file position to the end of the file will be copied.

=head3 parameters

=over

=item C<fsrc>

Source file object

=item C<fdst>

Destination file object

=item C<length>

Size of buffer in bytes to be used in copying

=back

=head2 C<copyfile>

Copy the contents (no metadata) of the file named C<src> to a file named C<dst>. C<dst> must be the complete target file name.

If C<src> and C<dst> are the same, exception is raised.

The destination location must be writable.

If C<dst> already exists, it will be replaced.

Special files such as character or block devices and pipes cannot be copied with this function.

C<src> and C<dst> are path names given as strings.

=head3 parameters

=over

=item C<src>

Path of source file

=item C<dst>

Path of destination file

=back

=head2 C<copymode>

Copy the permission bits from C<src> to C<dst>. The file contents, owner, and group are unaffected. C<src> and C<dst> are path names given as strings.

=head3 parameters

=over

=item C<src>

Path of source file

=item C<dst>

Path of destination file

=back

=head2 C<copystat>

Copy the permission bits, last access time, last modification time, and flags from C<src> to C<dst>. The file contents, owner, and group are unaffected. C<src> and C<dst> are path names given as strings.

=head3 parameters

=over

=item C<src> Path of source file

=item C<dst> Path of destination file

=back

=head3 parameters

=over

=item C<src>

=item C<dst>

=back

=head2 C<copy>

Copy data and mode bits ("cp src dst").

Copy the file C<src> to the file or directory C<dst>. If C<dst> is a directory, a file with the same basename as C<src> is created (or overwritten) in the directory specified. Permission bits are copied. C<src> and C<dst> are path names given as strings.

=head3 parameters

=over

=item C<src>

Path of source file

=item C<dst>

Path of destination file or directory

=back

=head2 C<copy2>

Similar to C<copy()>, but metadata is copied as well - in fact, this is just C<copy()> followed by C<copystat()>.

This is similar to the Unix command C<cp -p>. The destination may be a directory.

=over

=item C<src>

Path of source file

=item C<dst>

Path of destination file or directory

=back

=head2 C<copytree>

Recursively copy a directory tree using C<copy2()>.

The destination directory must not already exist.

If exception(s) occur, an exception is raised with a list of reasons.

If the optional symlinks flag is true, symbolic links in the source tree result in symbolic links in the destination tree; if it is false, the contents of the files pointed to by symbolic links are copied.

The optional ignore argument is a callable. If given, it is called with the C<src> parameter, which is the directory being visited by C<copytree()>, and C<names> which is the list of C<src> contents:

    C<callable(src, names) -> ignored_names>

Since C<copytree()> is called recursively, the callable will be called once for each directory that is copied.

It returns a list of names relative to the C<src> directory that should not be copied.

=head1 BUGS

=head1 SEE ALSO

=head1 AUTHOR

Ji-Hyeon Gim E<lt>potatogim@gluesys.comE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright 2017-2018 by Ji-Hyeon Gim.

This is free software; you can redistribute it and/or modify it under the same terms as the GPLv2/LGPLv3.

=cut

