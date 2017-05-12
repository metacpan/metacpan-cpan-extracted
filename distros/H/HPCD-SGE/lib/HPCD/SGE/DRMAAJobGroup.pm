package HPCD::SGE::DRMAAJobGroup;

### INCLUDES ##################################################################

# safe Perl
use warnings;
use strict;
use Schedule::DRMAAc qw( :all );

use Moose::Role;

with 'HPCD::SGE::DRMAAWrapper';

sub _sleep {
	my $self = shift;
	my $time = shift;

	my ($jobid, $stat, $rusage) = $self->Odrmaa_wait( $DRMAA_JOB_IDS_SESSION_ANY, $time );
	if (defined($jobid) and my $run = $self->_runs->{$jobid}) {
		$run->_drmaa_rusage( $rusage );
		$run->_drmaa_stat( $stat );
		$self->_reap_run( $run, $stat );
	}
};

1;
