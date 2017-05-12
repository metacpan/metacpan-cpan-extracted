#######################################################################
#      $URL: svn+ssh://equilibrious@equilibrious.net/home/equilibrious/svnrepos/chrisdolan/Fuse-PDF/lib/Fuse/PDF/FS.pm $
#     $Date: 2008-06-06 22:47:54 -0500 (Fri, 06 Jun 2008) $
#   $Author: equilibrious $
# $Revision: 767 $
########################################################################

package Fuse::PDF::FS;

use warnings;
use strict;
use 5.008;

use Carp qw(carp);
use Readonly;
use POSIX qw(:errno_h);
use Fcntl qw(:mode);
use English qw(-no_match_vars);
use CAM::PDF;
use CAM::PDF::Node;
use Fuse::PDF::ErrnoHacks;

our $VERSION = '0.09';

# integer, increases when we break file format backward compatibility
Readonly::Scalar my $COMPATIBILITY_VERSION => 2;

# file format compatibility history:
# 1 = Fuse::PDF v0.01
# 2 = Fuse::PDF v0.02-present
#     add another layer to avoid adding filesystems right in the PDF root dict
#     add fs timestamp

Readonly::Scalar my $PATHLEN => 255;
Readonly::Scalar my $BLOCKSIZE => 4096;
Readonly::Scalar my $ELOOP_LIMIT => 100;
Readonly::Scalar my $ROOT_FS_PERMS => oct 777;
Readonly::Scalar my $DEFAULT_SYMLINK_PERMS => oct 777;

Readonly::Scalar my $FREE_FILES => 1_000_000;
Readonly::Scalar my $MAX_BLOCKS => 1_000_000;
Readonly::Scalar my $FREE_BLOCKS => 500_000;

Readonly::Scalar my $FS_ROOT_KEY => 'FusePDF';

# --------------------------------------------------

sub new {
   my ($pkg, $options) = @_;
   return if ! $options;
   return if ! $options->{pdf};

   my $self = bless {
      # Order matters!
      backup => 0,
      compact => 1,
      autosave_filename => undef,
      fs_name => undef,
      %{$options},
      dirty => 0,
      backedup => {},
   }, $pkg;

   if (!defined $self->{fs_name}) {
      $self->{fs_name} = 'FusePDF_FS';
   }

   # lookup/create fs object in PDF
   my $root = $self->{pdf}->getRootDict();
   my ($o, $g) = ($root->{objnum}, $root->{gennum});

   $root->{$FS_ROOT_KEY} ||= CAM::PDF::Node->new('dictionary', {}, $o, $g);
   my $fs_holder = $root->{$FS_ROOT_KEY}->{value};
   if ($fs_holder->{$self->{fs_name}}) {
      $self->{fs} = $self->{pdf}->getValue($fs_holder->{$self->{fs_name}});
   } else {
      my $fs = CAM::PDF::Node->new('object', CAM::PDF::Node->new('dictionary', {
         nfiles => CAM::PDF::Node->new('number', 1),
         maxinode => CAM::PDF::Node->new('number', 0),
         root => $self->_newdir($root, $ROOT_FS_PERMS),
         mtime => CAM::PDF::Node->new('number', time),
      }));
      # Don't bother marking the FS dirty unless we actually put something in it
      my $objnum = $self->{pdf}->appendObject(undef, $fs, 0); # 0 means no-follow, so the newdir MUST be a single object
      $fs_holder->{$self->{fs_name}} = CAM::PDF::Node->new('reference', $objnum, $o, $g);
      $self->{fs} = $fs->{value}->{value};
   }

   return $self;
}

sub DESTROY {
   my ($self) = @_;
   if (defined $self->{autosave_filename}) {
      $self->save($self->{autosave_filename});
   }
   return;
}

sub deletefs {
   my ($self, $filename) = @_;
   my $root = $self->{pdf}->getRootDict();
   if ($root->{$FS_ROOT_KEY}) {
      delete $root->{$FS_ROOT_KEY}->{value}->{$self->{fs_name}};
      $self->{pdf}->cleanse();
      $self->{pdf}->cleanoutput($filename);
   }
   return;
}

sub compact { ## no critic(ArgUnpacking)
   my ($self, $boolean) = @_;
   return $self->{compact} if @_ == 1;
   $self->{compact} = $boolean ? 1 : undef;
   return;
}

sub backup { ## no critic(ArgUnpacking)
   my ($self, $boolean) = @_;
   return $self->{backup} if @_ == 1;
   $self->{backup} = $boolean ? 1 : undef;
   return;
}

sub autosave_filename { ## no critic(ArgUnpacking)
   my ($self, $filename) = @_;
   return $self->{autosave_filename} if @_ == 1;
   $self->{autosave_filename} = $filename;
   return;
}

# subclasses may wish to override this
sub _software_name {
   my ($self) = @_;
   return ref $self;
}

sub save {
   my ($self, $filename) = @_;
   if ($self->{dirty}) {
      $self->{pdf}->{changes}->{$self->{fs}->{root}->{objnum}} = 1;
      # TODO: atomically?
      $self->{fs}->{creator} = CAM::PDF::Node->new('string', $self->_software_name);
      $self->{fs}->{version} = CAM::PDF::Node->new('string', $self->VERSION);
      $self->{fs}->{compatibility} = CAM::PDF::Node->new('number', $COMPATIBILITY_VERSION);
      if ($self->{compact}) {
         $self->{pdf}->cleanse();
         $self->{pdf}->clean();
      }
      if ($self->{backup} && -e $filename && !$self->{backedup}->{$filename}) {
         my $backup_filename = $filename . '.bak';
         unlink $backup_filename; # ignore failure
         rename $filename, $backup_filename or carp 'Failed to make a backup of the filesystem: ' . $OS_ERROR;
         $self->{backedup}->{$filename} = 1;
      }
      $self->{pdf}->output($filename);
      $self->{dirty} = 0;
   }
   return;
}

sub previous_revision {
   my ($self) = @_;

   my $prev_pdf = $self->{pdf}->previousRevision();
   return if !$prev_pdf;

   return __PACKAGE__->new({
      pdf => $prev_pdf,
      fs_name => $self->{fs_name},
   });
}

sub all_revisions {
   my ($self) = @_;
   my @revs;
   for (my $fs = $self; $fs; $fs = $fs->previous_revision) {  ## no critic(ProhibitCStyleForLoops)
      push @revs, $fs;
   }
   return @revs;
}

sub statistics {
   my ($self) = @_;
   my %stats;
   $stats{name} = $self->{fs_name};
   $stats{nfiles} = $self->{fs}->{nfiles}->{value};
   $stats{mtime} = $self->{fs}->{mtime}->{value};
   return \%stats;
}

sub to_string {
   my ($self) = @_;
   my @stats = ($self->statistics);
   my $fs = $self;
   while ($fs = $fs->previous_revision) {
      push @stats, $fs->statistics;
   }
   my @rows = (
      'Name:       ' . $stats[0]->{name},
   );
   for my $i (0 .. $#stats) {
      my $s = $stats[$i];
      push @rows, 'Revision:   ' . (@stats - $i);
      push @rows, '  Modified: ' . localtime($s->{mtime}) . " ($s->{mtime})";
      push @rows, '  Files:    ' . $s->{nfiles};
   }

   return join "\n", @rows, q{};
}

# --------------------------------------------------

sub fs_getattr {
   my ($self, $abspath) = @_;
   my $f = $self->_file($abspath);
   return -$f if !ref $f;
   my $type = $f->{type}->{value};
   my $size = 'd' eq $type ? 0 : length $f->{content}->{value};
   my $blocks = 0 == $size ? 0 : (($size - 1) % $BLOCKSIZE) + 1;  # round up
   return
       0, # dev
       $f->{inode}->{value},
       $f->{mode}->{value},
       $f->{nlink}->{value},
       $EFFECTIVE_USER_ID, # uid
       0+$EFFECTIVE_GROUP_ID, # gid
       0, #rdev
       $size,
       $f->{mtime}->{value}, # atime not preserved
       $f->{mtime}->{value},
       $f->{ctime}->{value},
       $BLOCKSIZE,
       $blocks;
}

sub fs_readlink {
   my ($self, $abspath) = @_;
   my $f = $self->_file($abspath);
   return -$f if !ref $f;
   my $type = $f->{type}->{value};
   return -EINVAL() if 'l' ne $type;
   return $f->{content}->{value};
}

sub fs_getdir {
   my ($self, $abspath) = @_;
   my $f = $self->_file($abspath);
   return -$f if !ref $f;
   return q{.}, q{..}, (keys %{$f->{content}->{value}}), 0;
}

sub fs_mknod {
   my ($self, $abspath, $perms, $dev) = @_;
   my ($p, $name) = $self->_parent($abspath);
   return -$p if !ref $p;
   return -EEXIST() if q{.}  eq $name;
   return -EEXIST() if q{..} eq $name;
   my $f = $p->{content}->{value}->{$name};
   return -EEXIST() if $f;

   # don't support special files
   my $is_special = !S_ISREG($perms) && !S_ISDIR($perms) && !S_ISLNK($perms);
   return -EIO() if $is_special;

   my $newfile = $self->_newfile($p, $perms);
   my $mtime = $newfile->{value}->{mtime}->{value};
   $newfile->{value}->{inode}->{value} = ++$self->{fs}->{maxinode}->{value};
   $p->{content}->{value}->{$name} = $newfile;
   #$p->{nlink}->{value}++;
   $p->{mtime}->{value} = $mtime;
   $self->{fs}->{nfiles}->{value}++;
   $self->{fs}->{mtime}->{value} = $mtime;
   $self->{dirty} = 1;
   return 0;
}

sub fs_mkdir {
   my ($self, $abspath, $perm) = @_;
   my ($p, $name) = $self->_parent($abspath);
   return -$p if !ref $p;
   return -EEXIST() if q{.}  eq $name;
   return -EEXIST() if q{..} eq $name;
   my $f = $p->{content}->{value}->{$name};
   return -EEXIST() if $f;
   my $newdir = $self->_newdir($p, $perm);
   my $mtime = $newdir->{value}->{mtime}->{value};
   $newdir->{value}->{inode}->{value} = ++$self->{fs}->{maxinode}->{value};
   $p->{content}->{value}->{$name} = $newdir;
   $p->{nlink}->{value}++;
   $p->{mtime}->{value} = $mtime;
   $self->{fs}->{nfiles}->{value}++;
   $self->{fs}->{mtime}->{value} = $mtime;
   $self->{dirty} = 1;
   return 0;
}

sub fs_unlink {
   my ($self, $abspath) = @_;
   my ($p, $name) = $self->_parent($abspath);
   return -$p if !ref $p;
   #use Data::Dumper; print STDERR "$name vs. ".Dumper($p);
   my $f = $p->{content}->{value}->{$name};
   return -ENOENT() if !ref $f;
   $f = $f->{value};
   my $type = $f->{type}->{value};
   return -ENOENT() if 'd' eq $type;  # TODO: is this the right errno??

   # TODO: worry about open files?

   delete $p->{content}->{value}->{$name};
   #$p->{nlink}->{value}--;
   my $mtime = time;
   $p->{mtime}->{value} = $mtime;
   $self->{fs}->{mtime}->{value} = $mtime;
   $self->{dirty} = 1;
   return 0;
}

sub fs_rmdir {
   my ($self, $abspath) = @_;
   my ($p, $name) = $self->_parent($abspath);
   return -$p if !ref $p;
   my $f = $p->{content}->{value}->{$name};
   return -ENOENT() if !ref $f;
   $f = $f->{value};
   my $type = $f->{type}->{value};
   return -ENOTDIR() if 'd' ne $type;
   return -ENOTEMPTY() if 0 != scalar keys %{ $f->{content}->{value} };
   delete $p->{content}->{value}->{$name};
   $p->{nlink}->{value}--;
   my $mtime = time;
   $p->{mtime}->{value} = $mtime;
   $self->{fs}->{mtime}->{value} = $mtime;
   $self->{dirty} = 1;
   return 0;
}

sub fs_symlink {
   my ($self, $link, $abspath) = @_;
   my ($p, $name) = $self->_parent($abspath);
   return -$p if !ref $p;
   return -EEXIST() if q{.}  eq $name;
   return -EEXIST() if q{..} eq $name;
   my $f = $p->{content}->{value}->{$name};
   return -EEXIST() if $f;
   $p->{content}->{value}->{$name} = $self->_newsymlink($p, $link);
   #$p->{nlink}->{value}++;
   my $mtime = time;
   $p->{mtime}->{value} = $mtime;
   $self->{fs}->{mtime}->{value} = $mtime;
   $self->{fs}->{nfiles}->{value}++;
   $self->{dirty} = 1;
   return 0;
}

sub fs_rename {
   my ($self, $srcpath, $destpath) = @_;
   my ($errno, $srcdirs, $srcpaths) = $self->_readpath($srcpath);
   return -$errno if $errno;

   my ($desterrno, $destdirs, $destpaths) = $self->_readpath($destpath, 1);
   return -$desterrno if $desterrno;

   my $src = $srcdirs->[-1];
   my $dest = $destdirs->[-1];

   my $root = $self->{fs}->{root}->{value};
   return -EACCESS if $root == $src;

   if ($dest) {
      return 0 if $dest == $src; # rename to self always works
      return -EACCESS if $root == $dest;
      my $srctype = $src->{type}->{value};
      my $desttype = $dest->{type}->{value};
      return -ENOTDIR() if 'd' eq $srctype && 'd' ne $desttype;
      return -EISDIR() if 'd' ne $srctype && 'd' eq $desttype;
      if ('d' eq $desttype && 0 != scalar keys %{$dest->{content}->{value}}) {
         return -ENOTEMPTY();
      }
   }

   # Ensure dest is not inside src
   if (@{$srcpaths} < @{$destpaths}) {
      my $match = 1;
      for my $i (0 .. $#{$srcpaths}) {
         if ($srcpaths->[$i] ne $destpaths->[$i]) {
            $match = 0;
            last;
         }
      }
      return -EINVAL() if $match;
   }

   my $srcparent  = $srcdirs->[-2];  ## no critic(MagicNumber)
   my $destparent = $destdirs->[-2];  ## no critic(MagicNumber)
   my $srcname    = $srcpaths->[-1];
   my $destname   = $destpaths->[-1];

   # supposed to set dest before removing src to avoid data loss, but meh...
   $destparent->{content}->{value}->{$destname} = delete $srcparent->{content}->{value}->{$srcname};

   my $mtime = time;
   $srcparent->{mtime}->{value} = $mtime;
   $destparent->{mtime}->{value} = $mtime; # harmless if $srcparent == $destparent
   $self->{fs}->{mtime}->{value} = $mtime;
   $self->{dirty} = 1;
   return 0;
}

sub fs_link {
   return -EIO();
}

sub fs_chmod {
   my ($self, $abspath, $perms) = @_;
   my $f = $self->_file($abspath);
   return -$f if !ref $f;
   $f->{mode}->{value} = S_IFMT($f->{mode}->{value}) | S_IMODE($perms);
   $self->{fs}->{mtime}->{value} = time;
   $self->{dirty} = 1;
   return 0;
}

sub fs_chown {
   my ($self, $abspath, $uid, $gid) = @_;
   my $f = $self->_file($abspath);
   return -$f if !ref $f;
   #$f->{uid}->{value} = $uid;
   #$f->{gid}->{value} = $gid;
   #$self->{dirty} = 1;
   return 0;
}

sub fs_truncate {
   my ($self, $abspath, $length) = @_;
   my $f = $self->_file($abspath);
   return -$f if !ref $f;
   my $type = $f->{type}->{value};
   return -EISDIR() if 'd' eq $type;
   if ($length <= 0) {
      $f->{content}->{value} = q{};
   } else {
      my $l = length $f->{content}->{value};
      if ($length < $l) {
         $f->{content}->{value} = substr $f->{content}->{value}, 0, $length;
      } elsif ($length > $l) {
         $f->{content}->{value} .= "\0" x ($length - $l);
      }
   }
   my $mtime = time;
   $f->{mtime}->{value} = $mtime;
   $self->{fs}->{mtime}->{value} = $mtime;
   $self->{dirty} = 1;
   return 0;
}

sub fs_utime {
   my ($self, $abspath, $atime, $mtime) = @_;
   my $f = $self->_file($abspath);
   return -$f if !ref $f;

   # Ignore atime

   # Set utime, if changed
   if ($f->{mtime}->{value} != $mtime) {
      $f->{mtime}->{value} = $mtime;
      $self->{fs}->{mtime}->{value} = time;
      $self->{dirty} = 1;
   }
   return 0;
}

sub fs_open {
   my ($self, $abspath, $flags) = @_;
   my $f = $self->_file($abspath);
   return -$f if !ref $f;
   # check flags?
   return 0;
}

sub fs_read {
   my ($self, $abspath, $size, $offset) = @_;
   my $f = $self->_file($abspath);
   return -$f if !ref $f;
   return substr $f->{content}->{value}, $offset, $size;
}

sub fs_write {
   my ($self, $abspath, $str, $offset) = @_;
   my $f = $self->_file($abspath);
   return -$f if !ref $f;
   my $size = length $str;
   substr($f->{content}->{value}, $offset, $size) = $str;    ##no critic(ProhibitLvalueSubstr)
   my $mtime = time;
   $f->{mtime}->{value} = $mtime;
   $self->{fs}->{mtime}->{value} = $mtime;
   $self->{dirty} = 1;
   return $size;
}

sub fs_statfs {
   my ($self) = @_;
   return $PATHLEN, $self->{fs}->{nfiles}->{value}, $FREE_FILES, $MAX_BLOCKS, $FREE_BLOCKS, $BLOCKSIZE;
}

sub fs_flush {
   my ($self, $abspath) = @_;
   # TODO
   return 0;
}

sub fs_release {
   my ($self, $abspath, $flags) = @_;
   # TODO
   return 0;
}

sub fs_fsync {
   my ($self, $abspath, $flags) = @_;
   # TODO
   return 0;
}

sub fs_setxattr {
   my ($self, $abspath, $key, $value, $flags) = @_;
   if (!$flags->{create} && !$flags->{replace}) {
      return -EIO();
   }
   my $f = $self->_file($abspath);
   return -$f if !ref $f;
   my ($o, $g) = ($f->{type}->{objnum}, $f->{type}->{gennum});
   my $xattr = $f->{xattr};
   if (!$xattr) {
      $xattr = $f->{xattr} = CAM::PDF::Node->new('dictionary', {}, $o, $g);
   }
   if ($flags->{create}) {
      return -EEXIST() if exists $xattr->{value}->{$key};
   } elsif ($flags->{replace}) {
      return -ENOATTR() if !exists $xattr->{value}->{$key};
   }
   $xattr->{value}->{$key} = CAM::PDF::Node->new('string', $value, $o, $g);
   $self->{fs}->{mtime}->{value} = time;
   $self->{dirty} = 1;
   return 0;
}

sub fs_getxattr {
   my ($self, $abspath, $key) = @_;
   my $f = $self->_file($abspath);
   return -$f if !ref $f;
   my $xattr = $f->{xattr};
   return 0 if !$xattr;
   return 0 if !exists $xattr->{value}->{$key};
   return $xattr->{value}->{$key}->{value};
}

sub fs_listxattr {
   my ($self, $abspath, $key) = @_;
   my $f = $self->_file($abspath);
   return -$f if !ref $f;
   my $xattr = $f->{xattr};
   return ($xattr ? keys %{ $xattr->{value} } : ()), 0;
}

sub fs_removexattr {
   my ($self, $abspath, $key) = @_;
   my $f = $self->_file($abspath);
   return -$f if !ref $f;
   my $xattr = $f->{xattr};
   return -ENOATTR() if !$xattr;
   return -ENOATTR() if !exists $xattr->{value}->{$key};
   delete $xattr->{value}->{$key};
   $self->{fs}->{mtime}->{value} = time;
   $self->{dirty} = 1;
   return 0;
}

# --------------------------------------------------

sub _parent {
   my ($self, $path) = @_;
   my ($errno, $dirs, $paths) = $self->_readpath($path, 1);
   return $errno if $errno;
   return $dirs->[-2], $paths->[-1], $dirs->[-1];  ## no critic(MagicNumber)
}

sub _file {
   my ($self, $path) = @_;
   my ($errno, $dirs, $paths) = $self->_readpath($path);
   return $errno if $errno;
   return $dirs->[-1];
}


sub _readpath {
   my ($self, $path, $parent, $nsymlinks) = @_;

   $nsymlinks ||= 0;

   my @dirs = ($self->{fs}->{root}->{value});
   my @path = split m{/}xms, $path;
   my @realpath;

   for (my $i = 0; $i < @path; ++$i) {    ##no critic(ProhibitCStyleForLoops)
      my $entry = $path[$i];
      next if q{} eq $entry;

      my $type = $dirs[-1]->{type}->{value};
      return ENOTDIR() if 'd' ne $type;
      next if q{.} eq $entry;
      if (q{..} eq $entry) {
         pop @dirs;
         pop @realpath;
         return EACCESS() if !@dirs;      # tried to get parent of root
         next;
      }
      push @realpath, $entry;

      my $next = $dirs[-1]->{content}->{value}->{$entry};
      if (!$next) {
         if ($parent && $i == $#path) {
            push @dirs, undef;
            return 0, \@dirs, \@realpath;
         }
         return ENOENT();
      }
      my $f = $next->{value};
      if ('l' eq $f->{type}->{value}) {
         if ($i != $#path) {
            return ELOOP() if ++$nsymlinks >= $ELOOP_LIMIT;
            my $linkpath = $f->{content}->{value};

            # cannot leave the filesystem
            return EACCESS() if $linkpath =~ m{\A /}xms;

            splice @path, $i, 1, split m{/}xms, $linkpath;
            return $self->_readpath((join q{/}, @path), $parent, $nsymlinks);
         }
      }
      push @dirs, $f;
   }

   return 0, \@dirs, \@realpath;
}

sub _newfile {
   my ($self, $parent, $perm) = @_;
   my ($o, $g) = ($parent->{objnum}, $parent->{gennum});
   return $self->_newentry($o, $g, S_IFREG | $perm,
      'f', CAM::PDF::Node->new('string', q{}, $o, $g));
}

sub _newsymlink {
   my ($self, $parent, $src) = @_;
   my ($o, $g) = ($parent->{objnum}, $parent->{gennum});
   return $self->_newentry($o, $g, S_IFLNK | $DEFAULT_SYMLINK_PERMS,
      'l', CAM::PDF::Node->new('string', $src, $o, $g));
}

sub _newdir {
   my ($self, $parent, $perm) = @_;
   # MUST NOT create an new PDF objects
   my ($o, $g) = ($parent->{objnum}, $parent->{gennum});
   my $dir = $self->_newentry($o, $g, S_IFDIR() | $perm,
      'd', CAM::PDF::Node->new('dictionary', {}, $o, $g));
   $dir->{value}->{nlink}->{value}++;
   return $dir;
}

sub _newentry {    ##no critic(ProhibitManyArgs)
   my ($self, $o, $g, $perm, $type, $content) = @_;
   # MUST NOT create an new PDF objects if type = 'd'
   my $now = time;
   return CAM::PDF::Node->new('dictionary', {
      content => $content,
      type    => CAM::PDF::Node->new('string', $type, $o, $g),
      inode   => CAM::PDF::Node->new('number', 0, $o, $g),
      mode    => CAM::PDF::Node->new('number', $perm, $o, $g),
      nlink   => CAM::PDF::Node->new('number', 1, $o, $g),
      mtime   => CAM::PDF::Node->new('number', $now, $o, $g),
      ctime   => CAM::PDF::Node->new('number', $now, $o, $g),
   }, $o, $g);
}

1;

__END__

=pod

=for stopwords pdf runtime EIO

=head1 NAME

Fuse::PDF::FS - In-PDF implementation of a filesystem.

=head1 SYNOPSIS

    use Fuse::PDF::FS;
    my $fs = Fuse::PDF::FS->new({pdf => CAM::PDF->new('my_doc.pdf')});
    $fs->fs_mkdir('/foo');
    $fs->fs_write('/foo/bar', 'Hello world!', 0);
    $fs->save();

=head1 LICENSE

Copyright 2007-2008 Chris Dolan, I<cdolan@cpan.org>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DESCRIPTION

This is an implementation of a filesystem inside of a PDF file.
Contrary to the package name, this module is actually independent of
FUSE, but is meant to map cleanly onto the FUSE API.  See L<Fuse::PDF>
and the F<mount_pdf> front-end.

=head1 METHODS

=over

=item $pkg->new($hash_of_options)

Create a new filesystem instance.  This method creates a new root
filesystem node in the PDF if one does not already exist.  The only
required option is the C<pdf> key, like so:

   my $fs = Fuse::PDF::FS->new({pdf => $pdf});

Supported options:

=over

=item pdf => $pdf

Specify a L<CAM::PDF> instance.  Fuse::PDF::FS is highly dependent on
the architecture of CAM::PDF, so swapping in another PDF
implementation is not likely to be feasible with substantial rewriting
or bridging.

=item fs_name => $name

This specifies the key where the filesystem data is stored inside the
PDF data structure.  Defaults to 'FusePDF_FS', Note that it is
possible to have multiple independent filesystems embedded in the same
PDF at once by choosing another name.  However, mounting more than one
at a time will almost certainly cause data loss.

=item autosave_filename => C<undef> | $filename

If this option is set to a filename, the PDF will be automatically
saved when this instance is garbage collected.  Otherwise, the client
must explicitly call C<save()>.  Defaults to C<undef>.

=item compact => $boolean

Specifies whether the PDF should be compacted upon save.  Defaults to
true.  If this option is turned off, then previous revisions of the
filesystem can be retrieved via standard PDF revert tools, like
F<revertpdf.pl> from the L<CAM::PDF> distribution.  But that can lead
to rather large PDFs.

=item backup => $boolean

Specifies whether to save the previous version of the PDF as
F<$filename.bak> before saving a new version.  Defaults to false.

=back

=item $self->autosave_filename()

=item $self->autosave_filename($filename)

Accessor/mutator for the C<autosave_filename> property described above.

=item $self->compact()

=item $self->compact($boolean)

Accessor/mutator for the C<compact> property described above.

=item $self->backup()

=item $self->backup($boolean)

Accessor/mutator for the C<backup> property described above.

=item $self->save($filename);

Explicitly trigger a save to the specified filename.  If
C<autosave_filename> is defined, then this method is called via
C<DESTROY()>.

=item $self->deletefs($filename)

Delete the filesystem from the in-memory PDF and save the result to
the specified filename.  If there is more than one filesystem in the
PDF, only the one indicated by the C<fs_name> above is affected.  If
no filesystem exists with that C<fs_name>, the save succeeds anyway.

=item $self->all_revisions()

Return a list of one instance for each revision of the PDF.  The first
item on the list is this instance (the newest) and the last item on
the list is the first revision of the PDF (the oldest).

=item $self->previous_revision()

If there is an older version of the PDF, extract that and return a new
C<Fuse::PDF::FS> instance which applies to that revision.  Multiple
versions is feature supported by the PDF specification, so this action
is consistent with other PDF revision editing tools.

If this is a new filesystem or if the C<compact()> option was used,
then there will be no previous revisions and this will return
C<undef>.

=item $self->statistics()

Return a hashref with some global information about the filesystem.
This is currently meant for humans and the exact list of statistics is
not yet locked down.  See the code for more details.

=item $self->to_string()

Return a human-readable representation of the statistics for each
revision of the filesystem.

=back

=head1 FUSE-COMPATIBLE METHODS

The following methods are independent of L<Fuse>, but uses almost the
exact same API expected by that package (except for fs_setxattr), so
they can easily be converted to a FUSE implementation.

=over

=item $self->fs_getattr($file)

=item $self->fs_readlink($file)

=item $self->fs_getdir($file)

=item $self->fs_mknod($file, $modes, $dev)

=item $self->fs_mkdir($file, $perms)

=item $self->fs_unlink($file)

=item $self->fs_rmdir($file)

=item $self->fs_symlink($link, $file)

=item $self->fs_rename($oldfile, $file)

=item $self->fs_link($srcfile, $file)

=item $self->fs_chmod($file, $perms)

=item $self->fs_chown($file, $uid, $gid)

=item $self->fs_truncate($file, $length)

=item $self->fs_utime($file, $atime, $mtime)

=item $self->fs_open($file, $mode)

=item $self->fs_read($file, $size, $offset)

=item $self->fs_write($file, $str, $offset)

=item $self->fs_statfs()

=item $self->fs_flush($file)

=item $self->fs_release($file, $mode)

=item $self->fs_fsync($file, $flags)

=item $self->fs_setxattr($file, $key, $value, \%flags)

=item $self->fs_getxattr($file, $key)

=item $self->fs_listxattr($file)

=item $self->fs_removexattr($file, $key)

=back

=head1 HACKS

=over

=item ENOATTR()

L<POSIX> is missing a constant this error number (at least, not on Mac
10.4). If we detect that it is missing at runtime, we attempt to replace it
by: 1) reading F<errno.h>, 2) falling back to EIO.

See L<Fuse::PDF::ErrnoHacks>.

=back

=head1 SEE ALSO

L<Fuse::PDF>

L<CAM::PDF>

=head1 AUTHOR

Chris Dolan, I<cdolan@cpan.org>

=cut

# Local Variables:
#   mode: perl
#   perl-indent-level: 3
#   cperl-indent-level: 3
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
