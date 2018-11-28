package HPCI::Run;

### INCLUDES ##################################################################

# safe Perl
use warnings;
use strict;
use Carp;

use Config;

use MooseX::Role::Parameterized;
use MooseX::Types::Path::Class qw(Dir File);

parameter theDriver => (
	isa      => 'Str',
	required => 1,
);

die "No sigs?" unless $Config{sig_name} && $Config{sig_num};

my %sig_num;
my @sig_name;

@sig_num{split ' ', $Config{sig_name}} = split ' ', $Config{sig_num};
while (my($k,$v) = each %sig_num) {
	$sig_name[$v] ||= $k;
}

role {
	my $p = shift;
	my $theDriver = $p->theDriver;
	my $StageClass = "${theDriver}::Stage";

	# do nothing, but let roles write before/after/around wrappers
	method BUILD => sub {
	};

	has 'stage' => (
		is       => 'ro',
		required => 1,
		isa      => $StageClass,
		weak_ref => 1,
		handles  => {
			debug => 'debug',
			info  => 'info',
			warn  => 'warn',
			error => 'error',
			fatal => 'fatal',
		},
	);

	has 'index' => (
		is       => 'ro',
		isa      => 'Int',
		required => 1,
	);

	has 'pid' => (
		is       => 'rw',
		isa      => 'Int',
	);

	has 'unique_id' => (
		is       => 'ro',
		isa      => 'Str',
		lazy     => 1,
		init_arg => undef,
		default  => sub {
			my $self  = shift;
			my $stage = $self->stage;
			return $stage->_sub_name( $self->index );
		},
	);

	has 'dir' => (
		is       => 'ro',
		isa      => Dir,
		init_arg => undef,
		lazy     => 1,
		default  => sub {
			my $self      = shift;
			my $stage_dir = $self->stage->stage_dir;
			my $run_dir   = $stage_dir->subdir( $self->index );
			HPCI::_trigger_mkdir( $self, $run_dir );
			my $sym = $stage_dir->file('final_retry');
			unlink $sym if -e $sym;
			symlink $self->index, $sym;
			return $run_dir;
		},
	);

	has '_stdout' => (
		is       => 'ro',
		isa      => File,
		init_arg => undef,
		lazy     => 1,
		default  => sub {
			my $self   = shift;
			$self->dir->file( 'stdout' );
		},
	);

	has '_stderr' => (
		is       => 'ro',
		isa      => File,
		init_arg => undef,
		lazy     => 1,
		default  => sub {
			my $self   = shift;
			$self->dir->file( 'stderr' );
		},
	);

	has 'status' => ( # exit code if job exitted normally
		is       => 'rw',
		isa      => 'Str',
		init_arg => undef,
		lazy     => 1,
		default  => 0,
	);

	has 'kill' => ( # true if job was killed
		is       => 'rw',
		isa      => 'Str',
		init_arg => undef,
		lazy     => 1,
		default  => 0,
	);

	has 'killsignal' => ( # kill signal if job was killed
		is       => 'rw',
		isa      => 'Str',
		init_arg => undef,
		lazy     => 1,
		default  => 0,
	);

	has 'abort' => ( # abort info if job was not able to start
		is       => 'rw',
		isa      => 'Str',
		init_arg => undef,
		lazy     => 1,
		default  => 0,
	);

	has 'stats' => (
		is       => 'ro',
		isa      => 'HashRef[Str]',
		lazy     => 1,
		init_arg => undef,
		default  => sub {
			my $self = shift;
			return {
				map { $_ => 'unknown' } (@{ $self->stats_keys }, 'exit_status')
			}
		},
	);

	has '_analysis_chose_retry' => (
		is       => 'rw',
		isa      => 'Int',
		lazy     => 1,
		init_arg => undef,
		default  => 0,
	);

	method soft_timeout => sub {
		my $self = shift;
		$self->info( "Sending soft timeout: " . $self->unique_id );
		my $pid = $self->pid;
		kill 'USR1', $self->pid;
	};

	method hard_timeout => sub {
		my $self = shift;
		my $pid = $self->pid;
		$self->info( "Sending hard timeout: " . $self->unique_id );
		kill 'KILL', $self->pid;
	};

	method _submit_command => sub {
		my $self = shift;
		my $cmd  = shift;
		my $pid = fork;

		# normal parent
		return $pid if $pid;

		# parent after fork failure
		$self->_croak( "Fork failed: $!" ) unless defined $pid;

		# child
		setpgrp 0, $$;
		exec $cmd or die "Exec failed ($!) on command: $cmd\n";
	};

	before '_collect_job_stats' => sub {
		my $self   = shift;
		my $status = shift;

		$self->_base_register_status( $status );
	};

	sub _base_register_status {
		my $self   = shift;
		my $status = shift;
		my $stath  = $self->stats;
		$stath->{exit_status} = $status;
		if ($status =~ /\D/) {
			$self->killsignal( "internal code failed: $status" );
			$self->status( $stath->{exit_status} = 126 );
			;
		}
		elsif ($status & 127) {
			$self->kill( 1 );
			$self->killsignal( $sig_name[$status & 127] // "Unknown signal #".($status&127) );
		}
		else {
			$self->status( $stath->{exit_status} = $status >> 8 );
		}
	};

	around '_register_status' => sub {
		my $orig = shift;
		my $self   = shift;
		my $status = shift || 0;
		$orig->($self,$status);
		$self->_base_register_status( $status );
	};

};

1;
