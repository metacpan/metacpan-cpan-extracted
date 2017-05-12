package HPCD::SLURM::Run;

=head1 NAME

	HPCD::SLURM::Run

=head1 SYNOPSIS

	use HPCD::SLURM::Run;

=head1 DESCRIPTION

	This module helps execute srun, scancel and sacct.
	srun: This module puts together user input for stage attributes and submits the srun command for
	the system to run.
	sacct: This module contains a method to parse account information given
	back by the sacct command.
	scancel: This module executes the scancel command when the job needs to be killed.

=cut

### INCLUDES ######################################################################################

# safe Perl
use warnings;
use strict;
use Carp;

use Moose;
use Config;

my %sig_num;
my @sig_name;

@sig_num{split ' ', $Config{sig_name}} = split ' ', $Config{sig_num};
while (my ($k, $v) = each %sig_num) {
	$sig_name[$v] ||= $k;
}

sub _register_status {
}

sub _collect_job_stats {
}

with 'HPCI::Run' => { theDriver => 'HPCD::SLURM' };

# %job_info_mappings is a hash table that maps account information keys used by SLURM to more
# human readable names
my %job_info_mappings = (
	MaxRSS    => 'peak_real_memory',
	MaxVMSize      => 'peak_virtual_memory'
);

# @job_info_fields contains a list of account information keys that can be obtained by the
# "sacct -e" command
my @job_info_fields = map { m/\S+/g } `sacct -e`;

=head1 ATTRIBUTE

=head2 stats_keys

stats_keys record the names of the account information keys. Default to @job_info_fields.

=cut

has 'stats_keys' => (
	is => 'ro',
	isa => 'ArrayRef[Str]',
	init_arg => undef,
	default  => sub { [ values @job_info_fields ] }
);

=head1 METHODS

=head2 after '_collect_job_stats'

	Calls the subroutine _collect_sacct_info, updates the hash in the stats attribute
	with the exit status and accounting info.

=cut

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
	my $sacct_info = $self->_collect_sacct_info;
	while (my ( $k, $v ) = each %$sacct_info) {
		$k = $job_info_mappings{$k} // $k;
		$stath->{$k} = $v;
	}
	$self->_base_register_status( $stath->{ExitCode} );
	$stath->{killed} = $self->killsignal if $self->killsignal;
};

=head2 _collect_sacct_info

	Executes the command 'sacct --name $id --format=$key' n times, where $key is a singular key
	returned by sacct -e and n is the number of	keys returned by sacct -e. Maps $key and the
	returned account information value in hash %info and returns %info as the result.

	The reason why sacct is called multiple times instead of once (by sacct -name $id --format=
	$key1,$key2,$key3...) is that sometimes the value field might be blank, e.g. the result of
	the command sacct -name $id --format=Account,User,Comment,ReqMem might be

	Account	User	Comment	ReqMem
	----------------------------------
	        jdoe			2Gn

	It is thus difficult to parse the values and map them with corresponding keys. By calling
	--format=$key separately for each $key value each time, we can catch all the blank values and
	ensure that the key-value pairs are matched correctly.

=cut

sub _collect_sacct_info {
	my $self  = shift;
	my $id    = $self->unique_id;
	my %info  = ();
	my $stage = $self->stage;
	foreach my $key (@job_info_fields) {
		open my $fh, '-|', "sacct --name $id -n --format=$key 2>&1"
			or $self->croak("cannot open sacct command: $!");
		while (defined(my $val = <$fh>)) {
			$val =~ s/^\s*//;
			$val =~ s/\s*$//;
			# The number1:number2 formatted string returned by sacct for ExitCode has number1
			# as the exit status and number2 as the signal value.
			if ($key eq "ExitCode") {
				my( $exit, $kill ) = $val =~ m/(.*):(.*)/;
				$val = $exit;
				if ($kill) {
					$val += 128;
					$self->kill( 1 );
					$self->killsignal( $sig_name[$kill] // "Unknown signal #".($kill) );
				}
			}
			$info{$key} = $val;
		}
	}
	return \%info;
}

=head2 around 'soft_timeout'

	Replaces the original 'soft_timeout' method in HPCI, and cancels the job directly.

=cut

around 'soft_timeout' => sub {
	my $orig = shift;
	my $self = shift;
	$self->_delete_job;
};

=head2 around 'hard_timeout'

	Cancels the job before calling the original HPCI method 'hard_timeout'.

	The original hard_timeout sends a kill signal to the child process. In this case,
	that is the "srun" program, not the actual child job (which is on some other
	computer so kill cannot be used). The sleep and continue with sending the kill
	signal at least cleans up the local process if the cancellation does not work
	properly. Usually it will, and the kill will be sent to a process that has terminated
	already.

=cut

around 'hard_timeout' => sub {
	my $orig = shift;
	my $self = shift;
	$self->_delete_job;
	sleep(2);
	$self->$orig(@_);
};

=head2 _delete_job

	Terminates the job by calling scancel -n $id.

=cut

sub _delete_job {
	my $self = shift;
	my $id   = $self->unique_id;
	$self->info( "Running: (scancel -n $id) to terminate stage job" );
	system( "scancel -n $id" );
}

=head2 _to_MB

	A subroutine which converts any memory value in unit KMGT to a number in MB,
	since the srun --mem= option takes only a number which by default is in MB.

	Example:
		$self->_to_MB('2G') would return 2048
		$self->_to_MB('100M') would return 100

=cut

sub _to_MB {
	my $self = shift;
	my $val = shift;
	return ($1 * 1024 * 1024)
		if $val =~ /^(\d+)T$/;
	return ($1 * 1024)
		if $val =~ /^(\d+)G$/;
	return ($1)
		if $val =~ /^(\d+)M$/;
	return ($1 / 1024)
		if $val =~ /^(\d+)K$/;
	}

=head2 _reformat_time

	A subroutine which reformats the input $sec (a number in seconds) to either
	minute:second, hour:minute:second, or day-hour:minute:second, which are the
	formats acceptable by the srun --time= option.

	Example:
		$self->_reformat_time(1) would give '0:1'
		$self->_reformat_time(70) would give '1:10'
		$self->_reformat_time(3601) would give '1:0:1'
		$self->_reformat_time(86400) would give '1-0:0:0'

=cut

sub _reformat_time {
	my $self = shift;
	my $sec = shift;
	return "0:$sec" if $sec < 60;
	my $min = int $sec / 60;
	$sec %= 60;
	return "$min:$sec" if $min < 60;
	my $hour = int $min / 60;
	$min %= 60;
	return "$hour:$min:$sec" if $hour < 24;
	my $day = int $hour / 24;
	$hour %= 24;
	return "$day-$hour:$min:$sec";
	}

=head2 _res_value_map

	A subroutine which reformats key and value in stage attribute resources_required
	to the option format acceptable by srun.

	Example:
		If the key and value in resources_required is 'mem' and '3G', then
		_res_value_map would give '--mem=3072' as the output.

=cut

sub _res_value_map {
	my $self = shift;
	my $key  = shift;
	my $val  = shift;
	$val = $self->_reformat_time($self->stage->_time_to_secs( $val ))
		if $key eq 'time';
	$val = $self->_to_MB( $val )
		if $key eq 'mem';
	return "--$key=$val";
}

=head2 _get_mapped_resources_string

	A subroutine which maps parameters in resources_required to a string of srun
	options.

	Example:
		Say resources_required is {"mem" => "100M", "h_time" => 1000}, then the output
		will be '--mem=100 --time=16:40'.

=cut

sub _get_mapped_resource_string {
	my $self = shift;
	my $res  = shift;
	join( " ",
		map { $self->_res_value_map( $_, $res->{$_} ) }
		sort keys %$res
	);
}

=head2 _get_submit_command

	A subroutine which incorporates attributes of one certain stage (i.e. shell_script,
	unique name, stdout, stderr, native_args_string, resrouces_required) into one single
	srun command for the system to execute.

	Example:
		If the stage has its script_file named script.sh, unique_id being NAME12345,
		native_args_string being "-N 2 -n 4 --mail-type=ALL --mail-user=jdoe@xyz.com",
		resources_required being {"mem" => "5G", "h_time" => 200}, then the output of this
		subroutine would be 'srun -N 2 -n 4 --mail-type=ALL --mail-user=jdoe@xyz.com
		--mem=5120 --time=3:20 -J NAME12345 -o someoutputpath -e someerrorpath script.sh'.

=cut

sub _get_submit_command {
	my $self         = shift;
	my $stage        = $self->stage;
	my $shell_script = $stage->script_file;
	my $name         = $self->unique_id;
	my $extras       = $stage->native_args_string;
	my $res          = $stage->_use_resources_required;
	my $resources    = $self->_get_mapped_resource_string( $res );

	# Note how extras are positioned before resources: so that if a conflict arises
	# (in the case when the user accidentally define time/memory limit in native_args_string
	# as well), SLURM will adopt the ones defined in resources because resources appear later
	my $srun_command = join( ' ',
		"srun",
		( length($extras) ? $extras : () ),
		( length($resources) ? $resources : () ),
		"-J '$name'",
		"-o",      $self->_stdout,
		"-e",      $self->_stderr,
		"'$shell_script'" );

	return $srun_command;
}

=head1 AUTHOR

John Macdonald         - Boutros Lab

Anqi (Joyce) Yang      - Boutros Lab

=head1 ACKNOWLEDGEMENTS

Paul Boutros, Phd, PI - Boutros Lab

The Ontario Institute for Cancer Research

=cut

1;
