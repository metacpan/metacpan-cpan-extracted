package HPCD::SGE;
### HPCD::SGE.pm ###########################################################################

=head1 NAME

    HPCD::SGE

=head1 VERSION

Version 0.55

=cut

our $VERSION = '0.55';

=head1 SYNOPSIS

    use HPCI;

    my $group = HPCI->group(cluster => 'SGE', ...);

=head1 DESCRIPTION

This is a driver module that can be used internally from HPCI, by
specifying a cluster type of 'SGE'.  It customizes the HPCI access
interface to control jobs submitted to an SGE (Sun Grid Engine) cluster.

The differences provided by the SGE driver are:

=over

=item -

the following resource names have sge-specific aliases

=over

=item mem
h_vmem

=item h_time
h_rt

=item s_time
s_rt

=back

Using these aliases causes your code to be SGE-specific.  That makes
converting it to use an alternate type of cluster more painful.  However,
if you do not expect to ever be moving your code to a different cluster
type, this might simplify the interface for people who already know the
SGE-specific resource names and wish to avoid the confusion that might
come from using the generic names.

=item -

a stage attribute B<extra_sge_args_string> is available which specifies a string of
argument(s) that will be included in the qsub command that starts execution of that
stage

=item -

The B<name> attribute for a stage will be filtered to only allow letters,
digits, dash, dot, and underscore.  After this filtering, the name must
still be unique within the group.  (This is a requirement for names submitted
to the SGE system.)

=item -

The result information hash returned by C<$stats = $group-E<gt>execute>
includes all of the info provided by the SGE qacct command, not just
the exit status.

=item -

If a stage is terminated because it exceeds the requested memory resource
limit, then it will normally be retried using a higher limit.
The default is to first try with '2G' (if no h_mem or mem resource limit
is explicitly specified).  After mem failures, the next larger size in the
default sequence (2G 4G 8G 16G 32G) is attempted.  The detection for
exceeding the memory requirement is concoluted, because SGE does not return
a clear indiciation that it terminated the job.  HPCI considers it to have
been a memory overrun if the memory usage exceeds a threshold (default is 99%
of requested memory allocation, but the attribute B<retry_mem_percent>
can be specified to provide an alternate range), or if one of a few common
memory allocation failure requests is seen.

=item -

The SGE driver use the DRMAA binary library to interface with the SGE system
if it can, otherwise it uses the SGE user interface programs (qsub, qacct,
qdel).

You can set the environment variable HPCI_NO_DRMAA to a true value if you
wish to prevent use of the DRMAA library.  (This is mostly provided to be
able to test that both mechanisms work correctly, but it might also be
useful on a system that has a broken DRMAA interface that appears to load
correctly.)

=back

=head1 SEE ALSO

=over

=item HPCI

Describes the generic HPCI iterface - this manual is only providing
the exceptions to that document (and its related documents).

=item HPCI::Group

Describes the interface common to all B<HPCI Group>
objects, regardless of the particular type of cluster that
is actually being used to run the stages.

=item HPCI::Stage

Describes the interface common to stage object returned
by all B<HPCI Stage> objects, regardless of the
particular type of cluster that is actually being used to
run the stages.

=back

=head1 AUTHOR

Christopher Lalansingh - Boutros Lab

John Macdonald         - Boutros Lab

=head1 ACKNOWLEDGEMENTS

Paul Boutros, Phd, PI - Boutros Lab

The Ontario Institute for Cancer Research

=cut

1;

