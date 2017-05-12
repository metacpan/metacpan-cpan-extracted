#
# Fuse::Class
#
# For implementation using class.
#

package Fuse::Class;

use warnings;
use strict;

=head1 NAME

Fuse::Class - Base clsas for Fuse module implementation using class.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

Fuse::Class is just a abstract class. First, you must write subclass
overriding methods like named 'getattr'. (callbacks defined in Fuse)

Subclass will be written like following:

    package SampleFS;

    use base qw(Fuse::Class);

    sub getattr {
        my $self = shift; # instance or class is passed as first argment.
        my ($fname) = @_; # same as Fuse.
    
        ...

        return @attr; # same as Fuse.
    }
        ...

To mount your filesystem:

   use SampleFS;

   my $fuse = SampleFS->new("your", "parameters", "here");
   $fuse->main(mountpoint => '/mnt/sample', mountopts => "allow_other");

   # control will be not returned until file system is unmouted...

When file on your filesystem is opened, it will be seen that method
is called like this:

  $fuse->open($path_name, $flags, $file_info);

=head1 DESCRIPTION

This module supports writing Fuse callback as method.
Method name is same as Fuse callback, but first argment is an object (it's named '$self' usually).

This is a small change for Fuse, but you can use power of OO like
inheritance, encapsulation, ...

Exception handling:

Returned value will be treated as negative errno in Fuse way, but you can
use exception, too.
If exception is thrown in your method ("die" is called), $! will be used
as errno to notify error to Fuse.


=head1 EXPORT

Nothing.

=head1 CONSTRUCTOR

=cut

use Fuse;
use Errno;

# instance calling main
use vars qw($_Module);

=head2 new

Create a new instance. This method is defined just for your convenience.
Default implementation returns blessed empty HASHREF.

=cut

#
# for your convenience.
#
sub new {
    my $class = shift;
    bless {}, $class;
}

my @callback;

=head1 METHODS

=cut

=head2 main(OPT_KEY1 => OPT_VALUE1, OPT_KEY2 => OPT_VALUE2, ...)

Start a main loop. Filesystem is mounted to the mountpoint pointed by
option "mountpoint".

Options are taken as key=>value pair selected from following:

=over

=item debug => boolean

This option controls tracing on or off. (Default is off).

=item mountpoint => "path_to_mountpoint"

Directory name to mount filesystem like "/mnt/mypoint".
This option has no default value and is mandatory.

=item mountopts => "opt1,op2,..."

Comma separated options for FUSE kernel module.

=item nullpath_ok => boolean

If true, empty pathname is passed to the methods like read, write, flush,
release, fsync, readdir, releasedir, fsyncdir, ftruncate, fgetattr and lock.

To use this option, you must return file/directory handle from
open, opendir and create, and you must operate file/directory by
that handle insted of pathname.

Only effective on Fuse 2.8 or later.

=back

For more information, see the documentation of Fuse.

=cut

sub main {
    my $self = shift;
    my %attr = @_;

    my @args;
    for my $opt (qw(debug mountpoint mountopts nullpath_ok)) {
	push(@args, $opt, $attr{$opt}) if (defined($attr{$opt}));
    }

    local $_Module = $self;

    my %fnmap;
    foreach my $fnname (@callback) {
        if ($_Module->can($fnname)) {
            $fnmap{$fnname} = __PACKAGE__ . '::_' . $fnname;
        }
    }

    Fuse::main(@args, %fnmap);
}

BEGIN {
    @callback = qw (getattr readlink getdir mknod mkdir unlink
		    rmdir symlink rename link chmod chown truncate
		    utime open read write statfs flush release fsync
		    setxattr getxattr listxattr removexattr);
    if (Fuse->can('fuse_version')) {
        my $fuse_version = Fuse::fuse_version();
        if ($fuse_version >= 2.3) {
            push(@callback, qw(opendir readdir releasedir fsyncdir init destroy));
        }
        if ($fuse_version >= 2.5) {
            push(@callback, qw(access create ftruncate fgetattr));
        }
        if ($fuse_version >= 2.6) {
            push(@callback, qw(lock utimens bmap));
        }
    }

    no strict "refs";
    for my $m (@callback) {
	my $method = __PACKAGE__ . "::_$m";

	*$method = sub {
	    my $method_name = $m;

	    if ($_Module->can($method_name)) {
		my @ret = eval {
		    $_Module->$m(@_);
		};
		if ($@) {
		  return $! ? -$! : -Errno::EPERM();
		}
		else {
		  return (wantarray() ? @ret : $ret[0]);
		}
	    }
	    else {
		return -Errno::EPERM();
	    }
	}
    }
}

=head1 METHODS MAY BE OVERRIDDEN

=cut

=head2 getattr(PATH_NAME)

Return a list of file attributes. Meaning of fields are same as
"stat" function like this:

  ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
   $atime,$mtime,$ctime,$blksize,$blocks)

On error, return scalar value like -ENOENT().

=head2 readlink(PATH_NAME)

This method is called to dereference symbolic link.
Return a destination path string or numeric error value.

By Default implementation, returns -ENOENT().
You can leave this method if your FS does not have symlink.

=cut

sub readlink {
    return -Errno::ENOENT();
}

=head2 getdir(DIRECTORY_NAME)

Return a list of file/directory names and an errno (0 if success).
ex: ('..', '.', 'a', 'b', 0)

If 'readdir' method is implemented, this function will never be called.

=head2 mknod(PATH_NAME, MODE, DEVNO)

Return an errno (0 if success).
This method is called to create an entity (device or file).

=head2 mkdir(DIRECTORY_NAME, MODE)

Return an errno (0 if success).
This method is called to create a directory.

=head2 unlink(PATH_NAME)

Return an errno (0 if success).
This method is called to remove an entity (device, file or symlink).

=head2 rmdir(PATH_NAME)

Return an errno (0 if success).
This method is called to remove a directory.

=head2 symlink(EXISTING_PATH_NAME, SYMLINK_NAME)

Return an errno (0 if success).
This method is called to create a symbolic link.

=head2 rename(OLD_NAME, NEW_NAME)

Return an errno (0 if success).
This method is called to rename/move a entity.

=head2 link(EXISTING_PATH_NAME, HADLINK_NAME)

Return an errno (0 if success).
This method is called to create a hard link.

=head2 chmod(PATH_NAME, MODE).

Return an errno (0 if success).
This method is called to change permissions on a entity.

=head2 chown(PATH_NAME, UID, GID).

Return an errno (0 if success).
This method is called to change ownership of a entity.

=head2 truncate(PATH_NAME, OFFSET).

Return an errno (0 if success).
This method is called to truncate a file at the given offset.

=head2 utime(PATH_NAME, ACCESS_TIME, MODIFIED_TIME).

Return an errno (0 if success).
This method is called to change atime/mtime on a entity.

=head2 open(PATH_NAME, FLAGS, FILE_INFO)

Return an errno, and a file handle (optional)

First style means like this:

  return 0; # success

and second one is following:

  return (0, $file_handle_you_made); # success and handle

FLAGS is an OR-combined value of flags (O_RDONLY, O_SYNC, etc).
FILE_INFO is a hashref.

Returned file handle will be passed to subsequent method call
to operate on opend file.

=head2 read(PATH_NAME, SIZE, OFFSET, FILE_HANDLE)

Return an errno, or string scalar of read data.

This method is called to read data (SIZE bytes)
at the given offset of opened file.

=head2 write(PATH_NAME, BUFFER, OFFSET, FILE_HANDLE)

Return a written byte size or an errno.

This method is called to write data (BUFFER)
at the given offset of opened file.

=head2 statfs

Return status of filesystem in one of follwing style:

=over

=item -ENOANO()

or

=item $namelen, $files, $files_free, $blocks, $blocks_avail, $blocksize

or

=item -ENOANO(), $namelen, $files, $files_free, $blocks, $blocks_avail, $blocksize

=back

=cut

sub statfs {
    return -Errno::ENOANO();
}

=head2 flush(PATH_NAME, FILE_HANDLE)

Return an errno (0 if success).
This method is called to synchronize any cached data.

=cut

sub flush {
    return 0;
}

=head2 release(PATH_NAME, FLAGS, FILE_HANDLE)

Return an errno (0 if success).

FLAGS is a same value passed when 'open' is called.

Called to indicate that there are no more references to the file and flags.

=cut

sub release {
    return 0;
}

=head2 fsync(PATH_NAME, DATA_SYNC, FILE_HANDLE)

Return an errno (0 if success).

Called to synchronize file contents.

DATA_SYNC indicates 'user data only'. If DATA_SYNC is non-zero,
only the user data should be synchronized. Otherwise synchronize
user and meta data.

=cut

sub fsync {
    return 0;
}

=head2 setxattr(PATH_NAME, ATTR_NAME, ATTR_VALUE, FLAGS)

FLAGS is OR-ed value of Fuse::XATTR_CREATE and Fuse::XATTR_REPLACE

Return an errno (0 if success).

This method is called to set extended attribute.

-EOPNOTSUPP means that setting the attribute is rejected.

If XATTR_CREATE is passed and the attribute already exists, return -EEXIST.

If XATTR_REPLACE is passed and the attribute does not exist, return -ENOATTR.

By default implementation, returns -EOPNOTSUPP.
You can leave this method if your FS does not have any extended attributes.

=cut

sub setxattr {
    return -Errno::EOPNOTSUPP();
}

=head2 getxattr(PATH_NAME, ATTR_NAME)

Return attribute value or errno (0 if no value).

This method is called to get extended attribute value.

By default implementation, returns 0.
You can leave this method if your FS does not have any extended attributes.

=cut

sub getxattr {
    return 0;
}

=head2 listxattr(PATH_NAME)

Return a list of attribute names and an errno (0 if success).
ex: ('attr1', 'attr2', 'attr3', 0)

By default implementation, returns 0.
You can leave this method if your FS does not have any extended attributes.

=cut

sub listxattr {
    return 0;
}

=head2 removexattr(PATH_NAME, ATTR_NAME)

Return an errno (0 if success).

This method is called to remove an attribute from entity.

By default implementation, returns 0.
You can leave this method if your FS does not have any extended attributes.

=cut

sub removexattr {
    return 0;
}

=head2 opendir(DIRECTORY_NAME)

Return an errno, and a directory handle (optional).

This method is called to open a directory for reading.
If special handling is required to open a directory, this method
can be implemented.

Supported by Fuse version 2.3 or later.

=cut

# sub opendir {
#     return -Errno::EOPNOTSUPP();
# }

=head2 readdir(DIRECTORY_NAME, OFFSET, HANDLE)

(HANDLE is optional. see opendir)

Return list consists of entries and an errno. Most simple style is
same as getdir(). ex: ('..', '.', 'a', 'b', 0)

Entry can be array ref containing offset and attributes in following way:

    ([1, '..'], [2, '.'], [3, 'a'], [4, 'b', ], 0)

or
    ([1, '..', [array_like_getattr]], [2, '.', [array_like_getattr]], 0)


Supported by Fuse version 2.3 or later.

=cut

# sub readdir {
#     return -Errno::EOPNOTSUPP();
# }

=head2 releasedir(DIRECTORY_NAME, HANDLE)

(HANDLE is optional. see opendir)

Return an errno (0 if success).

Called to indicate that there are no more references to the opened directory.

Supported by Fuse version 2.3 or later.

=cut

=head2 fsyncdir(DIRECTORY_NAME, FLAGS, HANDLE)

(HANDLE is optional. see opendir)

Return an errno (0 if success).
This method is called to synchronize user data (FLAG is non-zero value)
or user data and meta data in directory.

Supported by Fuse version 2.3 or later.

=cut

=head2 init

You can return scalar. It can be accessed using fuse_get_context().

Supported by Fuse version 2.3 or later.

=cut

=head2 destroy(SCALAR_VALUE)

(SCALAR_VALUE is returned value by init method)

Supported by Fuse version 2.3 or later.

=cut

=head2 access(PATH_NAME, ACCESS_MODE_FLAG)

Return an errno (0 if success).

This method is called to determine if user can access the file.
For more information, see Fuse document and manual for access(2).

Supported by Fuse version 2.5 or later.

=cut

=head2 create(PATH_NAME, MASK, MODE)

Return an errno, and a file handle (optional)

This method is called to create a file with MASK (like mknod)
and open it with MODE atomically. 
If this method is not implemented, mknod() and open() will be used.

Supported by Fuse version 2.5 or later.

=cut

=head2 ftruncate(PATH_NAME, OFFSET, FILE_HANDLE)

(HANDLE is optional. see open)

Return an errno (0 if success).
This method is called to truncate an opened file at the given offset.

Supported by Fuse version 2.5 or later.

=cut

=head2 fgetattr(PATH_NAME, FILE_HANDLE)

(HANDLE is optional. see open)

Return a list of file attributes like getattr().
This method is called to get attributes for opened file.

Supported by Fuse version 2.5 or later.

=cut

=head2 lock(PATH_NAME, COMMAND_CODE, LOCK_PARAMS, FILE_HANDLE)

(HANDLE is optional. see open)

Return an errno (0 if success).

This method is called to lock or unlock regions of file. Parameters
for locking is passed in LOCK_PARAMS as hashref.

For more information, see the documentation of Fuse.

Supported by Fuse version 2.6 or later.

=cut

=head2 utimens(PATH_NAME, ACCESS_TIME, MODIFIED_TIME)

Return an errno (0 if success).
This method is called to change atime/mtime on a entity.
(Time has a resolution in nanosecond.)

Supported by Fuse version 2.6 or later.

=cut

=head2 bmap(PATH_NAME, BLOCK_SIZE, BLOCK_NUMBER)

Return 0 and physical block numeber on success, otherwise errno.

This method is called to get physical block offset on block device.

For more information, see the documentation of Fuse.

Supported by Fuse version 2.6 or later.

=cut

=head1 AUTHOR

Toshimitsu FUJIWARA, C<< <tttfjw at gmail.com> >>

=head1 BUGS

Threading is not tested.

=head1 COPYRIGHT & LICENSE

Copyright 2008-2011 Toshimitsu FUJIWARA, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

Fuse

=cut

1; # End of xxx
