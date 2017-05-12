package HPCD::SLURM::Stage;

=head1 NAME

	HPCD::SLURM::Stage

=head1 SYNOPSIS

	use HPCD::SLURM::Stage;

=head1 DESCRIPTION

	This module defines SLURM-specific stage attributes and contains the method
	that decides if the program has failed due to memory shortage, and if so if
	the program can be retried with a larger memory limit.

=cut

### INCLUDES ##################################################################

# safe Perl
use warnings;
use strict;
use Carp;
use Data::Dumper;
use DateTime;

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::ClassAttribute;

use HPCD::SLURM::Run;

with 'HPCI::Stage',
	HPCI::get_extra_roles('SLURM', 'stage');

=head1 BUILDERS

=head2 _build_cluster_specific_valid_resources

	The only two resources user can define via user_input are (hard) time and
	(hard) memory.

=cut

sub _build_cluster_specific_valid_resources {
	return (
		mem => 'mem',
		time   => 'h_time'
	)
}

=head2 _build_cluster_specific_default_resources

	The default memory limit is 2G, and default time limit is there is no limit.

=cut

sub _build_cluster_specific_default_resources {
	return ( mem => '2G' )
};

=head2 _build_cluster_specific_default_retry_resources

	A list of possible retry memory limits (when a program fails because of lack
	of memory it will look through this list to find and retry with the next biggest
	memory available). Should be in ascending order. Default is qw(2G 4G 16G 32G).

=cut

sub _build_cluster_specific_default_retry_resources {
	mem => [qw(2G 4G 8G 16G 32G)]
};

=head1 ATTRIBUTES

=cut

has '+runs' => (
	isa      => 'ArrayRef[HPCD::SLURM::Run]'
);

has '_run_class' => (
	is       => 'ro',
	isa      => 'Str',
	init_arg => undef,
	default  => "HPCD::SLURM::Run"
);

around '_run_args' => sub {
	my $orig = shift;
	my $self = shift;
	return (
		(
			$self->$orig(), resources_required => $self->_use_resources_required
		)
	);
};

has 'native_args_string' => (
	is      => 'ro',
	isa     => 'Str',
	default => ''
);

has 'memory_too_small' => (
	is      => 'ro',
	isa     => 'CodeRef',
	default => sub { return sub { return 0 } }
);

=head1 METHODS

=head2 _analyse_completion_state

	Analyzes and returns the completion state.
	Exit status 0 => pass, otherwise, if the program fails due to lack of memory and
	the program can be retried with the next biggest memory, then returns retry, else
	returns fail.

=cut

sub _analyse_completion_state {
	my $self  = shift;
	my $run   = shift;
	my $stats = $run->stats;
	$self->debug( "Stats from finished stage(" . $self->name . "): " . Dumper($stats) );
	my $vmem_retry = $self->_vmem_usage( $run );
	my $new_state =
			0 == $stats->{ExitCode}     ? 'pass'
		:   $vmem_retry                 ? 'retry'
		:                                 'fail';
	$self->_set_state($new_state);
}

=head2 _can_retry_from_vmem

	Searches for the next biggest memory in _use_retry_resources_required for retry.

=cut

sub _can_retry_from_vmem {
	my ($self, $res, $dres) = @_;
	return 0
		unless $self->_use_retry_resources_required
		and my $res_avail = $self->_use_retry_resources_required->{mem};
	for my $nres (@$res_avail) {
		$self->info( "Considering ($nres) as resource replacement for ($dres)" );
		next unless $res < _res_to_num($nres);
		$self->info( "Accepted ($nres) as resource replacement for ($dres)" );
		$self->_use_resources_required->{mem} = $nres;
		return 1;
	}
	$self->info( "No resource replacement found for ($dres)" );
	return 0;
}

=head2 _res_to_num

	Takes in a memory size (units: KMG or none(no unit means the unit is byte already))
	and converts it to a number representing the original size in bytes.

	Example:
	&_res_to_num('1024') returns 1024 (because 1024 bytes = 1024 bytes)
	&_res_to_num('2K') returns 2048 (because 2KB = 2048 bytes)
	&_res_to_num('1M') returns 1048576 (because 1MB = 1048576 bytes)

=cut

sub _res_to_num {
	my $str = shift;
	return 0 unless my ($val, $unit) = ($str =~ /^(\d+(?:\.\d+)?)([KMG])?B?$/);
	if ($unit) {
		$unit = uc $unit;
		if ($unit eq 'K') {
			return $val * 1024;
		}
		elsif ($unit eq 'M') {
			return $val * 1024 * 1024;
		}
		elsif ($unit eq 'G') {
			return $val * 1024 * 1024 * 1024;
		}
		else {
			return 0;
		}
	}
	return $val;
}

=head2 _num_to_res

	Takes in a number in bytes and converts it into designated units (K/M/G).

	Example:
	&_num_to_res(2048) returns '2K'
	&_num_to_res(1048576) returns '1M'

=cut

sub _num_to_res {
	my $num   = shift;
	my $codes = ' KMG';
	my $unit  = 0;
	while ($unit < length($codes)-1 && $num >= 1024) {
		$num /= 1024;
		++$unit;
	}
	$num = int($num) == $num ? int($num) : sprintf( "%.2f", $num );
	$num .= substr( $codes, $unit, 1 );
	return $num;
}

=head2 _vmem_usage

	Gives out warning based on memory usage account information and decides if the program
	fails because of lack of memory. If so, invoke _can_retry_from_vmem and return the memory
	limit for retry, otherwise return 0.

=cut

sub _vmem_usage {
	my $self    = shift;
	my $run     = shift;
	my $stats = $run->stats;
	my ( $req, $used ) = map { _res_to_num($_) }
		$self->_use_resources_required->{mem},
		$stats->{peak_virtual_memory};
	my $dreq     = _num_to_res($req);
	my $dused    = _num_to_res($used);
	my $pct      = ( $used / $req ) * 100; # percentage of actual memory that got used
	my $warn     = ($pct < 50 && $req > _res_to_num('2G'))
					? "  ** Requested resource too large"
					: "";
	my $loglevel = $warn ? 'warn' : 'info';
	$self->$loglevel( sprintf "Resource(%s): Requested(%s) Usage(%s) %.2f%%%s",
		'mem', $dreq, $dused, $pct, $warn );
	my $stderr = $run->_stderr;
	my $cmd  = "tail -1 $stderr";
	my $last = `$cmd`;
	# Decides if the program fails due to lack of memory
	# Sometimes SLURM will throw an error message 'exceeded memory limit', but sometimes
	# there will be no such error message. In the second case, we need to check the memory
	# usage percentage. But even that may fail, if account gathering frequency is set too big
	# (if the interval for checking memory usage is 30 sec then the memory usage info we get
	# back will likely to be a lot less that what we expect), so in that case we will check
	# the signal - if the program gets KILLED and the completion state is not TIMEOUT, then
	# it is most likely that the job has failed due to shortage of memory.
	if ($last =~ /exceeded memory limit/
			|| $pct >= 99
			|| $self->memory_too_small->($stats, $stderr)
			|| ((defined $stats->{killed}) && ($stats->{killed} eq 'KILL') && ($stats->{State} ne 'TIMEOUT'))) {
		return $self->_can_retry_from_vmem(
			$pct > 100
				? ( $used, $dused )
				: ( $req, $dreq )
		);
	}
	return 0;
}

=head1 AUTHOR

John Macdonald         - Boutros Lab

Anqi (Joyce) Yang      - Boutros Lab

=head1 ACKNOWLEDGEMENTS

Paul Boutros, Phd, PI - Boutros Lab

The Ontario Institute for Cancer Research

=cut

1;
