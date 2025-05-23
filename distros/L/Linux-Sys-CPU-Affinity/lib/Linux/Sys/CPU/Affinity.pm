package Linux::Sys::CPU::Affinity;

use 5.026001;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
    'cpu' => [ qw/
        cpu_count
        cpu_isset
    	cpu_equal
    	cpu_zero
    	cpu_clr
    	cpu_set
    	cpu_and
    	cpu_xor
    	cpu_or
    / ],
    'nprocs' => [ qw/ get_nprocs / ]
);

our @EXPORT_OK = (
	@{ $EXPORT_TAGS{'cpu'} },
	@{ $EXPORT_TAGS{'nprocs'} },
);

our @EXPORT = qw();

our $VERSION = '0.13';

require XSLoader;
XSLoader::load('Linux::Sys::CPU::Affinity', $VERSION);

1;
__END__
=head1 NAME

Linux::Sys::CPU::Affinity - Perl XS extension for setupping CPU affinity

=head1 SYNOPSIS

  use Linux::Sys::CPU::Affinity / :cpu :nprocs /;

  my @cpus = (0, 10, 70 .. 80);

  my $ca = Linux::Sys::CPU::Affinity->new(); # the same as below, but @cpus is empty
  my $ca = Linux::Sys::CPU::Affinity->new(\@cpus);

  my $is_success = $ca->set_affinity($pid);
  my $cpus_array = $ca->get_affinity($pid); # from the PID

  $ca->cpu_zero();
  cpu_zero($ca);

  $ca->cpu_clr($cpu);
  cpu_clr($ca, $cpu);

  $ca->cpu_set($cpu);
  cpu_set($ca, $cpu);

  my $isset = $ca->cpu_isset($cpu);
  my $isset = cpu_isset($ca, $cpu);

  my $res = $ca->cpu_equal($another_ca);
  my $res = cpu_equal($ca, $another_ca);

  my $cnt = $ca->cpu_count();
  my $cnt = cpu_count($ca);

  my $new_ca = $first_ca->cpu_and($second_ca);
  my $new_ca = cpu_and($first_ca, $second_ca);

  my $new_ca = $first_ca->cpu_xor($second_ca);
  my $new_ca = cpu_xor($first_ca, $second_ca);

  my $new_ca = $first_ca->cpu_or($second_ca);
  my $new_ca = cpu_or($first_ca, $second_ca);

  $ca->reset(); # the same as below, but @cpus is empty
  $ca->reset(\@new_cpus);

  my $cpus_array = $ca->get_cpus(); # from current set in object

  my $new_ca = $ca->clone();

  $ca->DESTROY(); # the same as "undef $ca;"

  my $nprocs = get_nprocs();

=head1 DESCRIPTION

This module allows you to pin any process by its PID to some CPU's group.

=head2 new

Constructor. It receives an array reference with CPU's number to be used in set creation.
In case if the argument isn't specified, the empty array will be used.

According to the cpu_set(3) Linux man page, the first available CPU on the system corresponds to a cpu value of 0,
the next CPU corresponds to a cpu value of 1, and so on. The constant CPU_SETSIZE (currently 1024) specifies a value
one greater than the maximum CPU number that can be used in set.

The size of created set will be equal to the amoumt of available CPU cores.
If code is failed to get that amount, then the CPU_SETSIZE constant will be used instead.

Returns an instance of class.

=head2 set_affinity

It receives the PID number and applies previously created set to the specified process.
Returns -1 on error, otherwise returns 0.
If pid is zero, then the calling thread is used.

See the method analog in sched_setaffinity(2) Linux man page.

=head2 get_affinity

It receives the PID number and gets the current settings of allowed CPUs for this PID.
Returns an array reference with list of CPU number.
If pid is zero, then the mask of the calling thread is returned.

See the method analog in sched_getaffinity(2) Linux man page.

=head2 reset

It receives an array reference with CPU's number to be used in set creation.
In case if the argument isn't specified, the empty array will be used.

If the set had been set set before this method was invoked, then the old set will be destroyed,
but it won't be applied automatically.

=head2 cpu_zero

Clears set, so that it contains no CPUs.
New set won't be applied automatically.

See CPU_ZERO, CPU_ZERO_S in cpu_set(3) Linux man page.

=head2 cpu_count

Returns the number of CPUs in set.

See CPU_COUNT, CPU_COUNT_S in cpu_set(3) Linux man page.

=head2 cpu_isset

It receives the CPU number.

Returns nonzero if cpu is in set; otherwise, it returns 0.

=head2 cpu_set

Adds the received CPU in to the set.
New set won't be applied automatically.

=head2 cpu_clr

Removes the received CPU from the set.
New set won't be applied automatically.

=head2 cpu_equal

Returns nonzero if the two CPU sets are equal; otherwise returns 0.

=head2 get_cpus

Returns the array reference with CPUS's numbers which are presented in set.
Please, keep in mind, that this set can be not applied yet to any PID.
To apply this set you can use C<set_affinity> method.

=head2 cpu_and

Stores he intersection of the sets C<$ca1> and C<$ca2> in the new set, and returns it.

=head2 cpu_or

Stores the union of the sets C<$ca1> and C<$ca2> in the new set, and returns it.

=head2 cpu_xor

Stores the XOR of the sets C<$ca1> and C<$ca2> in the new set, and returns it.
The XOR means the set of CPUs that are in either C<$ca1> or C<$ca2>, but not both.

=head2 clone

Returns the copy of original instance.

=head2 DESTROY

Destructor.

=head2 get_nprocs

Returns the amount of available CPU cores (see detail in get_nprocs(3) Linux Manual Pages).

=cut

=head1 AUTHOR

Chernenko Dmitriy <cdn@cpan.org>

=cut
