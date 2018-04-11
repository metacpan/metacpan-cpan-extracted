#+##############################################################################
#                                                                              #
# File: Directory/Queue.pm                                                     #
#                                                                              #
# Description: object oriented interface to a directory based queue            #
#                                                                              #
#-##############################################################################

#
# module definition
#

package Directory::Queue;
use strict;
use warnings;
our $VERSION  = "2.0";
our $REVISION = sprintf("%d.%02d", q$Revision: 1.52 $ =~ /(\d+)\.(\d+)/);

#
# used modules
#

use No::Worries::Die qw(dief);
use No::Worries::Export qw(export_control);
use No::Worries::Stat qw(ST_DEV ST_INO ST_NLINK ST_SIZE ST_MTIME);
use POSIX qw(:errno_h :fcntl_h);
use Time::HiRes qw();

#
# global variables
#

our(
    %_LoadedModule,             # hash of successfully loaded modules
);

#+++############################################################################
#                                                                              #
# Constants                                                                    #
#                                                                              #
#---############################################################################

#
# reasonable buffer size for file I/O operations
#

use constant SYSBUFSIZE => 1_048_576; # 1MB

#
# regular expressions
#

our(
    $_DirectoryRegexp,    # regexp matching an intermediate directory
    $_ElementRegexp,      # regexp matching an element
);

$_DirectoryRegexp = qr/[0-9a-f]{8}/;
$_ElementRegexp   = qr/[0-9a-f]{14}/;

#+++############################################################################
#                                                                              #
# Common Code                                                                  #
#                                                                              #
#---############################################################################

#
# make sure a module is loaded
#

sub _require ($) {
    my($module) = @_;

    return if $_LoadedModule{$module};
    eval("require $module"); ## no critic 'ProhibitStringyEval'
    if ($@) {
        $@ =~ s/\s+at\s.+?\sline\s+\d+\.?$//;
        dief("failed to load %s: %s", $module, $@);
    } else {
        $_LoadedModule{$module} = 1;
    }
}

#
# return the name of a new element to (try to) use with:
#  - 8 hexadecimal digits for the number of seconds since the Epoch
#  - 5 hexadecimal digits for the microseconds part
#  - 1 hexadecimal digit from the caller to further reduce name collisions
#
# properties:
#  - fixed size (14 hexadecimal digits)
#  - likely to be unique (with very high-probability)
#  - can be lexically sorted
#  - ever increasing (for a given process)
#  - reasonably compact
#  - matching $_ElementRegexp
#

sub _name ($) {
    return(sprintf("%08x%05x%01x", Time::HiRes::gettimeofday(), $_[0]));
}

#
# create a directory in adversary conditions:
#  - return true on success
#  - return false if the directory already exists
#  - die in case of any other error
#  - handle an optional umask
#

sub _special_mkdir ($$) {
    my($path, $umask) = @_;
    my($oldumask, $success);

    if (defined($umask)) {
        $oldumask = umask($umask);
        $success = mkdir($path);
        umask($oldumask);
    } else {
        $success = mkdir($path);
    }
    return(1) if $success;
    dief("cannot mkdir(%s): %s", $path, $!) unless $! == EEXIST and -d $path;
    # RACE: someone else may have created it at the the same time
    return(0);
}

#
# delete a directory in adversary conditions:
#  - return true on success
#  - return false if the path does not exist (anymore)
#  - die in case of any other error
#

sub _special_rmdir ($) {
    my($path) = @_;

    return(1) if rmdir($path);
    dief("cannot rmdir(%s): %s", $path, $!) unless $! == ENOENT;
    # RACE: someone else may have deleted it at the the same time
    return(0);
}

#
# get the contents of a directory in adversary conditions:
#  - return the list of names without . and ..
#  - return an empty list if the directory does not exist (anymore),
#    unless the optional second argument is true
#  - die in case of any other error
#

sub _special_getdir ($;$) {
    my($path, $strict) = @_;
    my($dh, @list);

    if (opendir($dh, $path)) {
        @list = grep($_ !~ /^\.\.?$/, readdir($dh));
        closedir($dh) or dief("cannot closedir(%s): %s", $path, $!);
        return(@list);
    }
    dief("cannot opendir(%s): %s", $path, $!)
        unless $! == ENOENT and not $strict;
    # RACE: someone else may have deleted it at the the same time
    return();
}

#
# create a file:
#  - return the file handle on success
#  - tolerate some errors unless the optional third argument is true
#  - die in case of any other error
#  - handle an optional umask
#

sub _create ($$;$) {
    my($path, $umask, $strict) = @_;
    my($fh, $oldumask, $success);

    if (defined($umask)) {
        $oldumask = umask($umask);
        $success = sysopen($fh, $path, O_WRONLY|O_CREAT|O_EXCL);
        umask($oldumask);
    } else {
        $success = sysopen($fh, $path, O_WRONLY|O_CREAT|O_EXCL);
    }
    return($fh) if $success;
    dief("cannot sysopen(%s, O_WRONLY|O_CREAT|O_EXCL): %s", $path, $!)
        unless ($! == EEXIST or $! == ENOENT) and not $strict;
    # RACE: someone else may have created the file (EEXIST)
    # RACE: the containing directory may be mising (ENOENT)
    return(0);
}

#
# "touch" a file or directory
#

sub _touch ($) {
    my($path) = @_;
    my($time);

    $time = time();
    utime($time, $time, $path)
        or dief("cannot utime(%d, %d, %s): %s", $time, $time, $path, $!);
}

#+++############################################################################
#                                                                              #
# Base Class                                                                   #
#                                                                              #
#---############################################################################

#
# helper to compute an "id" from the given path
#

sub _path2id ($) {
    my($path) = @_;
    my(@stat);

    # on some operating systems, we cannot rely on inode numbers :-(
    return($path) if $^O =~ /^(cygwin|dos|MSWin32)$/;
    # on others, we can: device number plus inode number should be unique
    @stat = stat($path);
    dief("cannot stat(%s): %s", $path, $!) unless @stat;
    return($stat[ST_DEV] . ":" . $stat[ST_INO]);
}

#
# object creator (wrapper)
#

sub new : method {
    my($class, %option) = @_;
    my($subclass);

    $option{"type"} ||= "Simple";
    $subclass = $class . "::" . $option{"type"};
    _require($subclass);
    delete($option{"type"});
    return($subclass->new(%option));
}

#
# object creator (inherited)
#

sub _new : method {
    my($class, %option) = @_;
    my($self, $path);

    # path is mandatory
    dief("missing option: path") unless defined($option{"path"});
    dief("not a directory: %s", $option{"path"})
        if -e $option{"path"} and not -d _;
    # build the object
    $self = {
        "path" => $option{"path"}, # toplevel path
        "dirs" => [],              # cached list of intermediate directories
        "elts" => [],              # cached list of elements
    };
    # check the integer options
    foreach my $name (qw(maxlock maxtemp rndhex umask)) {
        next unless defined($option{$name});
        dief("invalid %s: %s", $name, $option{$name})
            unless $option{$name} =~ /^\d+$/;
    }
    # handle the maxlock option
    if (defined($option{"maxlock"})) {
        $self->{"maxlock"} = $option{"maxlock"};
    } else {
        $self->{"maxlock"} = 600;
    }
    # handle the maxtemp option
    if (defined($option{"maxtemp"})) {
        $self->{"maxtemp"} = $option{"maxtemp"};
    } else {
        $self->{"maxtemp"} = 300;
    }
    # handle the rndhex option
    if (defined($option{"rndhex"})) {
        dief("invalid rndhex: %s", $option{"rndhex"})
            unless $option{"rndhex"} < 16;
        $self->{"rndhex"} = $option{"rndhex"};
    } else {
        $self->{"rndhex"} = int(rand(16));
    }
    # handle the umask option
    if (defined($option{"umask"})) {
        dief("invalid umask: %s", $option{"umask"})
            unless $option{"umask"} < 512;
        $self->{"umask"} = $option{"umask"};
    }
    # create the toplevel directory if needed
    $path = "";
    foreach my $name (split(/\/+/, $self->{"path"})) {
        $path .= $name . "/";
        _special_mkdir($path, $self->{"umask"}) unless -d $path;
    }
    # store the unique queue identifier
    $self->{"id"} = _path2id($self->{"path"});
    # that's it!
    bless($self, $class);
    return($self);
}

#
# copy/clone the object
#
# note:
#  - the main purpose is to copy/clone the iterator cached state
#  - the other attributes are _not_ cloned but this is not a problem
#    since they should not change
#

sub copy : method {
    my($self) = @_;
    my($copy);

    $copy = { %{ $self } };
    $copy->{"dirs"} = [];
    $copy->{"elts"} = [];
    bless($copy, ref($self));
    return($copy);
}

#
# return the toplevel path of the queue
#

sub path : method {
    my($self) = @_;

    return($self->{"path"});
}

#
# return a unique identifier for the queue
#

sub id : method {
    my($self) = @_;

    return($self->{"id"});
}

#
# return the name of the next element in the queue, using cached information
#

sub next : method { ## no critic 'ProhibitBuiltinHomonyms'
    my($self) = @_;
    my($dir, @list);

    return(shift(@{ $self->{"elts"} })) if @{ $self->{"elts"} };
    while (@{ $self->{"dirs"} }) {
        $dir = shift(@{ $self->{"dirs"} });
        foreach my $name (_special_getdir($self->{"path"} . "/" . $dir)) {
            push(@list, $1) if $name =~ /^($_ElementRegexp)$/o; # untaint
        }
        next unless @list;
        $self->{"elts"} = [ map("$dir/$_", sort(@list)) ];
        return(shift(@{ $self->{"elts"} }));
    }
    return("");
}

#
# return the first element in the queue and cache information about the next ones
#

sub first : method {
    my($self) = @_;
    my(@list);

    foreach my $name (_special_getdir($self->{"path"}, "strict")) {
        push(@list, $1) if $name =~ /^($_DirectoryRegexp)$/o; # untaint
    }
    $self->{"dirs"} = [ sort(@list) ];
    $self->{"elts"} = [];
    return($self->next());
}

#
# export control
#

sub import : method {
    my($pkg, %exported);

    $pkg = shift(@_);
    foreach my $name (
        qw(SYSBUFSIZE _name $_DirectoryRegexp $_ElementRegexp
           _special_getdir _special_mkdir _special_rmdir _create _touch)) {
        $exported{$name}++;
    }
    export_control(scalar(caller()), $pkg, \%exported, @_);
}

1;

__END__

=head1 NAME

Directory::Queue - object oriented interface to a directory based queue

=head1 SYNOPSIS

  use Directory::Queue;

  #
  # sample producer
  #

  $dirq = Directory::Queue->new(path => "/tmp/test");
  foreach $count (1 .. 100) {
      $name = $dirq->add(... some data ...);
      printf("# added element %d as %s\n", $count, $name);
  }

  #
  # sample consumer (one pass only)
  #

  $dirq = Directory::Queue->new(path => "/tmp/test");
  for ($name = $dirq->first(); $name; $name = $dirq->next()) {
      next unless $dirq->lock($name);
      printf("# reading element %s\n", $name);
      $data = $dirq->get($name);
      # one could use $dirq->unlock($name) to only browse the queue...
      $dirq->remove($name);
  }

=head1 DESCRIPTION

The goal of this module is to offer a queue system using the underlying
filesystem for storage, security and to prevent race conditions via atomic
operations. It focuses on simplicity, robustness and scalability.

This module allows multiple concurrent readers and writers to interact with
the same queue. A Python implementation of the same algorithm is available at
L<https://github.com/cern-mig/python-dirq>, a Java implementation at
L<https://github.com/cern-mig/java-dirq> and a C implementation at
L<https://github.com/cern-mig/c-dirq> so readers and writers can be written
in different programming languages.

There is no knowledge of priority within a queue. If multiple priorities are
needed, multiple queues should be used.

=head1 TERMINOLOGY

An element is something that contains one or more pieces of data. With
L<Directory::Queue::Simple> queues, an element can only contain one binary
string. With L<Directory::Queue::Normal> queues, more complex data schemas can
be used.

A queue is a "best effort" FIFO (First In - First Out) collection of elements.

It is very hard to guarantee pure FIFO behavior with multiple writers using
the same queue. Consider for instance:

=over

=item *

Writer1: calls the add() method

=item *

Writer2: calls the add() method

=item *

Writer2: the add() method returns

=item *

Writer1: the add() method returns

=back

Who should be first in the queue, Writer1 or Writer2?

For simplicity, this implementation provides only "best effort" FIFO,
i.e. there is a very high probability that elements are processed in FIFO
order but this is not guaranteed. This is achieved by using a high-resolution
timer and having elements sorted by the time their final directory gets
created.

=head1 QUEUE TYPES

Different queue types are supported. More detailed information can be found in
the modules implementing these types:

=over

=item *

L<Directory::Queue::Normal>

=item *

L<Directory::Queue::Simple>

=item *

L<Directory::Queue::Null>

=back

Compared to L<Directory::Queue::Normal>, L<Directory::Queue::Simple>:

=over

=item *

is simpler

=item *

is faster

=item *

uses less space on disk

=item *

can be given existing files to store

=item *

does not support schemas

=item *

can only store and retrieve binary strings

=item *

is not compatible (at filesystem level) with Directory::Queue::Normal

=back

L<Directory::Queue::Null> is special: it is a kind of black hole with the same
API as the other directory queues.

=head1 LOCKING

Adding an element is not a problem because the add() method is atomic.

In order to support multiple reader processes interacting with the same queue,
advisory locking is used. Processes should first lock an element before
working with it. In fact, the get() and remove() methods report a fatal error
if they are called on unlocked elements.

If the process that created the lock dies without unlocking the element, we
end up with a staled lock. The purge() method can be used to remove these
staled locks.

An element can basically be in only one of two states: locked or unlocked.

A newly created element is unlocked as a writer usually does not need to do
anything more with it.

Iterators return all the elements, regardless of their states.

There is no method to get an element state as this information is usually
useless since it may change at any time. Instead, programs should directly try
to lock elements to make sure they are indeed locked.

=head1 CONSTRUCTOR

The new() method of this module can be used to create a Directory::Queue
object that will later be used to interact with the queue. It can have a
C<type> attribute specifying the queue type to use. If not specified, the type
defaults to C<Simple>.

This method is however only a wrapper around the constructor of the underlying
module implementing the functionality. So:

  $dirq = Directory::Queue->new(type => Foo, ... options ...);

is identical to:

  $dirq = Directory::Queue::Foo->new(... options ...);

=head1 INHERITANCE

Regardless of how the directory queue object is created, it inherits from the
C<Directory::Queue> class. You can therefore test if an object is a directory
queue (of any kind) by using:

  if ($object->isa("Directory::Queue")) ...

=head1 BASE METHODS

Here are the methods available in the base class and inherited by all
directory queue implementations:

=over

=item new(PATH)

return a new object (class method)

=item copy()

return a copy of the object

=item path()

return the queue toplevel path

=item id()

return a unique identifier for the queue

=item first()

return the first element in the queue, resetting the iterator;
return an empty string if the queue is empty

=item next()

return the next element in the queue, incrementing the iterator;
return an empty string if there is no next element

=back

=head1 SECURITY

There are no specific security mechanisms in this module.

The elements are stored as plain files and directories. The filesystem
security features (owner, group, permissions, ACLs...) should be used to
adequately protect the data.

By default, the process' umask is respected. See the class constructor
documentation if you want an other behavior.

If multiple readers and writers with different uids are expected, the easiest
solution is to have all the files and directories inside the toplevel
directory world-writable (i.e. umask=0). Then, the permissions of the toplevel
directory itself (e.g. group-writable) are enough to control who can access
the queue.

=head1 SEE ALSO

L<Directory::Queue::Normal>,
L<Directory::Queue::Null>,
L<Directory::Queue::Set>,
L<Directory::Queue::Simple>.

=head1 AUTHOR

Lionel Cons L<http://cern.ch/lionel.cons>

Copyright (C) CERN 2010-2018
