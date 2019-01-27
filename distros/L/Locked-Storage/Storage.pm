package Locked::Storage;

use strict;
use vars qw($VERSION @ISA);

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);
$VERSION = "1.00";

bootstrap Locked::Storage $VERSION;


1

__END__

=head1 NAME

Locked::Storage - A locked in RAM memory region

=head1 SYNOPSIS

    use Locked::Storage;

    $a = new Locked::Storage $nPages;

    $a->store($data, $length);
    print $a->get();

    $a->lockall();
    $a->unlockall();

    $a->dump();

=head1 DESCRIPTION

C<Locked::Storage> implements a set of calls to mlock(), munlock()
mlockall() and munlockall().;
On new() It allocates memory pages specified and will lock them,
into RAM (preventing them from going to swap memory.).

This module was written for secure(ish) storage  purposes
like you would use in cryptographic routines particularly those
manipulating private keys.

lockall/unlockall is available to lock the entire process
instead of just a memory region however it could easily fail due
   system constraints so locking the region in the constructor
is always enabled.  unlockall will unlock the process and
immediately relock the memory reserved in the constructor.

=head1 METHODS

=over 4

=item I<$a> = C<new> C<Locked::Storage> I<$nPages>

Creates and returns a new C<Locked::Storage> object.
$nPages specifies the number of pages to be allocated and
locked on return.

=item I<$a>->C<store>(I<$data>, I<$length>)

Stores the data in the allocated storage of length.  $data
can be of any type, however it will be truncated at $length
if the length is longer.  If the storage is insufficient
0 (zero) will be returned, otherwise 1 (one) is returned.

=item I<$a>->C<get>()

Returns the data as a scalar string.

=item I<$a>->C<lockall>()

Will lock the entire process in RAM, on error will croak.

=item I<$a>->C<unlockall>()

Will unlock the process from RAM (if locked) and immediately
relock the preallocted memory.

=item I<$a>->C<dump>()

Will return a hexdump of the memory allocated.

=back

=head1 WARNING

unlockall() known nothing of other mlock() calls except those in
its own constructor, so if you have multiple instances and you
call unlockall() it will unlock the regions in those instances
and they will not be relocked.  It is recommended that you either
rely on lockall()/unlockall() or the internal locked storage but
not both.

When using this module for cryptography you should undef everything
in the same function if possible and overwrite each scalar
immediately to prevent the memory being put back into the pool
unwiped and therefore defeating the whole purpose of locking
the sensitive data in memory.

=head1 BUGS

Various failures in the C libraries are not checked.  Particularly
C<ENOMEM> where there isn't enough system memory to allow the
process or pages to be locked to RAM.

=head1 AUTHOR

Michelle Sullivan, cpan@sorbs.net

=head1 SEE ALSO

perl(1), mlock(2), munlock(2), munlockall(2), mlockall(2)

=cut

