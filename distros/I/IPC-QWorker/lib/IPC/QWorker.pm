package IPC::QWorker;
# ABSTRACT: processing a queue in parallel

use 5.000;
use strict;
use warnings;
use utf8;

our $VERSION = '0.07'; # VERSION
our $DEBUG   = 0;

use IO::Select;

use IPC::QWorker::Worker;

sub new {
    my $this  = shift;
    my $class = ref($this) || $this;
    my $self  = {
        '_workers' => [],
        '_queue'   => [],
				'_pids' => {},
				'_ready_workers' => [],
				'_io_select' => IO::Select->new(),
        @_
    };

    bless( $self, $class );
    return ($self);
}

sub create_workers {
    my $self        = shift();
    my $num_workers = shift();
		my $worker;

    for ( my $i = 0 ; $i < $num_workers ; $i++ ) {
				# create the worker
				$worker = IPC::QWorker::Worker->new(@_);
				# add him to the list of workers
        push( @{ $self->{'_workers'} }, $worker);
				# add him to the pid->workers index
				$self->{'_pids'}->{$worker->{'pid'}} = $worker;
				# add him to IO::Select
				$self->{'_io_select'}->add( $worker->{'pipe'} );
    }
}

sub push_queue {
    my $self = shift;

    push( @{ $self->{'_queue'} }, @_ );
}

sub _get_ready_workers {
		my $self = shift();
		my $timeout = shift();
		my @can_read_pipes;
		my $i;
		my $wpid;

		# if we have no ready workers find some
		@can_read_pipes = $self->{'_io_select'}->can_read($timeout);
		if ($IPC::QWorker::DEBUG) {
			print STDERR "found " . scalar(@can_read_pipes) . " ready workers!\n";
		}
		foreach $i (@can_read_pipes) {
			# get pid from a msg like "12345 READY\n"
			($wpid) = split(' ', readline($i));
			$self->{'_pids'}->{$wpid}->{'ready'} = 1;
			push(@{$self->{'_ready_workers'}}, $self->{'_pids'}->{$wpid});
		}
}

sub process_queue {
    my $self = shift;
		my $timeout = shift;
    my $qentry;
    my $worker;

		if(defined($timeout)) {
			# if timeout is set wait for timeout till a worker is ready
			$self->_get_ready_workers($timeout);
			while($worker = shift(@{$self->{'_ready_workers'}})) {
				$worker->send_entry(shift(@{ $self->{'_queue'}}));
			}
		} else {
			# loop over the Q till its empty
			# will block while waiting for ready workers
			# returns when the queue is empty
			while($qentry = shift(@{ $self->{'_queue'}})) {
		    while(!scalar(@{$self->{'_ready_workers'}})) {
					if ($IPC::QWorker::DEBUG) {
						print STDERR "no ready workers. wait for workers...\n";
					}
					$self->_get_ready_workers();
				}

				$worker = shift(@{$self->{'_ready_workers'}});
				$worker->send_entry($qentry);
			}
		}
}

sub _get_busy_workers {
		my $self = shift();
		my @result;
		my $worker;

		foreach $worker (@{$self->{'_workers'}}) {
			if(!$worker->{'ready'}) {
				push(@result, $worker);
			}
		}
		return(@result);
}

# will block till all workers are finished
sub flush_queue {
		my $self = shift();
		my @busy_workers;
		my $select = IO::Select->new();

		while(scalar(@busy_workers = $self->_get_busy_workers())) {
			if ($IPC::QWorker::DEBUG) {
				print STDERR "still " . scalar(@busy_workers) . " busy workers...\n";
			}
			$self->_get_ready_workers();
		}
}

sub stop_workers {
    my $self = shift;
    my $worker;

    # may be we could also use signals here
    foreach $worker ( @{ $self->{'_workers'} } ) {
        $worker->exit_child();
    }
}

1;
__END__

=head1 NAME

IPC::QWorker - Perl extension for processing a queue in parallel

=head1 SYNOPSIS
  
  my $qworker = IPC::QWorker->new();
  
  $qworker->create_workers(10,
          'dump' => sub { my $ctx = shift();
  							print $$.": ".Dumper(@_)."\n";
  							 $ctx->{'count'}++; },
          '_init' => sub { my $ctx = shift();	
  							$ctx->{'count'} = 0 ; },
          '_destroy' => sub { my $ctx = shift();
  							print $$.": did ".$ctx->{'count'}." operations!\n"; }
  );
          
  foreach $i (1..120) {
          $qworker->push_queue(IPC::QWorker::WorkUnit->new(
                  'cmd' => 'dump',
                  'params' => $i,
          ));
  }
  
  $qworker->process_queue();

	# wait till queue is emtpy
  $qworker->flush_queue();
	# then stop all workers
  $qworker->stop_workers();

=head1 ABSTRACT

  This Module creates a group of child processes and feeds them with data
  from a queue.

=head1 DESCRIPTION

  With this module you can fork a few child processes which know a few
  function calls you define while creating them.
  Later you can pass command with parameters into the queue which is
  distributed across the child processes thru pipes(with the Storable module).

=head2 EXPORT

None by default.

=head1 SEE ALSO

  perl, POSIX, Storable, IO::Select

=head1 AUTHOR

Markus Benning, E<lt>me@w3r3wolf.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2013 by Markus Benning <me@w3r3wolf.de>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

# vim:ts=2:syntax=perl:
# vim600:foldmethod=marker:
