package HPCD::SGE::Run;

### INCLUDES ######################################################################################

# safe Perl
use warnings;
use strict;
use Carp;
use HPCD::SGE::DRMAACheck;

use Moose;

sub _register_status {
}

sub _collect_job_stats {
}

with 'HPCI::Run' => { theDriver => 'HPCD::SGE' }, @HPCD::SGE::DRMAACheck::RunWith;

my %job_info_mappings = (
	jobname      => 'name',
	jobnumber    => 'number',
	taskid       => 'task_number',
	qname        => 'queue_name',
	hostname     => 'host',
	qsub_time    => 'submission_time',
	ru_wallclock => 'wallclock_time',
	cpu          => 'cpu_time',
	io           => 'io_transfers_made',
	iow          => 'io_wait_time',
	ru_maxrss    => 'peak_real_memory',
	maxvmem      => 'peak_virtual_memory',
	mem          => 'integral_memory_time',
	exit_status  => 'qacct_exit_status'
);

my @job_info_fields = (
	qw(
		account  arid      department end_time  failed     granted_pe group
		owner    priority  project    ru_idrss  ru_inblock ru_ismrss  ru_isrss
		ru_ixrss ru_majflt ru_minflt  ru_msgrcv ru_msgsnd  ru_nivcsw  ru_nsignals
		ru_nswap ru_nvcsw  ru_oublock ru_stime  ru_utime   slots      start_time
	)
);


has 'stats_keys' => (
	is => 'ro',
	isa => 'ArrayRef[Str]',
	init_arg => undef,
	default  => sub { [ values %job_info_mappings, @job_info_fields ] }
);

after '_collect_job_stats' => sub {
	my $self   = shift;
	my $status = shift;

	my $stath  = $self->stats;

	my $stage   = $self->stage;
	my $id      = $self->unique_id;

	$stath->{exit_status} = $self->status;
	$stath->{aborted} = $self->abort if $self->abort;
	$stath->{internal_killed} = $self->killsignal if $self->kill;

	$stage->info("collecting job stats ($id)\n");
	my $qacct_info = $self->_collect_qacct_info;
	while (my ( $k, $v ) = each %$qacct_info) {
		$k = $job_info_mappings{$k} // $k;
		$stath->{$k} = $v;
	}
	$self->_base_register_status( $stath->{qacct_exit_status} );
	$stath->{killed} = $self->killsignal if $self->killsignal;
};

sub _collect_qacct_info {
	my $self  = shift;

	my $id      = $self->unique_id;
	my %info    = ();
	my $retries = 0;

	GET_STATS:
	while (1) {
		open my $fh, '-|', "qacct -j $id 2>&1"
			or $self->croak("cannot open qacct command: $!");
		my $divcnt = 0;
		%info = ();
		while (<$fh>) {
			next GET_STATS if /^error:/;
			if (/^===*$/) {
				%info = ();
				$self->warn(
	"found duplicate jobs with same id ($id), using last one listed in qacct"
					) if ++$divcnt == 2;
				next;
				}
			if (my ( $key, $val ) = /(\w+)\s+(.*)/) {
				$info{$key} = $val;
			}
		}
	}
	continue {
		last GET_STATS if keys %info || ++$retries == 5;
		sleep(10);
	}
	return \%info;
}

around 'soft_timeout' => sub {
	my $orig = shift;
	my $self = shift;
	$self->_delete_job;
};

around 'hard_timeout' => sub {
	my $orig = shift;
	my $self = shift;
	$self->_delete_job;
	sleep(2);
	$self->$orig(@_);
};

sub _delete_job {
	my $self = shift;
	my $id   = $self->unique_id;
	$self->info( "Running: (qdel $id) to terminate stage job" );
	system( "qdel $id" );
}

sub _res_value_map {
	my $self = shift;
	my $key  = shift;
	my $val  = shift;
	$val = $self->stage->_time_to_secs( $val )
		if $key =~ /^[hs]_rt$/;
	return "$key=$val";
}

sub _get_mapped_resource_string {
	my $self = shift;
	my $res  = shift;
	join( ",",
		map { $self->_res_value_map( $_, $res->{$_} ) }
		sort keys %$res
	);
}

sub _get_submit_command {
	my $self         = shift;

	my $stage        = $self->stage;
	my $shell_script = $stage->script_file;
	my $name         = $self->unique_id;
	my $extras       = $stage->extra_sge_args_string;
	my $res          = $stage->_use_resources_required;
	my $resources    = $self->_get_mapped_resource_string( $res );
	$resources = "-l $resources" if $resources;

	my $qsub_command = join( ' ',
		"qsub",
		( length($extras) ? $extras : () ),
		( length($resources) ? $resources : () ),
		"-N '$name'",
		"-o",      $self->_stdout,
		"-e",      $self->_stderr,
		"-sync y", "-cwd",
		"-b y",    "'$shell_script'" );

	return $qsub_command;
}

1;
