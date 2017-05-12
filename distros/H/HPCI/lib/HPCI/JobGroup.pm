package HPCI::JobGroup;

### INCLUDES ##################################################################

# safe Perl
use warnings;
use strict;
use Carp;
use File::Path qw(make_path remove_tree);
use POSIX ":sys_wait_h";
use HPCI::TimeoutQueue;
use MooseX::Types::Path::Class qw(Dir File);

use MooseX::Role::Parameterized;

parameter theDriver => (
	isa      => 'Str',
	required => 1,
);

role {
	my $p = shift;
	my $theDriver = $p->theDriver;
	my $RunClass = "${theDriver}::Run";

	has '_runs' => (
		is       => 'ro',
		isa      => "HashRef[$RunClass]",
		lazy     => 1,
		init_arg => undef,
		default  => sub { {} },
	);

	has '_t_o_q' => (
		is       => 'ro',
		isa      => 'HPCI::TimeoutQueue',
		init_arg => undef,
		default  => sub { HPCI::TimeoutQueue->new },
		handles  => [
			qw(add_timeout
			delete_timeouts
			expire_timeouts
			time_to_next_timeout)
		],
	);

	has '_caught' => (
		is       => 'ro',
		isa      => 'ArrayRef',
		init_arg => undef,
		default  => sub { [] },
	);

	my $_next_to = undef;

	has '_reaper' => (
		is       => 'ro',
		isa      => 'Ref',
		init_arg => undef,
		default  => sub {
			my $self = shift;
			sub {
				while ( ( my $kid = waitpid( -1, WNOHANG ) ) > 0 ) {
					my $stat = $?;
					if ( my $run = $self->_runs->{$kid} ) {
						# keep a queue of completed children for
						# next_finished_job to collect (one at a time)
						$self->_reap_run( $run, $stat );
						$_next_to = 1;
					}
					else {
						$self->warn(
							"Reaper: kid: $kid, run: UNKNOWN, status: $stat"
						);
					}
				}
				$SIG{CHLD} = $self->_reaper;
			}
		},
	);

	method _reap_run => sub {
		my $self = shift;
		my $run  = shift;
		my $stat = shift;
		my $caught = $self->_caught;
		push @$caught, [ $run, $stat ];
	};

	method child_catcher => sub {
		my $self = shift;
		$SIG{CHLD} = $self->_reaper;
	};

	method next_finished_job => sub {
		my $self = shift;
		my $caught = $self->_caught;

		my ($status, $run);

		while (1) {
			$_next_to = undef;
			if (@$caught) {
				($run, $status) = @{ shift @$caught };
				last;
			}

			$_next_to = $self->time_to_next_timeout;
			if (defined $_next_to && $_next_to <= 0) {
				$self->expire_timeouts;
				next;
			}

			# the reaper might trigger at any time
			# so there could now be a child in the caught list
			# even though we just checked it above
			# We use two methods to minimize the effects of an
			# inopportune repear event.
			# 1. we check caught again at the last moment before sleeping
			# 2. limit the timeout to 5 minutes, so that we check again
			#    soon even if a termination slips in between the last
			#    moment check and the sleep, we don't sleep for days
			#    before checking again for completed children
			# 3. while we are making the final check of caught, we store
			#    the timeout in $_next_to.  The reaper
			#    resets that variable to 1 whenever it catches a child,
			#    so that reduces the sleep time to 1 second.  (Zero
			#    would be nice to use, but POSIX doesn't specify what
			#    sleep does with a parameter of 0, so it is implementation
			#    defined and cannot be trusted.)  This actually closes the
			#    critical section down (if a child terminates at the worst
			#    possible moment, we will sleep for 1 second because the
			#    reaper over-writes the $_next_to value), so, in theory, we
			#    could just sleep for the entire duration, but a 5 minute
			#    sleep provides a margin of safety, in case the reaper runs
			#    while we are getting the $_next_to #    value but before we
			#    actuially use it for the sleep.
			$_next_to = 5*60 unless defined $_next_to && $_next_to < 5*60;
			# if reaper was triggered before this point, @caught will be filled
			next if @$caught;
			# if reaper is triggered between these two statements, it will
			# set $_next_to to 1
			$self->can("_sleep")
				? $self->_sleep($_next_to)
				: sleep $_next_to;
			# if reaper triggers after the sleep has started, the sleep
			# will be interrupted
		}

		$self->delete_timeouts( $run );

		$self->info(
			qq{id finished: "}
		    . $run->unique_id
			. qq{", with return value:     $status}
		);

		$run->_collect_job_stats( $status );

		return $run;
	};

	method submit_stage => sub {
		my $self         = shift;
		my $stage        = shift;
		my $run          = $stage->_run;
		my $name         = $run->unique_id;
		my $command      = $stage->command;
		my ( $run_command, $soft_timeout, $hard_timeout ) = $run->_get_submit_command;
		$self->info("Submitting stage:   name: $name");
		$self->info("  wrapped submit command: $run_command");
		$self->info("     actual user command: $command");
		my $pid = $run->_submit_command( $run_command );
		$self->info("                     pid: $pid");
		$self->_runs->{$pid} = $run;
		$run->pid( $pid );
		if ($soft_timeout) {
			$self->add_timeout( $soft_timeout, $run, 'soft_timeout' );
			$self->info("            soft timeout: $soft_timeout");
		}
		if ($hard_timeout) {
			$self->add_timeout( $hard_timeout, $run, 'hard_timeout' );
			$self->info("            hard timeout: $hard_timeout");
		}
		return $run;
	};

	method kill_stages => sub {
		my $self = shift;
		$self->info("Starting soft timeout of remaining processes");
		$self->info(Carp::longmess( "called soft_timeout" ));
		$self->_kill_stages( 'soft_timeout', 20, '_kill_stages_2' );
		$self->info("Finished soft timeout");
	};

	method _kill_stages_2 => sub {
		my $self = shift;
		$self->error("Starting hard timeout of remaining processes - soft timeout didn't complete quickly enough");
		$self->_kill_stages( 'hard_timeout', 10, '_kill_stages_timed_out' );
		$self->info("Finished kill_stages_2");
	};

	method _kill_stages_timed_out => sub {
		my $self = shift;
		$self->fatal("Hard timeout took too long - aborting");
		exit(99);
	};

	method _kill_stages => sub {
		my $self          = shift;
		my $to_job_meth   = shift;
		my $time_allot    = shift;
		my $to_kill_meth  = shift;
		my @still_running =
			grep { $_->stats->{exit_status} ne 'unknown' }
			values %{ $self->_runs };
		my $cnt = scalar(@still_running);
		$self->info(
			"sending timeout signal ($to_job_meth) to $cnt remaining stages"
		);

		if ($cnt) {
			$_->$to_job_meth for @still_running;
			$self->add_timeout( $time_allot, $self, $to_kill_meth );
			$self->next_finished_job while $cnt--;
		}
	};

};

1;
