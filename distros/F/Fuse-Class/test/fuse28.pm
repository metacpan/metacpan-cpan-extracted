#
# test filesystem for Fuse 2.8
# (file operations are done via file/directory handle.)
#

use strict;
use warnings;

use Fcntl;
use Errno;

package test::fuse28;

use base qw(Fuse::Class);

sub new {
    my $class = shift;

    my $self = {
	root => test::fuse28::Directory->new,

	handle => {
	}
    };

    return bless $self, $class;
}

sub issue_handle {
    my $self = shift;
    my $obj = shift;

    my $i = 0;
    while ($self->{handle}->{$i}) {
	$i++;
    }

    $self->{handle}->{$i} = $obj;

    return $i;
}

sub release_handle {
    my $self = shift;
    my ($fh) = @_;

    delete $self->{handle}->{$fh};
}

sub pickup {
    my $self = shift;
    my $path = shift;

    my $ret = $self->{root};

    for my $e (split('/', $path)) {
	next if ($e eq '');

	if ($ret->isa('test::fuse28::Directory')) {
	    if ($e eq '..') {
		$ret = $ret->parent;
	    }
	    elsif ($e eq '.') {
		; # nothing
	    }
	    else {
		$ret = $ret->entity($e);
	    }
	}
	else {
	    return undef;
	}
    }

    return $ret;
}

sub init {
    # print STDERR "perl28.pm is started\n";
    return "perl28";
}

# I don't know when this method is called...?
sub destroy {
    my $param = shift;
    print STDERR "$param is ended\n";
}

sub fgetattr {
    my $self = shift;
    my ($path, $fh) = @_;

    my $entity = $self->{handle}->{$fh};
    return (-2) unless ($entity);
    return (-1) unless ($entity->can('attr'));

    $entity->attr;
}

sub getattr {
    my $self = shift;
    my ($path) = @_;

    my $entity = $self->pickup($path);
    return -2 unless ($entity);

    return $entity->attr;
}

sub readlink {
    my $self = shift;
    my ($path) = @_;

    my $entity = $self->pickup($path);
    return -2 unless ($entity);
    return -1 unless ($entity->can('readlink'));

    return $entity->readlink;
}

sub getdir {
    my $self = shift;
    my ($path) = @_;

    # die "this function must not be called.";
    return -1;
}

sub mknod {
    my $self = shift;
    my ($path, $mode, $devno) = @_;

    my ($dirname, $name) = ($path =~ m/^(.*)\/([^\/]+)$/);
    return -2 unless (defined($dirname) && defined($name)); # badname ?

    my $dir = $self->pickup($dirname);
    return -2 unless ($dir);

    return $dir->mknod($name, $mode, $devno);
}

sub mkdir {
    my $self = shift;
    my ($path, $mode) = @_;

    my ($dirname, $name) = ($path =~ m/^(.*)\/([^\/]+)$/);
    return -2 unless (defined($dirname) && defined($name)); # badname ?

    my $dir = $self->pickup($dirname);
    return -2 unless ($dir);

    return $dir->mkdir($name, $mode);
}

sub unlink {
    my $self = shift;
    my ($path) = @_;

    my ($dirname, $name) = ($path =~ m/^(.*)\/([^\/]+)$/);
    return -2 unless (defined($dirname) && defined($name)); # badname ?

    my $dir = $self->pickup($dirname);
    return -2 unless ($dir);

    return $dir->unlink($name);
}

sub rmdir {
    my $self = shift;
    my ($path) = @_;

    my ($dirname, $name) = ($path =~ m/^(.*)\/([^\/]+)$/);
    return -2 unless (defined($dirname) && defined($name)); # badname ?

    my $dir = $self->pickup($dirname);
    return -2 unless ($dir);

    return $dir->rmdir($name);
}

sub symlink {
    my $self = shift;
    my ($existing, $symlink) = @_;

    my ($dirname, $name) = ($symlink =~ m/^(.*)\/([^\/]+)$/);
    return -2 unless (defined($dirname) && defined($name)); # badname ?

    my $dir = $self->pickup($dirname);
    return -2 unless ($dir);

    return $dir->symlink($name, $existing);
}

sub rename {
    my $self = shift;
    my ($old_name, $new_name) = @_;

    my ($dirname1, $name1) = ($old_name =~ m/^(.*)\/([^\/]+)$/);
    return -2 unless (defined($dirname1) && defined($name1)); # badname ?

    my ($dirname2, $name2) = ($new_name =~ m/^(.*)\/([^\/]+)$/);
    return -2 unless (defined($dirname2) && defined($name2)); # badname ?

    my $dir1 = $self->pickup($dirname1);
    return -2 unless ($dir1);

    my $dir2 = $self->pickup($dirname2);
    return -2 unless ($dir2);

    return $dir1->rename($name1, $dir2, $name2);
}

sub opendir {
    my $self = shift;
    my ($path) = @_;

    my $entity = $self->pickup($path);
    return (-2) unless ($entity);

    if ($entity->isa('test::fuse28::Directory')) {
	my $fh =  $self->issue_handle($entity);
	return (0, $fh);
    }
    else {
	return (-2);
    }
}

sub readdir {
    my $self = shift;
    my ($path, $offset, $dh) = @_;

    if ($path eq '/test/readdir-type-1') {
	return $self->readdir_test_type_1(@_);
    }
    elsif ($path eq '/test/readdir-type-2') {
	return $self->readdir_test_type_2(@_);
    }

    my $dir = $self->{handle}->{$dh};
    return (-2) unless ($dir);

    my @names = $dir->readdir;

    if ($offset < $#names) {
      return (@names[$offset..$#names], 0);
    }

    return (0);
}

sub readdir_test_type_1 {
    my $self = shift;
    my ($path, $offset, $dh) = @_;

    my $dir = $self->{handle}->{$dh};
    return (-2) unless ($dir);

    # print STDERR "readdir_test_type_1, path=$path, offset=$offset\n";

    my $i = 1;
    my @list;

    foreach my $name ($dir->readdir) {
	push(@list, [$i++, $name]);
    }

    if ($offset < $#list) {
	return (@list[$offset..$#list], 0);
    }

    return (0);
}

sub readdir_test_type_2 {
    my $self = shift;
    my ($path, $offset, $dh) = @_;

    my $dir = $self->{handle}->{$dh};
    return (-2) unless ($dir);

    # print STDERR "readdir_test_type_2, path=$path, offset=$offset\n";

    my $i = 1;
    my @list;

    foreach my $name ($dir->readdir) {
	my $entity = $self->pickup("$path/$name");
	next unless ($entity);

	push(@list, [$i++, $name, [$entity->attr]]);
    }

    if ($offset < $#list) {
	return (@list[$offset..$#list], 0);
    }

    return (0);
}

sub releasedir {
    my $self = shift;
    my ($path, $dh) = @_;

    if ($self->{handle}->{$dh}) {
	$self->release_handle($dh);
	return 0;
    }

    return -2;
}

sub chmod {
    my $self = shift;
    my ($path, $modes) = @_;

    my $entity = $self->pickup($path);
    return -2 unless ($entity);

    $entity->chmod($modes);
}

sub chown {
    my $self = shift;
    my ($path, $uid, $gid) = @_;

    my $entity = $self->pickup($path);
    return -2 unless ($entity);

    $entity->chown($uid, $gid);
}

sub ftruncate {
    my $self = shift;
    my ($path, $offset, $fh) = @_;

    my $entity = $self->{handle}->{$fh};
    return (-2) unless ($entity);
    return (-1) unless ($entity->can('truncate'));

    $entity->truncate($offset);
}

sub truncate {
    my $self = shift;
    my ($path, $offset) = @_;

    my $entity = $self->pickup($path);
    return -2 unless ($entity);
    return -1 unless ($entity->can('truncate'));

    $entity->truncate($offset);
}

sub utime {
    my $self = shift;
    my ($path, $atime, $mtime) = @_;

    # die "utimens must be called";
    return -1;
}

sub open {
    my $self = shift;
    my ($path, $flags, $fileinfo) = @_;

    my $entity = $self->pickup($path);
    return (-2) unless ($entity);

    return (0, $self->issue_handle($entity));
}

sub write {
    my $self = shift;
    my ($path, $buffer, $offset, $fh) = @_;

    my $entity = $self->{handle}->{$fh};
    return (-2) unless ($entity);
    return (-1) unless ($entity->can('write'));

    $entity->write($buffer, $offset);
}

sub read {
    my $self = shift;
    my ($path, $size, $offset, $fh) = @_;

    my $entity = $self->{handle}->{$fh};
    return (-2) unless ($entity);
    return (-1) unless ($entity->can('read'));

    $entity->read($size, $offset);
}

sub statfs {
    my $self = shift;

    return (255, 50000, 40000, 30000, 20000, 10000);
}

sub utimens {
    my $self = shift;
    my ($path, $atime, $mtime) = @_;

    my $entity = $self->pickup($path);
    return -2 unless ($entity);

    return $entity->utimens($atime, $mtime);
}

sub access {
    my $self = shift;
    my ($path, $mode) = @_;

    if ($path eq '/test/access_no_perm') {
	# if exsits, it's not accesible!!
	return -Errno::EPERM() if $self->pickup($path);
    }

    return 0;
}

sub create {
    my $self = shift;
    my ($path, $mask, $mode) = @_;
    my ($dirname, $name) = ($path =~ m/^(.*)\/([^\/]+)$/);
    return -2 unless (defined($dirname) && defined($name)); # badname ?

    my $dir = $self->pickup($dirname);
    return -2 unless ($dir);

    return Errno::EXISTS if ($self->pickup($path));

    my $ret = $dir->mknod($name, $mask, 0);
    return ($ret) if ($ret != 0);

    my $entity = $self->pickup($path);
    return (-2) unless ($entity);

    return (0, $self->issue_handle($entity));
}

package test::fuse28::Entity;

my $last_ino = 0;

sub new {
    my $class = shift;

    my $t = time;

    my $self = {
	# ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
	# $atime,$mtime,$ctime,$blksize,$blocks)
	attr => [0, $last_ino++, 0, 1, $>+0, $)+0, 0, 0,
		 $t, $t, $t, 1024, 0],
    };

    $self->{attr}->[8] = $t;
    $self->{attr}->[9] = $t;
    $self->{attr}->[10] = $t;

    bless $self, $class;
}

sub attr {
    my $self = shift;
    return @{$self->{attr}};
}

sub chmod {
    my $self = shift;
    my ($modes) = @_;

    my $attr = $self->{attr}->[2] & ~(07777);
    $self->{attr}->[2] = $attr | $modes;

    return 0;
}

sub utimens {
    my $self = shift;
    my ($atime, $mtime) = @_;

    my $attr = $self->{attr};
    $attr->[8] = $atime if ($atime >= 0);
    $attr->[9] = $mtime if ($mtime >= 0);

    return 0;
}

sub chown {
    my $self = shift;
    my ($uid, $gid) = @_;

    $self->{attr}->[4] = $uid if ($uid >= 0);
    $self->{attr}->[5] = $gid if ($gid >= 0);

    return 0;
}

#
# Directory
#
package test::fuse28::Directory;

use Fcntl qw(:mode);
use base qw(test::fuse28::Entity);
use Scalar::Util qw(weaken);

sub new {
    my $class = shift;
    my $parent = shift;

    my $self = $class->SUPER::new;
    $self->{attr}->[2] = S_IFDIR | S_IRWXU;

    if (!defined($parent)) {
	$self->{parent} = $self;
    }
    else {
	$self->{parent} = $parent;
    }

    $self->{children} = {};

    # avoid cyclic reference
    weaken($self->{parent});

    bless $self, $class;
}

sub parent {
    my $self = shift;
    return $self->{parent};
}

sub entity {
  my $self = shift;
  my $name = shift;

  return $self if ($name eq '.');
  return $self->parent if ($name eq '..');

  return $self->{children}->{$name};
}

sub readdir {
  my $self = shift;
  return ('..', '.', keys %{$self->{children}});
}

sub mknod {
  my $self = shift;
  my ($name, $mode, $devno) = @_;

  my $umask = 0;
  $umask |= S_IRUSR if ($mode & 0400);
  $umask |= S_IWUSR if ($mode & 0200);
  $umask |= S_IXUSR if ($mode & 0100);
  $umask |= S_IRGRP if ($mode & 0040);
  $umask |= S_IWGRP if ($mode & 0020);
  $umask |= S_IXGRP if ($mode & 0010);
  $umask |= S_IROTH if ($mode & 0004);
  $umask |= S_IWOTH if ($mode & 0002);
  $umask |= S_IXOTH if ($mode & 0001);

  if (S_ISREG($mode)) {
      my $newfile = test::fuse28::File->new;
      my $attr = S_IFREG | $umask;
      $newfile->{attr}->[2] = $attr;
      $self->{children}->{$name} = $newfile;
      return 0;
  }
  if (S_ISDIR($mode)) {
      return $self->mkdir($name, $mode);
  }

  if (S_ISLNK($mode)) {
      return -1;
  }
  if (S_ISBLK($mode)) {
      return -1;
  }
  if (S_ISCHR($mode)) {
      return -1;
  }
  if (S_ISFIFO($mode)) {
      return -1;
  }
  if (S_ISSOCK($mode)) {
      return -1;
  }

  return -1;
}

sub mkdir {
  my $self = shift;
  my ($name, $mode) = @_;

  my $newdir = test::fuse28::Directory->new($self);
  my $attr = S_IFDIR;
  $attr |= S_IRUSR if ($mode & 0400);
  $attr |= S_IWUSR if ($mode & 0200);
  $attr |= S_IXUSR if ($mode & 0100);
  $attr |= S_IRGRP if ($mode & 0040);
  $attr |= S_IWGRP if ($mode & 0020);
  $attr |= S_IXGRP if ($mode & 0010);
  $attr |= S_IROTH if ($mode & 0004);
  $attr |= S_IWOTH if ($mode & 0002);
  $attr |= S_IXOTH if ($mode & 0001);
  $newdir->{attr}->[2] = $attr;

  $self->{children}->{$name} = $newdir;

  return 0;
}

sub unlink {
  my $self = shift;
  my ($name) = @_;

  my $entity = $self->{children}->{$name};
  return -2 unless ($entity);
  delete $self->{children}->{$name};

  return 0;
}

sub rmdir {
  my $self = shift;
  my ($name) = @_;

  my $entity = $self->{children}->{$name};
  return -2 unless ($entity);
  delete $self->{children}->{$name};

  return 0;
}

sub rename {
  my $self = shift;
  my ($old_name, $new_dir, $new_name) = @_;

  my $entity = $self->{children}->{$old_name};
  return -2 unless ($entity);

  delete $self->{children}->{$old_name};
  $new_dir->{children}->{$new_name} = $entity;

  return 0;
}

sub symlink {
    my $self = shift;
    my ($name, $existing) = @_;

    my $link = test::fuse28::Symlink->new($existing);
    my $attr = S_IFLNK | 0777;
    $link->{attr}->[2] = $attr;
    $self->{children}->{$name} = $link;

    return 0;
}

#
# Normal File
#
package test::fuse28::File;

use base qw(test::fuse28::Entity);

sub new {
    my $class = shift;

    my $self = $class->SUPER::new;
    $self->{content} = '';

    bless $self, $class;
}

sub write {
    my $self = shift;
    my ($buffer, $offset) = @_;

    substr($self->{content}, $offset) = $buffer;
    $self->{attr}->[7] = length($self->{content});
    $self->{attr}->[12] = int(($self->{attr}->[7] + $self->{attr}->[11] - 1) / $self->{attr}->[11]);

    return length($buffer);
}

sub read {
    my $self = shift;
    my ($size, $offset) = @_;

    return substr($self->{content}, $offset, $size);
}

sub truncate {
    my $self = shift;
    my ($offset) = @_;

    $self->{content} = substr($self->{content}, 0, $offset);
    $self->{attr}->[7] = length($self->{content});

    return 0;
}

#
# Symlink
#
package test::fuse28::Symlink;

use base qw(test::fuse28::Entity);
use Scalar::Util qw(weaken);

sub new {
    my $class = shift;
    my ($existing) = @_;

    my $self = $class->SUPER::new;
    $self->{link} = $existing;

    bless $self, $class;
}

sub readlink {
    my $self = shift;

    return $self->{link};
}

1;
