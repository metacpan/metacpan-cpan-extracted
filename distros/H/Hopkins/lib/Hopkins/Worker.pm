package Hopkins::Worker;

use strict;

=head1 NAME

Hopkins::Worker - hopkins worker session

=head1 DESCRIPTION

Hopkins::Worker encapsulates a POE session created by
Hopkins::Queue->spawn_worker via POE::Component::JobQueue.

=cut

use base 'Class::Accessor::Fast';

use POE;
use POE::Filter::Reference;
use POE::Wheel::Run;
use Class::Accessor::Fast;

use YAML;

use Hopkins::Worker::Native;

__PACKAGE__->mk_accessors(qw(alias postback work child status timer));

use constant HOPKINS_WORKER_MAX_STATUS_WAIT => 10;

=head1 STATES

=over 4

=item spawn

=cut

sub new
{
	my $self = shift->SUPER::new(@_);

	my $method = $self->work->task->class ? 'perl' : 'exec';
	my $source = $self->work->task->class || $self->work->task->cmd;

	Hopkins->log_debug("spawning worker: type=$method; source=$source");

	POE::Session->create
	(
		object_states =>
		[
			$self =>
			{
				_start		=> 'start',
				_stop		=> 'stop',

				execute		=> 'execute',
				terminate	=> 'terminate',
				stdout		=> 'stdout',
				stderr		=> 'stderr',
				done		=> 'done',
				statuswait	=> 'statuswait',
				reap		=> 'reap',
				shutdown	=> 'shutdown'
			}
		]
	);

	return $self;
}

=item start

=cut

sub start
{
	my $self		= $_[OBJECT];
	my $kernel		= $_[KERNEL];

	$self->work->worker($self);
	$self->work->date_started(DateTime->now(time_zone => 'local'));

	$kernel->post(store => notify => task_started => $self->work->serialize);

	# set the name of this session's alias based on the queue and session ID
	my $session = $kernel->get_active_session;

	$self->alias(join '.', $self->work->queue->alias, 'worker', $session->ID);
	$kernel->alias_set($self->alias);

	Hopkins->log_debug('worker session created');

	$kernel->post($self->alias => 'execute');
}

sub execute
{
	my $self		= $_[OBJECT];
	my $kernel		= $_[KERNEL];

	# determine the Program argument based upon what method
	# we're using.  POE::Wheel::Run will execute both native
	# perl code as well as external binaries depending upon
	# whether the argument is a coderef or a simple scalar.

	my $program = $self->work->task->class
		? new Hopkins::Worker::Native { work => $self->work }
		: $self->work->task->cmd;

	# construct the arguments neccessary for POE::Wheel::Run

	my %args =
	(
		Program			=> $program,
		StdoutEvent		=> 'stdout',
		StderrEvent		=> 'stderr',
		StdoutFilter	=> new POE::Filter::Reference 'YAML'
	);

	# after making sure to setup appropriate signal handlers
	# beforehand, spawn the actual worker in a child process
	# via POE::Wheel::Run.  this protects us from code that
	# may potentially block POE for a very long time.  it
	# also isolates hopkins from code that would otherwise
	# be able to alter the running environment.

	$kernel->sig(CHLD => 'done');
	$self->child(new POE::Wheel::Run %args);
}

sub stop
{
	my $self	= $_[OBJECT];
	my $kernel	= $_[KERNEL];
	my $heap	= $_[HEAP];

	Hopkins->log_debug('session destroyed');
}

sub done
{
	my $self	= $_[OBJECT];
	my $kernel	= $_[KERNEL];
	my $signal	= $_[ARG0];
	my $pid		= $_[ARG1];
	my $status	= $_[ARG2];

	return if $pid != $self->child->PID;

	Hopkins->log_debug("child process $pid exited with status $status");

	$self->timer(time);
	$self->child(undef);

	$kernel->sig('CHLD');
	$kernel->post($self->alias => 'statuswait');

	if ($self->work->task->cmd) {
		$self->status({}) unless $self->status;

		$self->status->{error} = "command exited with status $status"
			if $status != 0;
	}
}

sub statuswait
{
	my $self	= $_[OBJECT];
	my $kernel	= $_[KERNEL];

	return $kernel->post($self->alias => 'reap') if $self->status;

	if (time > $self->timer + HOPKINS_WORKER_MAX_STATUS_WAIT) {
		use Data::Dumper;
		$Data::Dumper::Indent = 1;
		Hopkins->log_error('worker did not report a status!');
		Hopkins->log_error(Dumper $self);

		$kernel->yield('shutdown');
	} else {
		$kernel->alarm(statuswait => time + 1);
	}
}

sub reap
{
	my $self	= $_[OBJECT];
	my $kernel	= $_[KERNEL];

	my $task = $self->work->task->name;

	if ($self->status->{error}) {
		Hopkins->log_error("worker failure executing $task");
		$kernel->call(manager => queue_failure => $self->work->queue, $self->status->{error});
		$self->work->succeeded(0);
	} else {
		if ($self->status->{terminated}) {
			Hopkins->log_info("worker terminated executing $task");
			$self->work->aborted(1);
		} else {
			Hopkins->log_info("worker successfully executed $task");
			$self->work->succeeded(1);
		}
	}

	$kernel->yield('shutdown');
}

sub terminate
{
	my $self	= $_[OBJECT];
	my $kernel	= $_[KERNEL];

	$self->child->kill;
}

sub shutdown
{
	my $self	= $_[OBJECT];
	my $kernel	= $_[KERNEL];

	# use the postback to inform the JobQueue component that
	# we have finished executing.

	$self->postback->(); # ($pid, $status);

	# we have to remove the session alias from the kernel,
	# else POE will never destroy the session.

	$kernel->alias_remove($self->alias);
}

sub stdout
{
	my $self = $_[OBJECT];

	$self->work->task->class
		? $self->status($_[ARG0])
		: Hopkins->log_worker_stdout($self->work->task->name, $_[ARG0]);
}

sub stderr
{
	my $self = $_[OBJECT];

	Hopkins->log_worker_stderr($self->work->task->name, $_[ARG0]);

	$self->work->output(($self->work->output || '') . $_[ARG0]);
}

=back

=head1 AUTHOR

Mike Eldridge <diz@cpan.org>

=head1 LICENSE

This program is free software; you may redistribute it
and/or modify it under the same terms as Perl itself.

=cut

1;
