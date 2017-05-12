package File::Lock::Multi;

use 5.006000;
use strict;
use warnings (FATAL => 'all');
use File::Lock::Multi::Base;
use base q(File::Lock::Multi::Base);

our $VERSION = '1.02';

return 1;

__END__

=pod

=head1 NAME

File::Lock::Multi - Lock files more than once

=head1 SYNOPSIS

  use File::Lock::Multi::Fuser;

  my $lock = File::Lock::Multi::Fuser->new(name => "/path/to/file", max => 3);

  $lock->lock or die;
  # no more than 3 locks have been taken out on "/path/to/file"
  [...]

=head1 DESCRIPTION

L<flock()|perlfunc/flock> (and co-operative locks in general) are a handy
tool used for various synchronization tasks;

=over

=item ensuring a daemon/process may only have one copy running at once

=item "waiting in line" for your turn to write to a file

=item flagging that a certain process, or a certain part of a process is running

=item etc...

=back

POSIX supports the concept of "exclusive" ("write") and "shared" ("read")
locks on files -- many processes may take out a "shared" lock on any
particular file, but only one process may have an "exclusive" lock, and that
process can not take out this lock unless there are no "shared" locks
open.

Part of what makes this such an effective and worry-free system, is that
these locks are maintained on the kernel level -- so if you kill off a
process, you do not need to be concerned that the locks it had will stick
around and get in some other process's way.

... But let's say you have a CPU-intensive operation that you want to limit
to, oh, 5 running copies at a time? Or 3 different types of CPU-intensive
operation that you want to collectively limit to 2 running copies at a time?
You could keep a counter somewhere, but if processes are killed off manually,
what is going to come along and decrement your counter?

"exclusive" locks are just that -- exclusive -- and there is no simple way
to tell how many processes have taken out a "shared" lock on a file (from
perl, anyway).

C<File::Lock::Multi> is designed to work around this problem by providing
it's own type of "locks" that behave like POSIX "exclusive" locks, except
that you can specify how many locks are allowed to be taken out. So long
as each process agrees on the maximum number of locks, they can work in
parallel, but within the limits you have specified.

There are three locking mechanisms available; L<File::Lock::Multi::Fuser>
allows you to have multi-locks using just one file, but only works on linux
and has some drawbacks (see the documentation for details);
L<File::Lock::Multi::FlockFiles> uses the C<flock()> call on several files
named after the file you specify in order to emulate allowing more than one
lock. L<File::Lock::Multi::MySQL> allows you to use a MySQL backend to
take out multiple locks on a resource that is shared across multiple servers,
using MySQL's GET_LOCK function.

=head1 CONSTRUCTOR

=over

=item new(param => 'value', ...)

Creates a new C<File::Lock::Multi> object, which will represent a lock
on a file. Once you have an object, you can attempt to aquire a lock
with the "lock" method; the lock will be relinquished when you call
the "release" method, or when the object falls out of scope.

Note that you cannot call new directly on C<File::Lock::Multi>, you
must do so on a particular implementation such as
L<File::Lock::Multi::Fuser> or L<File::Lock::Multi::MySQL>

"new" takes the following parameters; only "file" is required:

=over

=item name

The name of the resource you wish to lock; this parameter is required.
When dealing with files, if the file does not already exist, a zero-byte
file will be created when you attempt to acquire the lock with L</lock>.

This parameter is required.

=item max

The maximum number of lockers that may lock this file.

Default: 1

=item timeout

How long to wait to acquire the lock, in seconds. A value of zero means
don't wait at all, and a negative value means to wait forever (block).

Default: -1 (wait forever).

=item polling_interval

How often to check if the lock is available when waiting, in seconds.
For example, if "timeout" was set to "5", and "polling_interval" was
set to "0.5", C<File::Lock::Multi> would try to obtain the lock
every half a second, up to a maximum of five seconds, before giving up.

Default: 0.2 (1/5th of a second).

=back

=back

=head1 METHODS

=over

=item lock([$timeout])

Acquire a lock, obeying L</timeout> and L</polling_interval> above.
Returns a true value on success, or a false value if the the lock
could not be acquired in time.

This method actually works by taking out the lock anyway, and then
checking if there are too many lockers -- if there are too many lockers,
it releases the lock, and optionally waits for L</polling_interval> and
tries again.

If C<$timeout> is specified, this overrides the object's default.

=item lockable

Returns a true value if an attempt to take out the lock would succeed.
This method works by calling L</lock> with a timeout of zero (non-blocking),
then immediately releases the lock if it obtained one.

=item locked

Returns true if this lock is active, false otherwise.

=item release

Release a lock if we have taken one out. Raises an exception if we
have not.

=item lockers

Returns an array with an entry for each entity that has locked this
file. Presumedly each entry in the array is some sort of identifier
indicating _who_ has locked this file, but that would be implementation
specific. :-)

=back

=head1 LICENSE

Copyright 2010 Tyler "Crackerjack" MacDonald <japh@crackerjack.net>

This is free software; You may distribute it under the same terms as perl
itself.

=head1 SEE ALSO

L<File::Lock::Multi::Fuser> for technical details about the linux /proc
implementation.

L<File::Lock::Multi::FlockFiles> for technical details about the
multiple-file implementation.

l<File::Lock::Multi::MySQL> for technical details about the MySQL
implementation.

L<IPC::Locker> for a network-based locking solution that may help if
you don't want to use MySQL for distributed locking ("Multiple locks may
be requested, in which case the first lock to be free will be used.")

=cut

