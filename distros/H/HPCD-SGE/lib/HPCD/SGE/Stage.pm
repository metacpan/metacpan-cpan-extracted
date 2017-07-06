package HPCD::SGE::Stage;

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

use HPCD::SGE::Run;

with 'HPCI::Stage',
	HPCI::get_extra_roles('SGE', 'stage');

sub _build_cluster_specific_valid_resources {
	return (
		h_vmem => 'mem',
		h_rt   => 'h_time',
		s_rt   => 's_time'
	)
}

sub _build_cluster_specific_default_resources {
	return ( h_vmem => '2G' )
};

sub _build_cluster_specific_default_retry_resources {
	h_vmem => [qw(2G 4G 8G 16G 32G)]
};

has '+runs' => (
	isa      => 'ArrayRef[HPCD::SGE::Run]'
);

has '_run_class' => (
	is       => 'ro',
	isa      => 'Str',
	init_arg => undef,
	default  => "HPCD::SGE::Run"
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

has '+name' => (
	writer  => '_set_name',
	trigger => \&_name_filter
);

sub _name_filter {
	my( $self, $new, $old ) = @_;
	my $filter = $new;
	$filter =~ s/[^A-Za-z0-9\-\.\_]//g;
	$self->_set_name( $filter ) if $filter ne $new;
}

has 'extra_sge_args_string' => (
	is      => 'ro',
	isa     => 'Str',
	default => ''
);

has 'memory_too_small' => (
	is      => 'ro',
	isa     => 'CodeRef',
	default => sub { return sub { return 0 } }
);

sub _analyse_completion_state {
	my $self  = shift;
	my $run   = shift;
	my $stats = $run->stats;
	$self->debug( "Stats from finished stage(" . $self->name . "): " . Dumper($stats) );
	my $vmem_retry = $self->_vmem_usage( $run );
	my $new_state =
			0 == $stats->{exit_status}     ? 'pass'
		:   $vmem_retry                    ? 'retry'
		:                                    'fail';
	$self->_set_state($new_state);
}

sub _can_retry_from_vmem {
	my ($self, $res, $dres) = @_;
	return 0
		unless $self->_use_retry_resources_required
		and my $res_avail = $self->_use_retry_resources_required->{h_vmem};
	for my $nres (@$res_avail) {
		$self->info( "Considering ($nres) as resource replacement for ($dres)" );
		next unless $res < _res_to_num($nres);
		$self->info( "Accepted ($nres) as resource replacement for ($dres)" );
		$self->_use_resources_required->{h_vmem} = $nres;
		return 1;
	}
	$self->info( "No resource replacement found for ($dres)" );
	return 0;
}

sub _res_to_num {
	my $str = shift;
	return 0 unless my ($val, $unit) = ($str =~ /^(\d+(?:\.\d+)?)([KMG])?$/);
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

has 'retry_mem_percent' => (
	isa => 'Int',
	is  => 'ro',
	default => 99
);

sub _vmem_usage {
	my $self    = shift;
	my $run     = shift;
	my $stats = $run->stats;
	my ( $req, $used ) = map { _res_to_num($_) }
		$self->_use_resources_required->{h_vmem},
		$stats->{peak_virtual_memory};
	my $dreq     = _num_to_res($req);
	my $dused    = _num_to_res($used);
	$run->_cpu_multiplier( $stats->{slots} )
		if $stats->{granted_pe} !~ /^(NONE|unknown)/ && $stats->{slots} =~ /^\d+/;
	if ($run->_cpu_multiplier > 1) {
		$used /= $run->_cpu_multiplier;
		$dused = _num_to_res($used) . ' per pe';
	}
	my $pct      = ( $used / $req ) * 100;
	my $warn     = ($pct < 50 && $req > _res_to_num('2G'))
					? "  ** Requested resource too large"
					: "";
	my $loglevel = $warn ? 'warn' : 'info';
	$self->$loglevel( sprintf "Resource(%s): Requested(%s) Usage(%s) %.2f%%%s Stage(%s), Run(%s)",
		'h_vmem', $dreq, $dused, $pct, $warn, $run->stage->name, $run->index );
	my $stderr = $run->_stderr;
	my $cmd  = "tail -3 $stderr";
	my @last = `$cmd`;
	my $consider_vmem_retry_reason =
		  ($last[-1] =~ /Out of memory\!/)            ? "found stderr: $last[-1]"
		: ($last[-1] =~ /MemoryError/)                ? "found stderr: $last[-1]"
		: ($last[-2] =~ /^Error: cannot allocate vector of size /
			&& $last[-1] =~ /Execution halted/)       ? "found stderr: $last[-2]"
	    : ($pct >= $self->retry_mem_percent)          ? "exceeded allocated memory limit (or close enough to the limit)"
		: $self->memory_too_small->($stats, $stderr)  ? "user-provided check"
		                                              : undef;

	if ($consider_vmem_retry_reason) {
		$self->info( "Considering vmem retry, $consider_vmem_retry_reason" );
		return $self->_can_retry_from_vmem(
			$pct > 100
				? ( $used, $dused )
				: ( $req, $dreq )
		);
	}
	return 0;
}

1;

