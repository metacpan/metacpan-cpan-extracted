# -*-perl-*-
# Creation date: 2003-04-12 22:43:55
# Authors: Don
# Change log:
# $Id: Copy.pm,v 1.10 2004/03/21 04:56:19 don Exp $

use strict;

{   package File::Rotate::Backup::Copy;

    use vars qw($VERSION);
    $VERSION = do { my @r=(q$Revision: 1.10 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r };

    use File::Spec;
    use Fcntl ();

    sub new {
        my ($proto, $params) = @_;
        $params = {} unless ref($params) eq 'HASH';
        my $self = bless { _params => $params }, ref($proto) || $proto;
        return $self;
    }

    sub copy {
        my ($self, $src, $dst) = @_;
        
        if (-l $src or -f $src) {
            return $self->_copySymlinkOrFile($src, $dst);
        } elsif (-d $src) {
            return $self->_copyDirectoryRecursive($src, $dst);
        }
    }

    sub _copyDirectoryRecursive {
        my ($self, $src, $dst) = @_;

        my ($src_vol, $src_dirs, $src_file) = File::Spec->splitpath($src);
        my ($dst_vol, $dst_dirs, $dst_file) = File::Spec->splitpath($dst);

        if (-e $dst and -d $dst) {
            # if dst is a directory, add file name to end of path
            my $dir = File::Spec->catdir($dst_dirs, $dst_file);
            $dst = File::Spec->catpath($dst_vol, $dir, $src_file);
        }

        $self->_copyOneFile($src, $dst);

        my $cur_dir = File::Spec->curdir;
        my $parent_dir = File::Spec->updir;
        local(*DIR);

        opendir(DIR, $src) or return undef;
        my @files = grep { $_ ne $cur_dir and $_ ne $parent_dir } readdir DIR;
        closedir DIR;

        foreach my $file (@files) {
            my $new_src_dir = File::Spec->catdir($src_dirs, $src_file);
            my $src_path = File::Spec->catpath($src_vol, $new_src_dir, $file);
            $self->copy($src_path, $dst);
        }
    }

    sub _copySymlinkOrFile {
        my ($self, $src, $dst) = @_;
        my ($src_vol, $src_dirs, $src_file) = File::Spec->splitpath($src);
        my ($dst_vol, $dst_dirs, $dst_file) = File::Spec->splitpath($dst);

        if (-e $dst and -d $dst) {
            # if dst is a directory, add file name to end of path
            my $dir = File::Spec->catdir($dst_dirs, $dst_file);
            $dst = File::Spec->catpath($dst_vol, $dir, $src_file);
        }
            
        # FIXME: should handle $dst being a symlink

        $self->debugPrint(5, "src_path is $src_dirs, $src_file => $src\n");
        $self->debugPrint(5, "dst_path is $dst_dirs, $dst_file => $dst\n");

        return $self->_copyOneFile($src, $dst);
    }

    sub _copyOneFile {
        my ($self, $src_path, $dst_path) = @_;

        if ($self->_isSameFile($src_path, $dst_path)) {
            return 0;
        }

        # find out what kind of file it is
        my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
            $atime,$mtime,$ctime,$blksize,$blocks)
            = stat($src_path);

        my $permissions = $mode & 07777;

        $self->debugPrint(1, "$src_path ==> $dst_path\n");
        if (-l $src_path) {
            # symlink
            $self->debugPrint(9, "$src_path is a symbolic link\n");
            my $link_content = readlink $src_path;
            return undef unless symlink $link_content, $dst_path;
            # FIXME: set up owner and group of symlink
        } elsif (-f $src_path) {
            # need the full path here instead of the _ filehandle
            # because the -l does an lstat

            # plain file
            my $size = -s _;
            $self->debugPrint(9, "$src_path is a plain file - $size bytes\n");
            $self->_copyPlainFile($src_path, $dst_path) or return undef;
            $self->_fixOwnerPermissionsTimestamp($dst_path);
        } elsif (-d _) {
            # directory
            $self->debugPrint(9, "$src_path is a directory\n");
            return undef unless mkdir $dst_path, 0777;
            $self->_fixOwnerPermissionsTimestamp($dst_path);
        } elsif (-p _) {
            # don't copy pipes, sockets, and other special files for now
            
            # named pipe
            $self->debugPrint(9, "$src_path is a named pipe\n");
        } elsif (-S _) {
            # socket
            $self->debugPrint(9, "$src_path is a socket\n");
        } elsif (-b _) {
            # block special file
            $self->debugPrint(9, "$src_path is a block special file\n");
        } elsif (-c _) {
            # character special file
            $self->debugPrint(9,"$src_path is a character special file\n");
        }

        $self->debugPrint(9, sprintf("$src_path has permissions %o\n", $permissions));

        return 1;
    }

    sub _isSameFile {
        my ($self, $src_file, $dst_file) = @_;
        my ($src_dev, $src_ino);
        my ($dst_dev, $dst_ino);

        if (-l $src_file or -l $dst_file) {
            ($src_dev, $src_ino) = (lstat($src_file))[0,1];
            ($dst_dev, $dst_ino) = (lstat($dst_file))[0,1];
        } else {
            ($src_dev, $src_ino) = (stat($src_file))[0,1];
            ($dst_dev, $dst_ino) = (stat($dst_file))[0,1];
        }

        if ($src_dev == $dst_dev and $src_ino == $dst_ino) {
            return 1;
        }

        return 0;
    }
    
    sub _fixOwnerPermissionsTimestamp {
        my ($self, $dst_file) = @_;
        my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
            $atime,$mtime,$ctime,$blksize,$blocks)
            = stat(_);

        my $permissions = $mode & 07777;

        chown $uid, $gid, $dst_file;
        chmod $permissions, $dst_file;
        utime $atime, $mtime, $dst_file;
    }

    sub _copyPlainFile {
        my ($self, $src_path, $dst_path) = @_;
        
        local(*IN);
        local(*OUT);
        open(IN, '<' . $src_path) or return undef;
        unless (open(OUT, '>' . $dst_path)) {
            close IN;
            return undef;
        }

        # just in case this ever runs on windoze
        binmode IN, ':raw';
        binmode OUT, ':raw';
        
        my $buf;
        while (read(IN, $buf, 1024)) {
            print OUT $buf;
        }
        close IN;
        close OUT;

        return 1;
    }

    sub remove {
        my ($self, $victim) = @_;

        $self->debugPrint(9, "remove() - passed $victim\n");

        if (not -l $victim and -d $victim) {
            return $self->_removeDirectoryRecursive($victim);
        } else {
            $self->debugPrint(1, "Removing $victim\n");
            my $params = $self->_getParams;
            if ($$params{use_flock}) {
                local(*FILE);
                open(FILE, '+<' . $victim);
                unless (CORE::flock(FILE, &Fcntl::LOCK_EX() | &Fcntl::LOCK_NB)) {
                    # can't get lock
                    close FILE;
                    $self->debugPrint(1, "Could not get lock on $victim -- not removing\n");
                    return undef;
                }
                my $rv = unlink $victim;
                CORE::flock(FILE, &Fcntl::LOCK_UN);
                close FILE;
                if (not $rv and $$params{use_rm}) {
                    # added for v0.08
                    $self->debugPrint(1, "unlink() failed -- using /bin/rm\n");
                    $rv = not system("/bin/rm", "-f", $victim);
                }
                return $rv;
            } else {
                my $rv = unlink $victim;
                if (not $rv and $$params{use_rm}) {
                    # added for v0.08
                    $self->debugPrint(1, "unlink() failed -- using /bin/rm\n");
                    $rv = not system("/bin/rm", "-f", $victim);
                }
                return $rv;
            }
        }
    }

    sub _removeDirectoryRecursive {
        my ($self, $dir) = @_;

        $self->debugPrint(9, "_removeDirectoryRecursive() - passed $dir\n");
        
        local(*DIR);
        my $cur_dir = File::Spec->curdir;
        my $parent_dir = File::Spec->updir;

        opendir(DIR, $dir) or return undef;
        my @files = grep { $_ ne $cur_dir and $_ ne $parent_dir } readdir DIR;
        closedir DIR;

        my ($vol, $dirs, $dir_file) = File::Spec->splitpath($dir);
        foreach my $file (@files) {
            my $victim_dir = File::Spec->catdir($dirs, $dir_file);
            my $victim_path = File::Spec->catpath($vol, $victim_dir, $file);
            $self->debugPrint(9, "Trying to remove $victim_path\n");
            $self->remove($victim_path);
        }

        $self->debugPrint(1, "Removing directory $dir\n");
        rmdir $dir;

        return 1;
    }

    sub move {
        my ($self, $src, $dst) = @_;

        # FIXME: implement
    }

    # expects full path for $src and $dst
    sub _move {
        my ($self, $src, $dst) = @_;
        # HERE

        my ($src_dev, $src_ino);
        my ($dst_dev, $dst_ino);

        if (-l $src or -l $dst) {
            ($src_dev, $src_ino) = (lstat($src))[0,1];
            ($dst_dev, $dst_ino) = (lstat($dst))[0,1];
        } else {
            ($src_dev, $src_ino) = (stat($src))[0,1];
            ($dst_dev, $dst_ino) = (stat($dst))[0,1];
        }

        if ($src_dev == $dst_dev) {
            # same filesystem, so we can just do a rename
            rename $src, $dst;
        } else {
            # HERE
        }
    }

    sub debugOn {
        my ($self, $fh, $level) = @_;
        $$self{_debug} = 1;
        $$self{_debug_level} = $level;
        $$self{_debug_fh} = $fh;
    }

    sub debugOff {
        my ($self) = @_;
        undef $$self{_debug};
        undef $$self{_debug_fh};
    }

    sub debugPrint {
        my ($self, $level, $str) = @_;
        return undef unless $$self{_debug};
        return undef unless $$self{_debug_level} >= $level;
        
        my $fh = $$self{_debug_fh};
        print $fh $str;
    }

    sub _getParams {
        my ($self) = @_;
        return $$self{_params} || {};
    }
}

1;

__END__

=pod

=head1 NAME

File::Rotate::Backup::Copy - 

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 METHODS


=head1 EXAMPLES


=head1 BUGS


=head1 AUTHOR


=head1 VERSION

$Id: Copy.pm,v 1.10 2004/03/21 04:56:19 don Exp $

=cut
