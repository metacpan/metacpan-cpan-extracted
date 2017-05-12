package File::Find::Node;

use 5.006;
use strict;
use warnings;
use Carp;

our $VERSION = '0.03';

#
# constructor
#

use constant PATH     =>  0;
use constant NAME     =>  1;
use constant LEVEL    =>  2;
use constant PRUNE    =>  3;
use constant FOLLOW   =>  4;
use constant PARENT   =>  5;
use constant PROCESS  =>  6;
use constant POSTPROC =>  7;
use constant FILTER   =>  8;
use constant ERRPROC  =>  9;
use constant STAT     => 10;
use constant ARG      => 11;
use constant USER     => 12;
use constant GROUP    => 13;
use constant MAXFORK  => 14;

sub new {
    my ($class, $path) = @_;
    defined($path) or $path = ".";
    $path =~ s{/+}{/}g;
    $path =~ s{/$}{} if $path ne "/";
    my $self = [
        $path,  # PATH
        $path,  # NAME
        0,      # LEVEL
        0,      # PRUNE
        0,      # FOLLOW
        undef,  # PARENT
        undef,  # PROCESS
        undef,  # POSTPROC
        undef,  # FILTER
        undef,  # ERRPROC
        undef,  # STAT
        undef,  # ARG
        {},     # USER  cache for getpwuid()
        {},     # GROUP cache for getgrgid()
        0       # MAXFORK
    ];
    $self->[NAME] =~ s{.*/}{};
    bless($self);
}

#
# private object methods
#

# _error calls error callback function or calls carp().

sub _error {
    my ($self, $what) = @_;
    if ($self->[ERRPROC]) {
        $self->[ERRPROC]->($self, $what);
    }
    else {
        my $path = $self->[PATH];
        carp(__PACKAGE__, " - $what($path) - $!");
    }
}

# _cycle returns true if this directory is in the parent chain

sub _cycle {
    my $self = shift;
    my ($inum, $dev) = ($self->inum, $self->dev);
    for (my $p = $self->[PARENT]; $p; $p = $p->[PARENT]) {
        return 1 if $dev == $p->dev && $inum == $p->inum;
    }
    0;
}

#
# public object methods
#

sub process {
    my $self = shift;
    $self->[PROCESS] = shift;
    $self;
}

sub post_process {
    my $self = shift;
    $self->[POSTPROC] = shift;
    $self;
}

sub filter {
    my $self = shift;
    $self->[FILTER] = shift;
    $self;
}

sub error_process {
    my $self = shift;
    $self->[ERRPROC] = shift;
    $self;
}

sub arg {
    my $self = shift;
    $self->[ARG] or ($self->[ARG] = {});
}

sub prune {
    my $self = shift;
    $self->[PRUNE] = 1;
    $self;
}

sub stop {
    my $self = shift;
    for (my $p = $self; $p; $p = $p->[PARENT]) {
        $p->[PRUNE] = 1;
    }
    $self;
}

sub follow {
    my $self = shift;
    $self->[FOLLOW] = (@_ == 0 || shift);
    $self;
}

sub fork {
    my $self = shift;
    $self->[MAXFORK] = ($self->[LEVEL] > 0 && @_ > 0) ? shift : 0;
    $self;
}

sub path {
    shift->[PATH];
}

sub name {
    shift->[NAME];
}

sub parent {
    shift->[PARENT];
}

sub level {
    shift->[LEVEL];
}

# These methods return saved stat info

sub stat {
    @{shift->[STAT]};
}

sub dev {
    shift->[STAT]->[0];
}

sub inum {
    shift->[STAT]->[1];
}

sub ino {
    shift->[STAT]->[1];
}

sub mode {
    shift->[STAT]->[2];
}

sub perm {
    shift->[STAT]->[2] & 07777;
}

sub type {
    my $idx = (shift->[STAT]->[2] >> 12) & 017;
    ("?", "p", "c", "?", "d", "?", "b", "?",
     "f", "?", "l", "?", "s", "?", "?", "?")[$idx];
}

sub links {
    shift->[STAT]->[3];
}

sub nlink {
    shift->[STAT]->[3];
}

sub uid {
    shift->[STAT]->[4];
}

sub gid {
    shift->[STAT]->[5];
}

sub user {
    my $self = shift;
    my $uid = $self->uid;
    if (exists($self->[USER]->{$uid})) {
        return $self->[USER]->{$uid};
    }
    my $user = getpwuid($uid);
    $self->[USER]->{$uid} = defined($user) ? $user : $uid;
}

sub group {
    my $self = shift;
    my $gid = $self->gid;
    if (exists($self->[GROUP]->{$gid})) {
        return $self->[GROUP]->{$gid};
    }
    my $group = getgrgid($gid);
    $self->[GROUP]->{$gid} = defined($group) ? $group : $gid;
}

sub rdev {
    shift->[STAT]->[6];
}

sub size {
    shift->[STAT]->[7];
}

sub atime {
    shift->[STAT]->[8];
}

sub mtime {
    shift->[STAT]->[9];
}

sub ctime {
    shift->[STAT]->[10];
}

sub blksize {
    shift->[STAT]->[11];
}

sub blocks {
    shift->[STAT]->[12];
}

# empty returns true for an empty directory or a zero length regular file,
# otherwise false.

sub empty {
    my $self = shift;
    my $ftype = $self->type;
    if ($ftype eq "f") {
        return $self->size == 0;
    }
    elsif ($ftype eq "d") {
        my $dirh;
        if (!opendir($dirh, $self->[PATH])) {
            $self->_error("opendir");
            return 0;
        }
        my $ret = 1;
        while (my $name = readdir($dirh)) {
            if ($name ne "." && $name ne "..") {
                $ret = 0;
                last;
            }
        }
        closedir($dirh);
        return $ret;
    }
    0;
}

# refresh calls stat() or lstat() to load saved stat info

sub refresh {
    my $self = shift;
    my $path = $self->[PATH];
    my @stat;
    if ($self->[FOLLOW]) {
        @stat = CORE::stat($path) or @stat = CORE::lstat($path);
    }
    else {
        @stat = CORE::lstat($path);
    }
    if (@stat) {
        $self->[STAT] = \@stat;
    }
    else {
        $self->_error("stat");
    }
    $self;
}

# find performs the directory traversal

sub find {
    no warnings "recursion";
    my $self = shift;
    $self->refresh->[STAT] or return 0;  # loads stat info

    # avoid cycles

    my $ftype = $self->type;
    return 0 if $ftype eq "d" && $self->[FOLLOW] && $self->_cycle;

    # call process callback

    if ($self->[PROCESS]) {
        $self->[PROCESS]->($self);
    }

    # skip directory if pruned

    return 0 if $ftype ne "d" || $self->[PRUNE];

    # fork sub process if requested by $f->fork

    my $forked = 0;
    if ($self->[LEVEL] > 0 && $self->[MAXFORK] > 1) {
        my $pid = CORE::fork;
        if (!defined($pid)) {
            $self->_error("fork");
        }
        elsif ($pid == 0) {   # sub process continues
            $forked = 1;
        }
        else {
            return $self->[MAXFORK]  # parent process returns
        }
    }

    # read and filter the directory entries

    my $path = $self->[PATH];
    my $dirh;
    if (!opendir($dirh, $path)) {
        $self->_error("opendir");
        exit(0) if $forked;
        return 0;
    }
    my @dirent = $self->[FILTER] ?
        $self->[FILTER]->(readdir($dirh)) : readdir($dirh);
    closedir($dirh);

    # visit the directory entries

    my $maxfork = my $numfork = 0;
    foreach my $name (@dirent) {
        next if $name eq "." || $name eq "..";

        # build child object

        my $child;
        @$child = @$self;
        $child->[PATH] = $path ne "/" ? "$path/$name" : "/$name";
        $child->[NAME] = $name;
        $child->[PARENT] = $self;
        $child->[LEVEL]++;
        $child->[STAT] = undef;
        $child->[ARG]  = undef;
        $child->[MAXFORK] = 0;
        bless($child);

        # wait for sub processes to exit

        while ($numfork > 0 && $numfork >= $maxfork) {
            wait;
            $numfork--;
        }

        # visit the child with a recursive call

        my $forkinfo = $child->find;

        if ($forkinfo > 1) {     # a sub process was forked
            $numfork++;
            $maxfork = $forkinfo;
        }
        last if $self->[PRUNE];  # may have been pruned by child
    }

    # call post_process callback

    if (!$self->[PRUNE] && $self->[POSTPROC]) {
        $self->[POSTPROC]->($self);
    }

    # wait for any remaining sub processes

    while ($numfork-- > 0) {
        wait;
    }
    exit(0) if $forked;
    return 0;
}
1;

__END__

=head1 NAME

File::Find::Node - Object oriented directory tree traverser

=head1 SYNOPSIS

    use File::Find::Node;
    my $f = File::Find::Node->new("path");
    $f->process(sub { ... });
    $f->post_process(sub { ... });
    $f->find;

=head1 DESCRIPTION

The constructor File::Find::Node->new creates a top level
File::Find::Node object for the specified path.
The $f->process method takes a reference to a callback function
that is called for each item in the traversal.  The
$f->post_process method takes a reference to a callback
function that is called for each directory after it has been
traversed.  The $f->find method performs the traversal.

Callback functions are passed a File::Find::Node object
for the item being visited.  This object provides many useful
methods that return information about the item.  Other
methods allow access to the parent directory object
and allow arbitrary data to be stored in objects.

=head1 Constructor

=over 4

=item File::Find::Node->new($path)

Returns a top level File::Find::Node object for the
specified path.  Uses "." if no path is given.

=back

=head1 Methods for the Top Level Object

The following methods are intended to be used with the top level
object, but you can call them with child objects to dynamically
alter the traversal while it is in progress.

=over 4

=item $f->process(\&func)

Takes a reference to a callback function that is called for
each item visited in the traversal, including the top level object.
Returns the object itself, which allows you to chain method
calls such as

  $f->process(\&func)->find;

The callback function is passed a single argument, which is a
File::Find::Node object for the current item.  When visiting
a directory, the function is called before the directory is traversed.

=item $f->post_process(\&func)

Takes a reference to a callback function that is called for each
directory after it has been traversed.  Returns the object itself.
The function is passed the File::Find::Node object for the directory.

=item $f->filter(\&func)

Takes a reference to a callback function that is called to filter
a list of file names.  When descending into a directory,
the function is passed the list of file names obtained with readdir()
and the function returns a new list.  The filter function can be
used to sort and/or remove file names.

  $f->filter(sub {sort @_});
  $f->filter(sub {grep($_ ne ".snapshot", @_)});

=item $f->error_process(\&func)

Takes a reference to a callback function that is called whenever
there is an error.  Returns the object itself.  The function is
passed the File::Find::Node object that encountered the error and
a string indicating the cause:

  "stat"     stat() or lstat() failed
  "opendir"  opendir() failed
  "fork"     fork() failed

An error does not terminate the traversal, so the callback
function may need to call $f->stop or exit() or die().
If the error is a failed stat() or lstat() call then the
object passed to the callback function is incomplete,
which breaks many object methods.  The following methods
(discussed later) are safe:

  $f->path  $f->name  $f->stop  $f->parent  $f->arg  $f->level

Beware that calling $f->refresh or $f->empty may result in an
error and hence a recursive call to the callback function.

  $f->error_process(sub {
      my ($f, $what) = @_;
      my $path = $f->path;
      die("find error: $what($path) : $!");
  });

If no $f->error_process function is specified then errors
are reported with carp().

=item $f->follow($value)

Sets a flag in the object that causes $f->find to follow symbolic
links, which is off by default.  $f->follow takes an optional argument
and returns the object.  If the argument is absent or true
then symbolic links are followed, otherwise not.  If follow is on,
then cycles are possible and $f->find avoids them.  If a symbolic
link cannot be followed, then an object for the link itself is
created rather than for what the link refers to.

=item $f->find

Performs the directory traversal.  As it visits each item
it creates a File::Find::Node object and passes it to the
callback functions specified by the $f->process and
$f->post_process methods.  (If no callbacks are specified,
then nothing useful happens.)  $f->find does not change
directory and it will probably fail if a callback function
changes directory without changing back.

=back

=head1 Methods for Callback Functions

The following methods should be used with the objects
passed to callback functions.

=over 4

=item $f->path

Returns the full path name of the item, beginning
with the path of the top level item.

=item $f->name

Returns the file name (base name) of the item.

=item $f->parent

Returns the object for the parent directory (or undef
for the top level object, which has no parent).  You can call
methods with the parent object such as $f->parent->path.

=item $f->arg

Returns a hash reference that is stored in the object.
The hash is a handy place for callback functions to store arbitrary
data such as flags, counters, totals or other state information between
calls.  An object can access its parent's hash via $f->parent->arg.
For example, you can count the number of regular files in a directory
and total their sizes like this:

  if ($f->type eq "d") {
      $f->arg->{count} = $f->arg->{total} = 0;
  }
  elsif ($f->parent && $f->type eq "f") {
      $f->parent->arg->{count}++;
      $f->parent->arg->{total} += $f->size;
  }

=item $f->level

Returns the depth level of the object.  Returns zero for the top
level object and returns one for its immediate children, etc.

=item $f->prune

Sets a flag in the object that causes $f->find to not traverse
the object and returns the object.
For example, this code skips a directory
if it contains a file called .skipme .

  if ($f->type eq "d" && -f($f->path . "/.skipme")) {
      $f->prune;
      return;
  }

Calling $f->prune on a non-directory has no effect, but you can
call $f->parent->prune if you want to prune the parent directory.
If a directory is pruned, then $f->find does not call the
$f->post_process function.

=item $f->stop

Prunes everything on the $f->parent chain, which causes $f->find
to return.

=item $f->fork($maxfork)

$f->fork sets a flag in the object and returns the object.
The flag causes $f->find to traverse the object using a
concurrent sub process.  The argument
$maxfork limits the number of concurrent processes that
$f->find will create in the object's parent directory.
When the limit is reached, $f->find waits for a sub process
to exit before starting another.  Before leaving the
parent directory $f->find waits for any remaining sub
processes to exit.
$f->fork has no effect if
1) the object is not a directory, or
2) the object is the top level object, or
3) $maxfork is less than two, or
4) $f->fork is called from the $f->post_process function.

You can use $f->fork to traverse directories concurrently.
For example, suppose you have home directories stored
under directories named /users/a /users/b ... /users/z .
The following traverses these directories using up to ten
concurrent processes:

  sub proc {
      my $f = shift;
      $f->fork(10) if $f->level == 1;

      # more code here
  }
  my $f = File::Find::Node->new("/users");
  $f->process(\&proc)->find;

A sub process itself can create sub processes.
Suppose you have directories named
/users/a/aa /users/a/ab ... /users/a/az ...  /users/z/zz .
The following creates up to five concurrent processes at level one,
each of which creates up to four concurrent processes at level two.

  sub proc {
      my $f = shift;
      $f->fork(5) if $f->level == 1;
      $f->fork(4) if $f->level == 2;

      # more code here
  }
  my $f = File::Find::Node->new("/users");
  $f->process(\&proc)->find;

Sub processes have several limitations.
A sub process is created using the Unix/perl fork() call so the
sub process receives a private copy of the parent process's data.
Modifications to perl variables and other data are confined
to the sub process and do not affect the parent process or any
other processes.  Calling exit() or die() or $f->stop only
affects the current process.  Other processes continue to run.
Open filehandles are duplicated when a sub process is created.
In particular, STDOUT and STDERR receive output interspersed
from all processes.

Creating and destroying processes incurs significant system overhead.
Using numerous sub processes to traverse small directory trees is
counterproductive.

=item $f->empty

Returns true if the item is an empty directory or if the item is a
zero length regular file.  Otherwise returns false.

=back

The $f->find method calls stat() or lstat() (depending on $f->follow)
for each item and saves the information in the object.
The following methods are convenient ways
to access the saved stat information and are named according to the
corresponding field in the Unix stat struct and/or the corresponding
option in the Unix find command.

=over 4

=item $f->dev

Returns the device number of the filesystem containing
the item.  You can determine when you cross mount points
with

  if ($f->parent &&  $f->dev != $f->parent->dev) { ... }

=item $f->inum

=item $f->ino

Returns the inode number.

=item $f->mode

Returns the mode bits.

=item $f->type

Returns a lower case letter indicating the type of the item:
  "f" - regular file
  "d" - directory
  "l" - symbolic link
  "b" - block device file
  "c" - character device file
  "p" - named pipe (FIFO)
  "s" - socket
  "?" - unknown (probably an error)

=item $f->perm

Returns the permission bits ($f->mode masked with 07777).
Here are the Unix permission bit definitions in octal:

            user  group other
          +------------------
  read    | 0400   040    04
  write   | 0200   020    02
  execute | 0100   010    01

  set user:   04000
  set group:  02000
  sticky:     01000

For example, to see if write is enabled for group or other:

  if (($f->perm & 022) != 0) { ... }

=item $f->links

=item $f->nlink

Returns the number of hard links.

=item $f->uid

Returns the user id number.

=item $f->user

Returns the user name or else returns the user id
number if getpwuid() fails.  Uses a cache to avoid
extra calls to getpwuid().

=item $f->gid

Returns the group id number.

=item $f->group

Returns the group name or else returns the group id
number if getgrgid() fails.  Uses a cache to avoid
extra calls to getgrgid().

=item $f->rdev

Returns the device number of a device file.

=item $f->size

Returns the size in bytes.

=item $f->atime

Returns the access time.

=item $f->mtime

Returns the modification time.

=item $f->ctime

Returns the inode change time.

=item $f->blksize

Returns the I/O block size of the containing filesystem.

=item $f->blocks

Returns the number of 512 byte blocks allocated for
the item.

=item $f->stat

Returns the array of saved stat information.

  @stat = $f->stat;

=item $f->refresh

Calls stat() or lstat() (depending on $f->follow) to refresh
the saved stat information.  Returns the object.  For
example, you may want to call $f->refresh after changing the
permissions of an object with chmod() or else $f->perm returns
the old saved permissions.

=back

=head1 Efficiency

File::Find::Node is both space and time efficient.  Although it
creates an object for each item in the traversal, at any given time
the only objects that require memory are the current object and the
linear chain of parent objects up to the top level.  Because the
stat information is saved in the object, extra calls to stat() and
lstat() are avoided.

=head1 Examples

This example prints all path names in sorted order.

    use File::Find::Node;
    my $f = File::Find::Node->new($ARGV[0]);
    $f->process(sub { print(shift->path, "\n") });
    $f->filter(sub{sort @_});
    $f->find;

This example recursively removes a directory tree.

    use File::Find::Node;
    my $f = File::Find::Node->new($ARGV[0]);
    $f->process(sub {
        my $f = shift;
        unlink($f->path) if $f->type ne "d";
    });
    $f->post_process(sub { rmdir(shift->path) });
    $f->find;

This example mimics the Unix "du -k" command.

    use File::Find::Node;

    sub proc {
        my $f = shift;
        my $blocks = $f->blocks;
        if ($f->type eq "d") {
            $f->arg->{blocks} = $blocks;
        }
        elsif ($f->parent) {
            $f->parent->arg->{blocks} += $blocks;
        }
    }

    sub postproc {
        my $f = shift;
        printf("%8d %s\n", $f->arg->{blocks} / 2, $f->path);
        if ($f->parent) {
            $f->parent->arg->{blocks} += $f->arg->{blocks};
        }
    }

    my $f = File::Find::Node->new($ARGV[0]);
    $f->process(\&proc)->post_process(\&postproc)->find;

This example outputs a line for each directory showing the
number of regular files immediately contained by the
directory, the total size of the files in Kbytes, and
the name of the directory.

    use File::Find::Node;

    sub proc {
        my $f = shift;
        if ($f->type eq "d") {
            $f->arg->{count} = $f->arg->{total} = 0;
        }
        elsif ($f->parent && $f->type eq "f") {
            $f->parent->arg->{count}++;
            $f->parent->arg->{total} += $f->size;
        }
    }

    sub postproc {
        my $f = shift;
        printf("%5d  %12.2f  %s\n", $f->arg->{count},
            $f->arg->{total} / 1024, $f->path);
    }

    my $f = File::Find::Node->new($ARGV[0]);
    $f->process(\&proc)->post_process(\&postproc);
    $f->filter(sub {sort @_})->find;


This example outputs the N most recently modified regular files
in a directory tree.

    use File::Find::Node;

    my ($N, $dir) = @ARGV;
    my @recent;

    sub proc {
        my $f = shift;
        return if $f->type ne "f";
        if (@recent == $N) {
            return if $f->mtime <= $recent[-1]->mtime;
            pop(@recent);
        }
        @recent = sort { $b->mtime <=> $a->mtime } (@recent, $f);
    }
    my $f = File::Find::Node->new($dir);
    $f->process(\&proc)->find;
    foreach $f (@recent) {
        print(scalar(localtime($f->mtime)), "  ", $f->path, "\n");
    }

=head1 SEE ALSO

See the perl modules File::Find and File::stat.

See the man page for the Unix find(1) command.

=head1 AUTHOR

Stephen C. Losen, University of Virginia, scl@virginia.edu

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Stephen C. Losen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
