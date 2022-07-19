#+##############################################################################
#                                                                              #
# File: Directory/Queue/Normal.pm                                              #
#                                                                              #
# Description: object oriented interface to a normal directory based queue     #
#                                                                              #
#-##############################################################################

#
# module definition
#

package Directory::Queue::Normal;
use strict;
use warnings;
our $VERSION  = "2.2";
our $REVISION = sprintf("%d.%02d", q$Revision: 1.16 $ =~ /(\d+)\.(\d+)/);

#
# used modules
#

use Directory::Queue qw(_create _name _touch /Regexp/ /special/);
use Encode qw(encode decode FB_CROAK LEAVE_SRC);
use No::Worries::Die qw(dief);
use No::Worries::File qw(file_read file_write);
use No::Worries::Stat qw(ST_MTIME ST_NLINK);
use No::Worries::Warn qw(warnf);
use POSIX qw(:errno_h);

#
# inheritance
#

our(@ISA) = qw(Directory::Queue);

#
# constants
#

# name of the directory holding temporary elements
use constant TEMPORARY_DIRECTORY => "temporary";

# name of the directory holding obsolete elements
use constant OBSOLETE_DIRECTORY => "obsolete";

# name of the directory indicating a locked element
use constant LOCKED_DIRECTORY => "locked";

#
# global variables
#

our(
    $_FileRegexp,     # regexp matching a file in an element directory
    %_Byte2Esc,       # byte to escape map
    %_Esc2Byte,       # escape to byte map
);

$_FileRegexp = qr/[0-9a-zA-Z]+/;
%_Byte2Esc   = ("\x5c" => "\\\\", "\x09" => "\\t", "\x0a" => "\\n");
%_Esc2Byte   = reverse(%_Byte2Esc);

#+++############################################################################
#                                                                              #
# Helper Functions                                                             #
#                                                                              #
#---############################################################################

#
# transform a hash of strings into a string (reference)
#
# note:
#  - the keys are sorted so that identical hashes yield to identical strings
#

sub _hash2string ($) {
    my($hash) = @_;
    my($value, $string);

    $string = "";
    foreach my $key (sort(keys(%{ $hash }))) {
        $value = $hash->{$key};
        dief("undefined hash value: %s", $key) unless defined($value);
        dief("invalid hash scalar: %s", $value) if ref($value);
        $key   =~ s/([\x5c\x09\x0a])/$_Byte2Esc{$1}/g;
        $value =~ s/([\x5c\x09\x0a])/$_Byte2Esc{$1}/g;
        $string .= $key . "\x09" . $value . "\x0a";
    }
    return(\$string);
}

#
# transform a string (reference) into a hash of strings
#
# note:
#  - duplicate keys are not checked (the last one wins)
#

sub _string2hash ($) {
    my($stringref) = @_;
    my($key, $value, %hash);

    foreach my $line (split(/\x0a/, ${ $stringref })) {
        if ($line =~ /^([^\x09\x0a]*)\x09([^\x09\x0a]*)$/o) {
            ($key, $value) = ($1, $2);
        } else {
            dief("unexpected hash line: %s", $line);
        }
        $key   =~ s/(\\[\\tn])/$_Esc2Byte{$1}/g;
        $value =~ s/(\\[\\tn])/$_Esc2Byte{$1}/g;
        $hash{$key} = $value;
    }
    return(\%hash);
}

#
# check if a path is old enough:
#  - return true if the path exists and is (strictly) older than the given time
#  - return false if it does not exist or it is newer
#  - die in case of any other error
#
# note:
#  - lstat() is used so symlinks are not followed
#

sub _older ($$) {
    my($path, $time) = @_;
    my(@stat);

    @stat = lstat($path);
    unless (@stat) {
        dief("cannot lstat(%s): %s", $path, $!) unless $! == ENOENT;
        # RACE: this path does not exist (anymore)
        return(0);
    }
    return($stat[ST_MTIME] < $time);
}

#
# count the number of sub-directories in the given directory:
#  - return undef if the directory does not exist (anymore)
#  - die in case of any other error
#

# stat version (faster):
#  - lstat() is used so symlinks are not followed
#  - this only checks the number of hard links
#  - we do not even check that the given path indeed points to a directory!
#  - this will return incorrect results on some filesystems like DOS or Btrfs

sub _subdirs_stat ($) {
    my($path) = @_;
    my(@stat);

    @stat = lstat($path);
    unless (@stat) {
        dief("cannot lstat(%s): %s", $path, $!) unless $! == ENOENT;
        # RACE: this path does not exist (anymore)
        return();
    }
    return($stat[ST_NLINK] - 2);
}

# readdir version (slower):
#  - we really count the number of entries
#  - we however do not check that these entries are themselves indeed directories
#  - this is the default method to favor correctness over speed

sub _subdirs_readdir ($) {
    my($path) = @_;

    return(scalar(_special_getdir($path)));
}

#
# wrapper method
#

sub _subdirs ($$) {
    my($self, $path) = @_;

    return($self->{nlink} ? _subdirs_stat($path) : _subdirs_readdir($path));
}

#
# check the given string to make sure it represents a valid element name
#

sub _check_element ($) {
    my($element) = @_;

    dief("invalid element: %s", $element)
        unless $element =~ m/^(?:$_DirectoryRegexp)\/(?:$_ElementRegexp)$/o;
}

#+++############################################################################
#                                                                              #
# Object Oriented Interface                                                    #
#                                                                              #
#---############################################################################

#
# object constructor
#

sub new : method {
    my($class, %option) = @_;
    my($self, $path, $options);

    # default object
    $self = __PACKAGE__->SUPER::_new(%option);
    foreach my $name (qw(path maxlock maxtemp rndhex umask)) {
        delete($option{$name});
    }
    # default options
    $self->{maxelts} = 16_000; # maximum number of elements per directory
    # check maxelts
    if (defined($option{maxelts})) {
        dief("invalid maxelts: %s", $option{maxelts})
            unless $option{maxelts} =~ /^\d+$/ and $option{maxelts} > 0;
        $self->{maxelts} = delete($option{maxelts});
    }
    # check nlink
    $self->{nlink} = delete($option{nlink});
    # check schema
    if (defined($option{schema})) {
        dief("invalid schema: %s", $option{schema})
            unless ref($option{schema}) eq "HASH";
        foreach my $name (keys(%{ $option{schema} })) {
            dief("invalid schema name: %s", $name)
                unless $name =~ /^($_FileRegexp)$/
                   and $name ne LOCKED_DIRECTORY;
            if ($option{schema}{$name} =~
                /^(binary|string|table)([\?\*]{0,2})$/) {
                $self->{type}{$name} = $1;
                $options = $2;
            } else {
                dief("invalid schema type: %s", $option{schema}{$name});
            }
            $self->{mandatory}{$name} = 1 unless $options =~ /\?/;
            $self->{ref}{$name} = 1 if $options =~ /\*/;
            dief("invalid schema type: %s", $option{schema}{$name})
                if $self->{type}{$name} eq "table" and $self->{ref}{$name};
        }
        dief("invalid schema: no mandatory data")
            unless $self->{mandatory};
        delete($option{schema});
    }
    # check unexpected options
    foreach my $name (keys(%option)) {
        dief("unexpected option: %s", $name);
    }
    # create directories
    foreach my $name (TEMPORARY_DIRECTORY, OBSOLETE_DIRECTORY) {
        $path = $self->{path}."/".$name;
        _special_mkdir($path, $self->{umask}) unless -d $path;
    }
    # so far so good...
    return($self);
}

#
# return the number of elements in the queue, regardless of their state
#

sub count : method {
    my($self) = @_;
    my($count, @list, $subdirs);

    $count = 0;
    # get the list of existing directories
    foreach my $name (_special_getdir($self->{path}, "strict")) {
        push(@list, $1) if $name =~ /^($_DirectoryRegexp)$/o; # untaint
    }
    # count sub-directories
    foreach my $name (@list) {
        $subdirs = _subdirs($self, $self->{path}."/".$name);
        $count += $subdirs if $subdirs;
    }
    # that's all
    return($count);
}

#
# check if an element is locked:
#  - this is best effort only as it may change while we test (only locking is atomic)
#  - if given a time, only return true on locks older than this time (needed by purge)
#

sub _is_locked ($$;$) {
    my($self, $name, $time) = @_;
    my($path, @stat);

    $path = $self->{path}."/".$name;
    return(0) unless -d $path."/".LOCKED_DIRECTORY;
    return(1) unless defined($time);
    @stat = lstat($path);
    unless (@stat) {
        dief("cannot lstat(%s): %s", $path, $!) unless $! == ENOENT;
        # RACE: this path does not exist (anymore)
        return(0);
    }
    return($stat[ST_MTIME] < $time);
}

#
# lock an element:
#  - return true on success
#  - return false in case the element could not be locked (in permissive mode)
#
# note:
#  - locking can fail:
#     - if the element has been locked by somebody else (EEXIST)
#     - if the element has been removed by somebody else (ENOENT)
#  - if the optional second argument is true, it is not an error if
#    the element cannot be locked (= permissive mode), this is the default
#    as one usually cannot be sure that nobody else will try to lock it
#  - the directory's mtime will change automatically (after a successful mkdir()),
#    this will later be used to detect stalled locks
#

sub lock : method { ## no critic 'ProhibitBuiltinHomonyms'
    my($self, $element, $permissive) = @_;
    my($path, $oldumask, $success);

    _check_element($element);
    $permissive = 1 unless defined($permissive);
    $path = $self->{path}."/".$element."/".LOCKED_DIRECTORY;
    if (defined($self->{umask})) {
        $oldumask = umask($self->{umask});
        $success = mkdir($path);
        umask($oldumask);
    } else {
        $success = mkdir($path);
    }
    unless ($success) {
        if ($permissive) {
            # RACE: the locked directory already exists
            return(0) if $! == EEXIST;
            # RACE: the element directory does not exist anymore
            return(0) if $! == ENOENT;
        }
        # otherwise this is unexpected...
        dief("cannot mkdir(%s): %s", $path, $!);
    }
    $path = $self->{path}."/".$element;
    unless (lstat($path)) {
        if ($permissive and $! == ENOENT) {
            # RACE: the element directory does not exist anymore
            # (this can happen if an other process locked & removed the element
            #  while our mkdir() was in progress... yes, this can happen!)
            return(0);
        }
        # otherwise this is unexpected...
        dief("cannot lstat(%s): %s", $path, $!);
    }
    # so far so good
    return(1);
}

#
# unlock an element:
#  - return true on success
#  - return false in case the element could not be unlocked (in permissive mode)
#
# note:
#  - unlocking can fail:
#     - if the element has been unlocked by somebody else (ENOENT)
#     - if the element has been removed by somebody else (ENOENT)
#  - if the optional second argument is true, it is not an error if
#    the element cannot be unlocked (= permissive mode), this is _not_ the default
#    as unlock() should normally be called by whoever locked the element
#

sub unlock : method {
    my($self, $element, $permissive) = @_;
    my($path);

    _check_element($element);
    $path = $self->{path}."/".$element."/".LOCKED_DIRECTORY;
    unless (rmdir($path)) {
        if ($permissive) {
            # RACE: the element directory or its lock does not exist anymore
            return(0) if $! == ENOENT;
        }
        # otherwise this is unexpected...
        dief("cannot rmdir(%s): %s", $path, $!);
    }
    # so far so good
    return(1);
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
    my($self, $element) = @_;
    my($temp, $path);

    _check_element($element);
    dief("cannot remove %s: not locked", $element)
        unless _is_locked($self, $element);
    # move the element out of its intermediate directory
    $path = $self->{path}."/".$element;
    while (1) {
        $temp = $self->{path}
           ."/".OBSOLETE_DIRECTORY
           ."/"._name($self->{rndhex});
        rename($path, $temp) and last;
        dief("cannot rename(%s, %s): %s", $path, $temp, $!)
            unless $! == ENOTEMPTY or $! == EEXIST;
        # RACE: the target directory was already present...
    }
    # remove the data files
    foreach my $name (_special_getdir($temp, "strict")) {
        next if $name eq LOCKED_DIRECTORY;
        if ($name =~ /^($_FileRegexp)$/o) {
            $path = $temp."/".$1; # untaint
        } else {
            dief("unexpected file in %s: %s", $temp, $name);
        }
        unlink($path) and next;
        dief("cannot unlink(%s): %s", $path, $!);
    }
    # remove the locked directory
    $path = $temp."/".LOCKED_DIRECTORY;
    while (1) {
        rmdir($path) or dief("cannot rmdir(%s): %s", $path, $!);
        rmdir($temp) and return;
        dief("cannot rmdir(%s): %s", $temp, $!)
            unless $! == ENOTEMPTY or $! == EEXIST;
        # RACE: this can happen if an other process managed to lock this element
        # while it was being removed (see the comment in the lock() method)
        # so we try to remove the lock again and again...
    }
}

#
# read a binary file and return a reference to the corresponding data
#

sub _file_read_bin ($) {
    my($path) = @_;
    my($data);

    file_read($path, data => \$data);
    return(\$data);
}

#
# read a UTF-8 encoded file and return a reference to the corresponding string
#

sub _file_read_utf8 ($) {
    my($path) = @_;
    my($data, $string);

    file_read($path, data => \$data);
    eval {
        local $SIG{__WARN__} = sub { die($_[0]) };
        $string = decode("UTF-8", $data, FB_CROAK);
    };
    return(\$string) unless $@;
    $@ =~ s/\s+at\s.+?\sline\s+\d+\.?$//;
    dief("cannot UTF-8 decode %s: %s", $path, $@);
}

#
# get an element from a locked element
#

sub get : method {
    my($self, $element) = @_;
    my(%data, $path, $ref);

    dief("unknown schema") unless $self->{type};
    _check_element($element);
    dief("cannot get %s: not locked", $element)
        unless _is_locked($self, $element);
    foreach my $name (keys(%{ $self->{type} })) {
        $path = "$self->{path}/$element/$name";
        unless (lstat($path)) {
            dief("cannot lstat(%s): %s", $path, $!) unless $! == ENOENT;
            if ($self->{mandatory}{$name}) {
                dief("missing data file: %s", $path);
            } else {
                next;
            }
        }
        if ($self->{type}{$name} =~ /^(binary|string)$/) {
            if ($self->{type}{$name} eq "string") {
                $ref = _file_read_utf8($path);
            } else {
                $ref = _file_read_bin($path);
            }
            $data{$name} = $self->{ref}{$name} ? $ref : ${ $ref };
        } elsif ($self->{type}{$name} eq "table") {
            $data{$name} = _string2hash(_file_read_utf8($path));
        } else {
            dief("unexpected data type: %s", $self->{type}{$name});
        }
    }
    return(\%data) unless wantarray();
    return(%data);
}

#
# return the name of the intermediate directory that can be used for insertion:
#  - if there is none, an initial one will be created
#  - if it is full, a new one will be created
#  - in any case the name will match $_DirectoryRegexp
#

sub _insertion_directory ($) {
    my($self) = @_;
    my(@list, $new, $subdirs);

    # get the list of existing directories
    foreach my $name (_special_getdir($self->{path}, "strict")) {
        push(@list, $1) if $name =~ /^($_DirectoryRegexp)$/o; # untaint
    }
    # handle the case with no directories yet
    unless (@list) {
        $new = sprintf("%08x", 0);
        _special_mkdir($self->{path}."/".$new, $self->{umask});
        return($new);
    }
    # check the last directory
    @list = sort(@list);
    $new = pop(@list);
    $subdirs = _subdirs($self, $self->{path}."/".$new);
    if (defined($subdirs)) {
        return($new) if $subdirs < $self->{maxelts};
        # this last directory is now full... create a new one
    } else {
        # RACE: at this point, the directory does not exist anymore, so it
        # must have been purged after we listed the directory contents...
        # we do not try to do more and simply create a new directory
    }
    # we need a new directory
    $new = sprintf("%08x", hex($new) + 1);
    _special_mkdir($self->{path}."/".$new, $self->{umask});
    return($new);
}

#
# add data to a directory
#

sub _add_data ($$$) {
    my($self, $data, $tempdir) = @_;
    my($ref, $utf8, $tmp, $path, $fh);

    foreach my $name (keys(%{ $data })) {
        dief("unexpected data: %s", $name) unless $self->{type}{$name};
        if ($self->{type}{$name} =~ /^(binary|string)$/) {
            if ($self->{ref}{$name}) {
                dief("unexpected %s data in %s: %s",
                     $self->{type}{$name}, $name, $data->{$name})
                    unless ref($data->{$name}) eq "SCALAR";
                $ref = $data->{$name};
            } else {
                dief("unexpected %s data in %s: %s",
                     $self->{type}{$name}, $name, $data->{$name})
                    if ref($data->{$name});
                $ref = \$data->{$name};
            }
            $utf8 = $self->{type}{$name} eq "string";
        } elsif ($self->{type}{$name} eq "table") {
            dief("unexpected %s data in %s: %s",
                 $self->{type}{$name}, $name, $data->{$name})
                unless ref($data->{$name}) eq "HASH";
            $ref = _hash2string($data->{$name});
            $utf8 = 1;
        } else {
            dief("unexpected data type in %s: %s",
                 $name, $self->{type}{$name});
        }
        if ($utf8) {
            eval {
                $tmp = encode("UTF-8", ${ $ref }, FB_CROAK|LEAVE_SRC);
            };
            if ($@) {
                $@ =~ s/\s+at\s.+?\sline\s+\d+\.?$//;
                dief("unexpected character in %s: %s", $name, $@);
            }
            $ref = \$tmp;
        }
        $path = "$tempdir/$name";
        $fh = _create($path, $self->{umask}, "strict");
        file_write($path, handle => $fh, data => $ref);
    }
}

#
# add a new element to the queue and return its name
#
# note:
#  - the destination directory must _not_ be created beforehand as it would
#    be seen as a valid (but empty) element directory by an other process,
#    we therefor use rename() from a temporary directory
#

sub add : method {
    my($self, @data) = @_;
    my($data, $tempdir, $dir, $new, $path, $ref, $utf8);

    dief("unknown schema") unless $self->{type};
    if (@data == 1) {
        $data = $data[0];
    } else {
        $data = { @data };
    }
    foreach my $name (keys(%{ $self->{mandatory} })) {
        dief("missing mandatory data: %s", $name)
            unless defined($data->{$name});
    }
    while (1) {
        $tempdir = $self->{path}
           ."/".TEMPORARY_DIRECTORY
           ."/"._name($self->{rndhex});
        last if _special_mkdir($tempdir, $self->{umask});
    }
    _add_data($self, $data, $tempdir);
    $dir = _insertion_directory($self);
    while (1) {
        $new = $dir."/"._name($self->{rndhex});
        $path = $self->{path}."/".$new;
        rename($tempdir, $path) and return($new);
        dief("cannot rename(%s, %s): %s", $tempdir, $path, $!)
            unless $! == ENOTEMPTY or $! == EEXIST;
        # RACE: the target directory was already present...
    }
}

#
# return the list of volatile (i.e. temporary or obsolete) directories
#

sub _volatile ($) {
    my($self) = @_;
    my(@list);

    foreach my $name (_special_getdir($self->{path} .
                                      "/" . TEMPORARY_DIRECTORY)) {
        push(@list, TEMPORARY_DIRECTORY."/".$1)
            if $name =~ /^($_ElementRegexp)$/o; # untaint
    }
    foreach my $name (_special_getdir($self->{path} .
                                      "/" . OBSOLETE_DIRECTORY)) {
        push(@list, OBSOLETE_DIRECTORY."/".$1)
            if $name =~ /^($_ElementRegexp)$/o; # untaint
    }
    return(@list);
}

#
# destroy a volatile directory
#

sub _destroy_dir ($) {
    my($dir) = @_;
    my($path);

    foreach my $name (_special_getdir($dir)) {
        next if $name eq LOCKED_DIRECTORY;
        $path = $dir."/".$name;
        unlink($path) and next;
        dief("cannot unlink(%s): %s", $path, $!) unless $! == ENOENT;
    }
    _special_rmdir($dir."/".LOCKED_DIRECTORY);
    _special_rmdir($dir);
}

#
# purge the queue:
#  - delete unused intermediate directories
#  - delete too old temporary directories
#  - unlock too old locked directories
#
# note: this uses first()/next() to iterate so this will reset the cursor
#

sub purge : method {
    my($self, %option) = @_;
    my(@list, $path, $subdirs, $oldtime, $locked);

    # check options
    $option{maxtemp} = $self->{maxtemp} unless defined($option{maxtemp});
    $option{maxlock} = $self->{maxlock} unless defined($option{maxlock});
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
    # try to purge all but the last intermediate directory
    if (@list > 1) {
        @list = sort(@list);
        pop(@list);
        foreach my $name (@list) {
            $path = $self->{path}."/".$name;
            $subdirs = _subdirs($self, $path);
            next if $subdirs or not defined($subdirs);
            _special_rmdir($path);
        }
    }
    # remove the volatile directories which are too old
    if ($option{maxtemp}) {
        $oldtime = time() - $option{maxtemp};
        foreach my $name (_volatile($self)) {
            $path = $self->{path}."/".$name;
            next unless _older($path, $oldtime);
            warnf("removing too old volatile element: %s", $name);
            _destroy_dir($path);
        }
    }
    # iterate to find abandoned locked entries
    if ($option{maxlock}) {
        $oldtime = time() - $option{maxlock};
        $locked = $self->first();
        while ($locked) {
            next unless _is_locked($self, $locked, $oldtime);
            warnf("removing too old locked element: %s", $locked);
            $self->unlock($locked, 1);
        } continue {
            $locked = $self->next();
        }
    }
}

1;

__END__

=head1 NAME

Directory::Queue::Normal - object oriented interface to a normal directory based queue

=head1 SYNOPSIS

  use Directory::Queue::Normal;

  #
  # simple schema:
  #  - there must be a "body" which is a string
  #  - there can be a "header" which is a table/hash
  #

  $schema = { "body" => "string", "header" => "table?" };
  $queuedir = "/tmp/test";

  #
  # sample producer
  #

  $dirq = Directory::Queue::Normal->new(path => $queuedir, schema => $schema);
  foreach $count (1 .. 100) {
      $name = $dirq->add(body => "element $count\n", header => \%ENV);
      printf("# added element %d as %s\n", $count, $name);
  }

  #
  # sample consumer (one pass only)
  #

  $dirq = Directory::Queue::Normal->new(path => $queuedir, schema => $schema);
  for ($name = $dirq->first(); $name; $name = $dirq->next()) {
      next unless $dirq->lock($name);
      printf("# reading element %s\n", $name);
      %data = $dirq->get($name);
      # one can use $data{body} and $data{header} here...
      # one could use $dirq->unlock($name) to only browse the queue...
      $dirq->remove($name);
  }

  #
  # looping consumer (sleeping to avoid using all CPU time)
  #

  $dirq = Directory::Queue::Normal->new(path => $queuedir, schema => $schema);
  while (1) {
      sleep(1) unless $dirq->count();
      for ($name = $dirq->first(); $name; $name = $dirq->next()) {
          ... same as above ...
      }
  }

=head1 DESCRIPTION

The goal of this module is to offer a "normal" (as opposed to "simple") queue
system using the underlying filesystem for storage, security and to prevent
race conditions via atomic operations.

It allows arbitrary data to be stored (see the L</SCHEMA> section for more
information) but it has a significant disk space and speed overhead.

Please refer to L<Directory::Queue> for general information about directory
queues.

=head1 CONSTRUCTOR

The new() method can be used to create a Directory::Queue::Normal object that
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

=item maxelts

the maximum number of elements that an intermediate directory can hold
(default: 16,000)

=item maxlock

default maximum time for a locked element (in seconds, default 600)
as used by the purge() method

=item maxtemp

default maximum time for a temporary element (in seconds, default 300)
as used by the purge() method

=item nlink

flag indicating that the "nlink optimization" (faster but only working on some
filesystems) will be used

=item schema

the schema defining how to interpret user supplied data
(mandatory if elements are added or read)

=back

=head1 SCHEMA

The schema defines how user supplied data is stored in the queue. It is only
required by the add() and get() methods.

The schema must be a reference to a hash containing key/value pairs.

The key must contain only alphanumerical characters. It identifies the piece
of data and will be used as file name when storing the data inside the element
directory.

The value represents the type of the given piece of data. It can be:

=over

=item binary

the data is a binary string (i.e. a sequence of bytes), it will be stored
directly in a plain file with no further encoding

=item string

the data is a text string (i.e. a sequence of characters), it will be UTF-8
encoded before being stored in a file

=item table

the data is a reference to a hash of text strings, it will be serialized and
UTF-8 encoded before being stored in a file

=back

By default, all pieces of data are mandatory. If you append a question mark to
the type, this piece of data will be marked as optional. See the comments in
the L</SYNOPSIS> section for an example.

By default, string or binary data is used directly. If you append an asterisk
to the type, the data that you add or get will be by reference. This can be
useful to avoid string copies of large amounts of data.

=head1 METHODS

The following methods are available:

=over

=item new()

return a new Directory::Queue::Normal object (class method)

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

add the given data (a hash or hash reference) to the queue and return the
corresponding element name; the schema must be known and the data must conform
to it

=item lock(ELEMENT[, PERMISSIVE])

attempt to lock the given element and return true on success; if the
PERMISSIVE option is true (which is the default), it is not a fatal error if
the element cannot be locked and false is returned

=item unlock(ELEMENT[, PERMISSIVE])

attempt to unlock the given element and return true on success; if the
PERMISSIVE option is true (which is I<not> the default), it is not a fatal
error if the element cannot be unlocked and false is returned

=item touch(ELEMENT)

update the access and modification times on the element's directory to
indicate that it is still being used; this is useful for elements that are
locked for long periods of time (see the purge() method)

=item remove(ELEMENT)

remove the given element (which must be locked) from the queue

=item get(ELEMENT)

get the data from the given element (which must be locked) and return
basically the same hash as what add() got (in list context, the hash is
returned directly while in scalar context, the hash reference is returned
instead); the schema must be knownand the data must conform to it

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

All the directories holding the elements and all the files holding the data
pieces are located under the queue toplevel directory. This directory can
contain:

=over

=item temporary

the directory holding temporary elements, i.e. the elements being added

=item obsolete

the directory holding obsolete elements, i.e. the elements being removed

=item I<NNNNNNNN>

an intermediate directory holding elements; I<NNNNNNNN> is an 8-digits long
hexadecimal number

=back

In any of the above directories, an element is stored as a single directory
with a 14-digits long hexadecimal name I<SSSSSSSSMMMMMR> where:

=over

=item I<SSSSSSSS>

represents the number of seconds since the Epoch

=item I<MMMMM>

represents the microsecond part of the time since the Epoch

=item I<R>

is a random hexadecimal digit used to reduce name collisions

=back

Finally, inside an element directory, the different pieces of data are stored
into different files, named according to the schema. A locked element contains
in addition a directory named C<locked>.

=head1 SEE ALSO

L<Directory::Queue>.

=head1 AUTHOR

Lionel Cons L<http://cern.ch/lionel.cons>

Copyright (C) CERN 2010-2022
