package HPCD::SLURM;
### HPCD::SLURM.pm #########################################################################

=head1 NAME

	HPCD::SLURM

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

	use HPCI;

	my $group = HPCI->group(cluster => 'SLURM', ...);

=head1 DESCRIPTION

This is a driver module that can be used internally from HPCI, by
specifying a cluster type of 'SLURM'.  It customizes the HPCI access
interface to control jobs submitted to an SLURM (Simple Linux Utility
for Resource Management) cluster.

The differences provided by the SLURM driver are:

=over

=item -

the following resource names have slurm-specific aliases

=over

=item h_time
time

=back

Using these aliases causes your code to be SLURM-specific.  That makes
converting it to use an alternate type of cluster more painful.  However,
if you do not expect to ever be moving your code to a different cluster
type, this might simplify the interface for people who already know the
SLURM-specific resource names and wish to avoid the confusion that might
come from using the generic names.

=item -

a stage attribute B<native_args_string> is available which specifies a string of
argument(s) that will be included in the srun/sbatch command that starts execution
of that stage

=item -

The result information hash returned by C<$stats = $group-E<gt>execute>
includes all of the info provided by the SLURM sacct command, not just
the exit status.

=item -

If a stage is terminated because it exceeds the requested memory resource
limit, then it will normally be retried using a higher limit.
The default is to first try with '2G' (if no mem resource limit
is explicitly specified).  After mem failures, the next larger size in the
default sequence (2G 4G 8G 16G 32G) is attempted.

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

Anqi (Joyce) Yang      - Boutros Lab

=head1 ACKNOWLEDGEMENTS

Paul Boutros, Phd, PI - Boutros Lab

The Ontario Institute for Cancer Research

=cut

1;

