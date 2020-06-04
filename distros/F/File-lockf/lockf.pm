#
# File-Lockf version 0.20
#
# Paul Henson <henson@acm.org>
#
# Copyright (c) 1997,1998 Paul Henson -- see COPYRIGHT file for details
#

package File::lockf;

use strict;
use vars qw($VERSION @ISA @EXPORT);

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);

@EXPORT = qw();

$VERSION = '0.26';

bootstrap File::lockf $VERSION;

sub new {
    my ($class, $fh) = @_;
    my $self = {};

    $self->{fh} = $fh;

    bless($self, "File::lockf::lock_obj");

    return $self;
}

sub File::lockf::lock_obj::fh {
    my ($self) = @_;
    
    return $self->{fh};
}

sub File::lockf::lock_obj::lock {
    my ($self, $size) = @_;
    $size = 0 unless $size;
    
    return File::lockf::lock($self->{fh}, $size);
}

sub File::lockf::lock_obj::tlock {
    my ($self, $size) = @_;
    $size = 0 unless $size;
    
    return File::lockf::tlock($self->{fh}, $size);
}

sub File::lockf::lock_obj::ulock {
    my ($self, $size) = @_;
    $size = 0 unless $size;
    
    return File::lockf::ulock($self->{fh}, $size);
}

sub File::lockf::lock_obj::test {
    my ($self, $size) = @_;
    $size = 0 unless $size;
    
    return File::lockf::test($self->{fh}, $size);
}

sub File::lockf::lock_obj::slock {
    my ($self, $count, $delay, $size) = @_;
    $count = 5 unless $count;
    $delay = 2 unless $delay;
    $size = 0 unless $size;
    my $status = -1;
    my $index;

    for ($index = 0; $index < $count; $index++) {
	$status = File::lockf::tlock($self->{fh}, $size);
	return 0 if ($status == 0);
	sleep($delay);
    }
    
    return $status;
}


1;
__END__

=head1 NAME

File::lockf - Perl module interface to the lockf system call

=head1 SYNOPSIS

  use File::lockf;

=head1 DESCRIPTION

File-Lockf is an interface to the lockf system call. Perl supports the
flock system call natively, but that does not acquire network locks. Perl
also supports the fcntl system call, but that is somewhat ugly to
use. There are other locking modules available for Perl, but none of them
provided what I wanted -- a simple, clean interface to the lockf system
call, without any bells or whistles getting in the way.

File-Lockf contains four functions which map directly to the four modes of
lockf, and an OO wrapper class that encapulates the basic locking
functionality along with an additional utility method that iteratively
attempts to acquire a lock.

=head1 Lock functions

The following functions return 0 (zero) on success, and the system error
number from errno on failure. They each take an open file handle as the
first argument, and optionally a size parameter. Please see your system
lockf man page for more details about lockf functionality on your system.

=over 4

=item $status = File::lockf::lock(FH, size = 0)

This function maps to the F_LOCK mode of lockf.

=item $status = File::lockf::tlock(FH, size = 0)

This function maps to the F_TLOCK mode of lockf.

=item $status = File::lockf::ulock(FH, size = 0)

This function maps to the F_ULOCK mode of lockf.

=item $status = File::lockf::test(FH, size = 0)

This function maps to the F_TEST mode of lockf.

=back

=head1 OO wrapper

File-Lockf also provides a simple OO wrapper class around the locking
functionality, which allows you to create a lock object for a file handle
and then perform lock operations with it. All of the methods return 0
(zero) on success, and the system error number from errno on failure.

=over 4

=item $lock = new File::lockf(\*FH)

This function returns a new lock object bound to the given file
handle. Note that you need to pass a reference to the file handle
to the constructor, not the file handle itself.

=item $fh = $lock->fh()

This method returns the file handle associated with the lock object.

=item $status = $lock->lock(size = 0)

This method calls File::lockf::lock on the bound file handle.

=item $status = $lock->tlock(size = 0)

This method calls File::lockf::tlock on the bound file handle.

=item $status = $lock->ulock(size = 0)

This method calls File::lockf::ulock on the bound file handle.

=item $status = $lock->test(size = 0)

This method calls File::lockf::test on the bound file handle.

=item $status = $lock->slock(count = 5, delay = 2, size = 0)

This method will attempt to lock the bound file handle <count> times,
sleeping <delay> seconds after each try. It will return 0 if the lock
succeeded, or the system error number from errno if all attempts fail.

=back

=head1 AUTHOR

Paul Henson <henson@acm.org>

=head1 SEE ALSO

perl(1).

=cut
