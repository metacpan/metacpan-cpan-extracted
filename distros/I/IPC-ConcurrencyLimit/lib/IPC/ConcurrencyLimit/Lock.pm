package IPC::ConcurrencyLimit::Lock;
use 5.008001;
use strict;
use warnings;

our $VERSION = '0.17';
sub id { $_[0]->{id} }

sub heartbeat { 1 }

1;

__END__


=head1 NAME

IPC::ConcurrencyLimit::Lock - Simple base class for lock implementations

=head1 SYNOPSIS

  use IPC::ConcurrencyLimit;

=head1 DESCRIPTION

Very simple base class for locks defining a common interface.

If you are just looking to use L<IPC::ConcurrencyLimit>,
you don't need this.

=head1 METHODS

=head2 new

Constructor that acquires a new lock and
returns undef on failure to acquire a lock.

Needs to be implemented in the subclass.

First argument is a hash reference containing
options including at least C<max_procs>
which indicates the maximum number of locks
at the same time.

I<Note to implementors:> Copy the hash if you need to store it.

=head2 DESTROY

The destructor (none implemented in the base class)
needs to release the lock.

=head2 id

Returns the id of the lock (starting at 1, not 0).

=head2 heartbeat

When called, must return whether the lock is still valid.
By default, this just returns true unless overridden in
subclasses.

=head1 AUTHOR

Steffen Mueller, C<smueller@cpan.org>

Yves Orton

=head1 ACKNOWLEDGMENT

This module was originally developed for booking.com.
With approval from booking.com, this module was generalized
and put on CPAN, for which the authors would like to express
their gratitude.

=head1 COPYRIGHT AND LICENSE

 (C) 2011, 2012 Steffen Mueller. All rights reserved.
 
 This code is available under the same license as Perl version
 5.8.1 or higher.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

