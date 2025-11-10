#!/usr/bin/env perl
package File::At;

use common::sense;
use FFI::Platypus 2.00;
use Fcntl qw(:DEFAULT :mode);
use Exporter 'import';
use vars qw(@EXPORT @EXPORT_OK);
our $VERSION   = '0.01';
BEGIN {
  # constants
  push(@EXPORT_OK, qw(
    AT_FDCWD AT_SYMLINK_NOFOLLOW AT_SYMLINK_FOLLOW
    AT_EACCESS AT_REMOVEDIR AT_EMPTY_PATH
    RENAME_NOREPLACE RENAME_EXCHANGE RENAME_WHITEOUT
    )
  );


  # helpers
  push(@EXPORT_OK,qw( dir open_fd_at open_fh_at ));

  # raw bindings (callable directly if you want)
  push(@EXPORT_OK,qw(
    openat     fstatat     unlinkat  mkdirat    mknodat
    mkfifoat   fchmodat    fchownat  utimensat  linkat
    symlinkat  readlinkat  renameat  renameat2  faccessat
    futimesat                                   
    )
  );
};

#----------------------------------------------------------------------
# Constants (from linux/fcntl.h and friends)
#----------------------------------------------------------------------

use constant {
  AT_FDCWD            => -100,
  AT_SYMLINK_NOFOLLOW => 0x100,
  AT_EACCESS          => 0x200,
  AT_REMOVEDIR        => 0x200,   # overlaps on purpose
  AT_SYMLINK_FOLLOW   => 0x400,
  AT_EMPTY_PATH       => 0x1000,

  RENAME_NOREPLACE    => 0x1,
  RENAME_EXCHANGE     => 0x2,
  RENAME_WHITEOUT     => 0x4,
};

#----------------------------------------------------------------------
# FFI bootstrap
#----------------------------------------------------------------------

my $ffi = FFI::Platypus->new( api => 1 );
$ffi->lib(undef);   # libc

# Map common C typedefs so we can use their names in signatures
eval { $ffi->type('uint'  => 'mode_t');};
eval { $ffi->type('uint'  => 'uid_t'); };
eval { $ffi->type('uint'  => 'gid_t'); };
eval { $ffi->type('ulong' => 'dev_t'); };

#----------------------------------------------------------------------
# Raw *at() bindings
#   These are direct libc calls; they follow the C prototypes.
#----------------------------------------------------------------------

# int openat(int dirfd, const char *pathname, int flags, mode_t mode);
$ffi->attach( openat => ['int','string','int','mode_t'] => 'int' );

# int fstatat(int dirfd, const char *pathname, struct stat *buf, int flags);
$ffi->attach( fstatat => ['int','string','opaque','int'] => 'int' );

# int unlinkat(int dirfd, const char *pathname, int flags);
$ffi->attach( unlinkat => ['int','string','int'] => 'int' );

# int mkdirat(int dirfd, const char *pathname, mode_t mode);
$ffi->attach( mkdirat => ['int','string','mode_t'] => 'int' );

# int mknodat(int dirfd, const char *pathname, mode_t mode, dev_t dev);
$ffi->attach( mknodat => ['int','string','mode_t','dev_t'] => 'int' );

# int mkfifoat(int dirfd, const char *pathname, mode_t mode);
$ffi->attach( mkfifoat => ['int','string','mode_t'] => 'int' );

# int fchmodat(int dirfd, const char *pathname, mode_t mode, int flags);
$ffi->attach( fchmodat => ['int','string','mode_t','int'] => 'int' );

# int fchownat(int dirfd, const char *pathname,
#              uid_t owner, gid_t group, int flags);
$ffi->attach( fchownat => ['int','string','uid_t','gid_t','int'] => 'int' );

# int utimensat(int dirfd, const char *pathname,
#               const struct timespec times[2], int flags);
$ffi->attach( utimensat => ['int','string','opaque','int'] => 'int' );

# int linkat(int olddirfd, const char *oldpath,
#            int newdirfd, const char *newpath, int flags);
$ffi->attach( linkat => ['int','string','int','string','int'] => 'int' );

# int symlinkat(const char *target, int newdirfd, const char *linkpath);
$ffi->attach( symlinkat => ['string','int','string'] => 'int' );

# ssize_t readlinkat(int dirfd, const char *pathname,
#                    char *buf, size_t bufsiz);
$ffi->attach( readlinkat => ['int','string','opaque','size_t'] => 'ssize_t' );

# int renameat(int olddirfd, const char *oldpath,
#              int newdirfd, const char *newpath);
$ffi->attach( renameat => ['int','string','int','string'] => 'int' );

# int renameat2(int olddirfd, const char *oldpath,
#               int newdirfd, const char *newpath,
#               unsigned int flags);
eval {
  $ffi->attach( renameat2 => ['int','string','int','string','uint'] => 'int' );
  1;
} or do {
  # Older libcs may not have renameat2; leave symbol undefined in that case.
};

# int faccessat(int dirfd, const char *pathname, int mode, int flags);
$ffi->attach( faccessat => ['int','string','int','int'] => 'int' );

# int futimesat(int dirfd, const char *pathname,
#               const struct timeval times[2]);
eval {
  $ffi->attach( futimesat => ['int','string','opaque'] => 'int' );
  1;
} or do {
  # May be missing on some platforms; ignore.
};

#----------------------------------------------------------------------
# Directory handle helper object
#----------------------------------------------------------------------

{
  package File::At::Dir;
  use common::sense;

  sub new {
    my ($class, $path) = @_;
    opendir(my $dh, $path) or die "opendir($path): $!";
    my $fd = fileno($dh);
    die "File::At::Dir: no fd for $path" unless defined $fd;
    bless { path => $path, dh => $dh, fd => $fd }, $class;
  }

  sub fd   { $_[0]{fd}   }
  sub path { $_[0]{path} }
}

sub dir {
  my ($path) = @_;
  return File::At::Dir->new($path);
}

sub _dirfd {
  my ($dir) = @_;
  return $dir->fd if ref($dir) && $dir->isa('File::At::Dir');
  return int($dir);  # raw fd or AT_FDCWD
}

#----------------------------------------------------------------------
# Convenience wrappers
#----------------------------------------------------------------------

# open_fd_at($dir_or_fd, $relpath, $flags, $mode)
#   -> returns fd or dies
sub open_fd_at {
  my ($dir, $path, $flags, $mode) = @_;
  $mode //= 0;

  my $fd = openat(_dirfd($dir), $path, $flags, $mode);
  return $fd if $fd >= 0;

  die "openat(" . _dirfd($dir) . ", $path): $!";
}

# open_fh_at($dir_or_fd, $relpath, $flags, $mode)
#   -> returns Perl filehandle, dies on error
sub open_fh_at {
  my ($dir, $path, $flags, $mode) = @_;
  my $fd = open_fd_at($dir, $path, $flags, $mode);

  my $acc = $flags & O_ACCMODE;
  my $mode_str =
      $acc == O_RDONLY ? '<'
    : $acc == O_WRONLY ? '>'
    :                    '+<';

  open(my $fh, "$mode_str&=$fd") or die "dup fd $fd: $!";
  return $fh;
}

1;

__END__

=head1 NAME

File::At - Thin FFI wrapper around the POSIX *at() filesystem syscalls

=head1 SYNOPSIS

  use File::At qw(
    AT_FDCWD AT_REMOVEDIR
    dir open_fd_at open_fh_at
    unlinkat mkdirat
  );
  use Fcntl qw(O_RDONLY O_CREAT O_WRONLY);

  my $root = dir("/some/base");

  # Get an fd
  my $fd = open_fd_at($root, "foo.txt", O_CREAT|O_WRONLY, 0644);

  # Or a normal Perl filehandle
  my $fh = open_fh_at($root, "bar.txt", O_CREAT|O_WRONLY, 0644);
  print $fh "hello\n";

  # Unlink relative to that directory
  unlinkat($root->fd, "old.txt", 0) == 0
    or die "unlinkat: $!";

=head1 DESCRIPTION

File::At exposes the modern POSIX/Linux *at() family of filesystem
syscalls via L<FFI::Platypus>, and gives you a small amount of sugar
for working relative to a directory fd.

The bindings are intentionally thin; you can build richer, Perlish
interfaces on top without having to remember the C prototypes or
syscall names.

=head1 EXPORTS

Nothing by default. On request:

  constants: AT_*, RENAME_*
  helpers:   dir, open_fd_at, open_fh_at
  raw api:   all the *at() functions listed above

=cut
