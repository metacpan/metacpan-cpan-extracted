package Devel::Malloc;

use 5.006;
use strict;
use Exporter 'import';
our @ISA = qw(Exporter);
our @EXPORT = qw(_malloc _memset _memget _free __sync_store_sv __sync_load_sv
    __sync_add_and_fetch __sync_sub_and_fetch __sync_and_and_fetch __sync_or_and_fetch __sync_xor_and_fetch __sync_nand_and_fetch
    __sync_fetch_and_add __sync_fetch_and_sub __sync_fetch_and_and __sync_fetch_and_or __sync_fetch_and_xor __sync_fetch_and_nand
    __sync_lock_test_and_set __sync_lock_release __sync_synchronize __sync_bool_compare_and_swap __sync_val_compare_and_swap
    );
our $VERSION = '0.03';

require XSLoader;
XSLoader::load('Devel::Malloc', $VERSION);

1;
__END__

=head1 NAME

Devel::Malloc - Low-level memory and atomic operations for real-time inter-thread communication.

=head1 SYNOPSIS MALLOC

 use warnings;
 use strict;
 use POSIX;
 use POSIX::RT::Signal qw(sigwaitinfo sigqueue);
 use Devel::Malloc;
 use threads;

 POSIX::sigprocmask(POSIX::SIG_BLOCK, POSIX::SigSet->new(&POSIX::SIGRTMIN));
 my $thr = threads->create(\&_thread);

 sub _thread
 {
    my $sigset = POSIX::SigSet->new(&POSIX::SIGRTMIN);
    my $info=sigwaitinfo($sigset);
    my $str = _memget($info->{value}, 4);
    print $str."\n";
    _free($info->{value});
 }

 my $address = _malloc(4);
 _memset($address, "TEST", 4);
 sigqueue($$, &POSIX::SIGRTMIN, $address);
 $thr->join();

=head1 SYNOPSIS ATOMIC

 use Devel::Malloc;

 # allocate mutex memory
 my $mutex = _malloc(1);
 if ($mutex)
 {
    # mutex init
    __sync_and_and_fetch($mutex, 0, 1);

    for (1..10)
    {
        # lock mutex
        while (__sync_lock_test_and_set($mutex, 1, 1) == 1) { }

        # critical section here

        # unlock mutex
        __sync_lock_release($mutex, 1);
    }

    # free mutex memory
    _free($address);
 }

=head1 DESCRIPTION

The _malloc() function allocates size bytes and returns memory address
to the allocated memory. You can store bytes to memory using _memset() and
retrieve them using _memget(). The _free() function deallocates memory.

Memory address returned by _malloc() can be used between threads.

Also you can store short byte arrays or unsigned integers using
atomic opetaions.

For SV atomic operations $size must be from 1 to 8 (store/load).
For IV atomic operations $size must be 1, 2, 4 or 8 if your sizeof(IV) == 8.

I hope you enjoyed it.

=head2 EXPORT GENERAL FUNCTIONS

 $address = _malloc(size);
 
 $address = _memset($address, $sv, $size = 0);
 
 $sv = _memget($address, $size);
 
 _free($address);

=head2 EXPORT ATOMIC FUCTIONS

 __sync_store_sv($address, $sv, $size = 0)
 
 $sv = __sync_load_sv($address, $size);
 
 $iv = __sync_lock_test_and_set($address, $iv, $size);
 
 $iv = __sync_lock_release($address, $size);
 
 __sync_synchronize();
 
 $iv = __sync_bool_compare_and_swap($address, $oldval, $newval, $size);
 
 $iv = __sync_val_compare_and_swap($address, $oldval, $newval, $size);
 
 $iv = __sync_add_and_fetch($address, $iv, $size);
 
 $iv = __sync_sub_and_fetch($address, $iv, $size);
 
 $iv = __sync_and_and_fetch($address, $iv, $size);
 
 $iv = __sync_or_and_fetch($address, $iv, $size);
 
 $iv = __sync_xor_and_fetch($address, $iv, $size);
 
 $iv = __sync_nand_and_fetch($address, $iv, $size);
 
 $iv = __sync_fetch_and_add($address, $iv, $size);
 
 $iv = __sync_fetch_and_sub($address, $iv, $size);
 
 $iv = __sync_fetch_and_and($address, $iv, $size);
 
 $iv = __sync_fetch_and_or($address, $iv, $size);
 
 $iv = __sync_fetch_and_xor($address, $iv, $size);
 
 $iv = __sync_fetch_and_nand($address, $iv, $size);

=head1 AUTHOR

Yury Kotlyarov C<yura@cpan.org>

=head1 SEE ALSO

L<POSIX::RT::Signal>, L<POSIX>, L<threads>

=cut
