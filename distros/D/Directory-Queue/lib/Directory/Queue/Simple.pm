#+##############################################################################
#                                                                              #
# File: Directory/Queue/Simple.pm                                              #
#                                                                              #
# Description: object oriented interface to a simple directory based queue     #
#                                                                              #
#-##############################################################################

#
# module definition
#

package Directory::Queue::Simple;
use strict;
use warnings;
our $VERSION  = "2.1";
our $REVISION = sprintf("%d.%02d", q$Revision: 1.19 $ =~ /(\d+)\.(\d+)/);

#
# used modules
#

use Directory::Queue qw(_create _name _touch SYSBUFSIZE /Regexp/ /special/);
use No::Worries::Die qw(dief);
use No::Worries::File qw(file_read file_write);
use No::Worries::Stat qw(ST_MTIME);
use No::Worries::Warn qw(warnf);
use POSIX qw(:errno_h);

#
# inheritance
#

our(@ISA) = qw(Directory::Queue);

#
# constants
#

# suffix indicating a temporary element
use constant TEMPORARY_SUFFIX => ".tmp";

# suffix indicating a locked element
use constant LOCKED_SUFFIX => ".lck";

#
# object constructor
#

sub new : method {
    my($class, %option) = @_;
    my($self);

    # default object
    $self = __PACKAGE__->SUPER::_new(%option);
    foreach my $name (qw(path maxlock maxtemp rndhex umask)) {
        delete($option{$name});
    }
    # check granularity
    if (defined($option{granularity})) {
        dief("invalid granularity: %s", $option{granularity})
            unless $option{granularity} =~ /^\d+$/;
        $self->{granularity} = delete($option{granularity});
    } else {
        $self->{granularity} = 60; # default
    }
    # check unexpected options
    foreach my $name (keys(%option)) {
        dief("unexpected option: %s", $name);
    }
    # so far so good...
    return($self);
}

#
# helpers for the add methods
#

sub _add_dir ($) {
    my($self) = @_;
    my($time);

    $time = time();
    $time -= $time % $self->{granularity} if $self->{granularity};
    return(sprintf("%08x", $time));
}

sub _add_data ($$) {
    my($self, $dataref) = @_;
    my($dir, $name, $path, $fh);

    $dir = _add_dir($self);
    while (1) {
        $name = _name($self->{rndhex});
        $path = $self->{path}."/".$dir."/".$name . TEMPORARY_SUFFIX;
        $fh = _create($path, $self->{umask});
        last if $fh;
        _special_mkdir($self->{path}."/".$dir, $self->{umask})
            if $! == ENOENT;
    }
    file_write($path, handle => $fh, data => $dataref);
    return($dir, $path);
}

sub _add_path ($$$) {
    my($self, $tmp, $dir) = @_;
    my($name, $new);

    while (1) {
        $name = _name($self->{rndhex});
        $new = $self->{path}."/".$dir."/".$name;
        # N.B. we use link() + unlink() to make sure $new is never overwritten
        if (link($tmp, $new)) {
            unlink($tmp) or dief("cannot unlink(%s): %s", $tmp, $!);
            return($dir."/".$name);
        }
        dief("cannot link(%s, %s): %s", $tmp, $new, $!) unless $! == EEXIST;
    }
}

#
# add a new element to the queue and return its name
#

sub add : method {
    my($self, $data) = @_;
    my($dir, $path);

    ($dir, $path) = _add_data($self, \$data);
    return(_add_path($self, $path, $dir));
}

sub add_ref : method {
    my($self, $dataref) = @_;
    my($dir, $path);

    ($dir, $path) = _add_data($self, $dataref);
    return(_add_path($self, $path, $dir));
}

sub add_path : method {
    my($self, $path) = @_;
    my($dir);

    $dir = _add_dir($self);
    _special_mkdir($self->{path}."/".$dir, $self->{umask});
    return(_add_path($self, $path, $dir));
}

#
# get a locked element
#

sub get : method {
    my($self, $name) = @_;

    return(file_read($self->{path}."/".$name . LOCKED_SUFFIX));
}

sub get_ref : method {
    my($self, $name) = @_;
    my($data);

    return(file_read($self->{path}."/".$name . LOCKED_SUFFIX, data => \$data));
}

sub get_path : method {
    my($self, $name) = @_;

    return($self->{path}."/".$name . LOCKED_SUFFIX);
}

#
# lock an element:
#  - return true on success
#  - return false in case the element could not be locked (in permissive mode)
#

sub lock : method {  ## no critic 'ProhibitBuiltinHomonyms'
    my($self, $name, $permissive) = @_;
    my($path, $lock, $time, $ignored);

    $permissive = 1 unless defined($permissive);
    $path = $self->{path}."/".$name;
    $lock = $path . LOCKED_SUFFIX;
    unless (link($path, $lock)) {
        return(0) if $permissive and ($! == EEXIST or $! == ENOENT);
        dief("cannot link(%s, %s): %s", $path, $lock, $!);
    }
    # we also touch the element to indicate the lock time
    $time = time();
    unless (utime($time, $time, $path)) {
        if ($permissive and $! == ENOENT) {
            # RACE: the element file does not exist anymore
            # (this can happen if an other process locked & removed the element
            #  while our link() was in progress... yes, this can happen!
            #  we do our best and ignore what unlink() returns)
            $ignored = unlink($lock);
            return(0);
        }
        # otherwise this is unexpected...
        dief("cannot utime(%d, %d, %s): %s", $time, $time, $path, $!);
    }
    # so far so good
    return(1);
}

#
# unlock an element:
#  - return true on success
#  - return false in case the element could not be unlocked (in permissive mode)
#

sub unlock : method {
    my($self, $name, $permissive) = @_;
    my($path, $lock);

    $permissive = 0 unless defined($permissive);
    $path = $self->{path}."/".$name;
    $lock = $path . LOCKED_SUFFIX;
    return(1) if unlink($lock);
    return(0) if $permissive and $! == ENOENT;
    dief("cannot unlink(%s): %s", $lock, $!);
}

#
# touch an element to indicate that it is still being used
#

sub touch : method {
    my($self, $element) = @_;

    _touch($self->{"path"}."/".$element);
}

#
# remove a locked element from the queue
#

sub remove : method {
    my($self, $name) = @_;
    my($path, $lock);

    $path = $self->{path}."/".$name;
    $lock = $path . LOCKED_SUFFIX;
    unlink($path) or dief("cannot unlink(%s): %s", $path, $!);
    unlink($lock) or dief("cannot unlink(%s): %s", $lock, $!);
}

#
# return the number of elements in the queue, locked or not (but not temporary)
#

sub count : method {
    my($self) = @_;
    my($count, @list);

    $count = 0;
    # get the list of directories
    foreach my $name (_special_getdir($self->{path}, "strict")) {
        push(@list, $1) if $name =~ /^($_DirectoryRegexp)$/o; # untaint
    }
    # count the elements inside
    foreach my $name (@list) {
        $count += grep(/^(?:$_ElementRegexp)$/o,
                       _special_getdir($self->{path}."/".$name));
    }
    # that's all
    return($count);
}

#
# purge an intermediate directory
#

sub _purge_dir ($$$) {
    my($dir, $oldtemp, $oldlock) = @_;
    my($path, @stat);

    foreach my $name (grep(/\./, _special_getdir($dir))) {
        $path = $dir."/".$name;
        @stat = stat($path);
        unless (@stat) {
            dief("cannot stat(%s): %s", $path, $!) unless $! == ENOENT;
            next;
        }
        next if substr($name, -4) eq TEMPORARY_SUFFIX
            and $stat[ST_MTIME] >= $oldtemp;
        next if substr($name, -4) eq LOCKED_SUFFIX
            and $stat[ST_MTIME] >= $oldlock;
        warnf("removing too old volatile file: %s", $path);
        next if unlink($path);
        dief("cannot unlink(%s): %s", $path, $!) unless $! == ENOENT;
    }
}

#
# purge the queue
#

sub purge : method {
    my($self, %option) = @_;
    my(@list, $path, $oldtemp, $oldlock);

    # check options
    $option{maxtemp} = $self->{maxtemp} unless defined($option{maxtemp});
    $option{maxlock} = $self->{maxtemp} unless defined($option{maxlock});
    foreach my $name (keys(%option)) {
        dief("unexpected option: %s", $name)
            unless $name =~ /^(maxtemp|maxlock)$/;
        dief("invalid %s: %s", $name, $option{$name})
            unless $option{$name} =~ /^\d+$/;
    }
    # get the list of intermediate directories
    @list = ();
    foreach my $name (_special_getdir($self->{path}, "strict")) {
        push(@list, $1) if $name =~ /^($_DirectoryRegexp)$/o; # untaint
    }
    # remove the old temporary or locked elements
    $oldtemp = $oldlock = 0;
    $oldtemp = time() - $option{maxtemp} if $option{maxtemp};
    $oldlock = time() - $option{maxlock} if $option{maxlock};
    if ($oldtemp or $oldlock) {
        foreach my $name (@list) {
            _purge_dir($self->{path}."/".$name, $oldtemp, $oldlock);
        }
    }
    # try to purge all but the last intermediate directory
    if (@list > 1) {
        @list = sort(@list);
        pop(@list);
        foreach my $name (@list) {
            $path = $self->{path}."/".$name;
            _special_rmdir($path) unless _special_getdir($path);
        }
    }
}

1;

__END__

=head1 NAME

Directory::Queue::Simple - object oriented interface to a simple directory based queue

=head1 SYNOPSIS

  use Directory::Queue::Simple;

  #
  # sample producer
  #

  $dirq = Directory::Queue::Simple->new(path => "/tmp/test");
  foreach $count (1 .. 100) {
      $name = $dirq->add("element $count\n");
      printf("# added element %d as %s\n", $count, $name);
  }

  #
  # sample consumer (one pass only)
  #

  $dirq = Directory::Queue::Simple->new(path => "/tmp/test");
  for ($name = $dirq->first(); $name; $name = $dirq->next()) {
      next unless $dirq->lock($name);
      printf("# reading element %s\n", $name);
      $data = $dirq->get($name);
      # one could use $dirq->unlock($name) to only browse the queue...
      $dirq->remove($name);
  }

=head1 DESCRIPTION

The goal of this module is to offer a "simple" (as opposed to "normal") queue
system using the underlying filesystem for storage, security and to prevent
race conditions via atomic operations.

It only allows binary strings to be stored but it is fast and small.

Please refer to L<Directory::Queue> for general information about directory
queues.

=head1 CONSTRUCTOR

The new() method can be used to create a Directory::Queue::Simple object that
will later be used to interact with the queue. The following attributes are
supported:

=over

=item path

the queue toplevel directory (mandatory)

=item rndhex

the "random" hexadecimal digit to use in element names (aka I<R>) as a number
between 0 and 15 (default: randomly generated)

=item umask

the umask to use when creating files and directories (default: use the running
process' umask)

=item maxlock

default maximum time for a locked element (in seconds, default 600)
as used by the purge() method

=item maxtemp

default maximum time for a temporary element (in seconds, default 300)
as used by the purge() method

=item granularity

the time granularity for intermediate directories, see L</DIRECTORY STRUCTURE>
(default: 60)

=back

=head1 METHODS

The following methods are available:

=over

=item new()

return a new Directory::Queue::Simple object (class method)

=item copy()

return a copy of the object; this can be useful to have independent iterators
on the same queue

=item path()

return the queue toplevel path

=item id()

return a unique identifier for the queue

=item count()

return the number of elements in the queue

=item first()

return the first element in the queue, resetting the iterator;
return an empty string if the queue is empty

=item next()

return the next element in the queue, incrementing the iterator;
return an empty string if there is no next element

=item add(DATA)

add the given data (a binary string) to the queue and return the corresponding
element name

=item add_ref(REF)

add the given data (a reference to a binary string) to the queue and return
the corresponding element name, this can avoid string copies with large
strings

=item add_path(PATH)

add the given file (identified by its path) to the queue and return the
corresponding element name, the file must be on the same filesystem and will
be moved to the queue

=item lock(ELEMENT[, PERMISSIVE])

attempt to lock the given element and return true on success; if the
PERMISSIVE option is true (which is the default), it is not a fatal error if
the element cannot be locked and false is returned

=item unlock(ELEMENT[, PERMISSIVE])

attempt to unlock the given element and return true on success; if the
PERMISSIVE option is true (which is I<not> the default), it is not a fatal
error if the element cannot be unlocked and false is returned

=item touch(ELEMENT)

update the access and modification times on the element's file to indicate
that it is still being used; this is useful for elements that are locked for
long periods of time (see the purge() method)

=item remove(ELEMENT)

remove the given element (which must be locked) from the queue

=item get(ELEMENT)

get the data from the given element (which must be locked) and return a binary
string

=item get_ref(ELEMENT)

get the data from the given element (which must be locked) and return a
reference to a binary string, this can avoid string copies with large strings

=item get_path(ELEMENT)

get the file path of the given element (which must be locked), this file can
be read but not removed, you must use the remove() method for this

=item purge([OPTIONS])

purge the queue by removing unused intermediate directories, removing too old
temporary elements and unlocking too old locked elements (aka staled locks);
note: this can take a long time on queues with many elements; OPTIONS can be:

=over

=item maxtemp

maximum time for a temporary element (in seconds);
if set to 0, temporary elements will not be removed

=item maxlock

maximum time for a locked element (in seconds);
if set to 0, locked elements will not be unlocked

=back

=back

=head1 DIRECTORY STRUCTURE

The toplevel directory contains intermediate directories that contain the
stored elements, each of them in a file.

The names of the intermediate directories are time based: the element
insertion time is used to create a 8-digits long hexadecimal number. The
granularity (see the new() method) is used to limit the number of new
directories. For instance, with a granularity of 60 (the default), new
directories will be created at most once per minute.

Since there is usually a filesystem limit in the number of directories a
directory can hold, there is a trade-off to be made. If you want to support
many added elements per second, you should use a low granularity to keep small
directories. However, in this case, you will create many directories and this
will limit the total number of elements you can store.

The elements themselves are stored in files (one per element) with a 14-digits
long hexadecimal name I<SSSSSSSSMMMMMR> where:

=over

=item I<SSSSSSSS>

represents the number of seconds since the Epoch

=item I<MMMMM>

represents the microsecond part of the time since the Epoch

=item I<R>

is a random hexadecimal digit used to reduce name collisions

=back

A temporary element (being added to the queue) will have a C<.tmp> suffix.

A locked element will have a hard link with the same name and the C<.lck>
suffix.

=head1 SEE ALSO

L<Directory::Queue>.

=head1 AUTHOR

Lionel Cons L<http://cern.ch/lionel.cons>

Copyright (C) CERN 2010-2021
