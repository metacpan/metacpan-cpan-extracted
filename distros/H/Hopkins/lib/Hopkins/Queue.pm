package Hopkins::Queue;

use strict;

=head1 NAME

Hopkins::Queue - hopkins queue states and methods

=head1 DESCRIPTION

Hopkins::Queue contains all of the POE event handlers and
supporting methods for the initialization and management of
each configured hopkins queue.

=cut

use POE;
use Class::Accessor::Fast;

use Cache::FileCache;
use DateTime::Format::ISO8601;
use Tie::IxHash;

use Hopkins::Constants;
use Hopkins::Worker;
use Hopkins::Work;

use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw(kernel config cache name alias onerror onfatal concurrency works halted frozen error));

=head1 STATES

=over 4

=item new

=cut

sub new
{
	my $self = shift->SUPER::new(@_);

	Hopkins->log_debug('creating queue ' . $self->name);

	$self->alias('queue.' . $self->name);
	$self->works(new Tie::IxHash);

	$self->onerror(undef)
		unless $self->onerror
		and grep { $self->onerror eq $_ } qw(halt freeze shutdown flush);

	$self->cache(new Cache::FileCache {
		cache_root		=> $self->config->fetch('state/root')->stringify,
		namespace		=> 'queue/' . $self->name,
		directory_umask	=> 0077
	});

	$self->read_state;
	$self->write_state;

	return $self;
}

sub read_state
{
	my $self = shift;

	$self->frozen($self->cache->get('frozen') ? 1 : 0);
	$self->halted($self->cache->get('halted') ? 1 : 0);
	$self->error($self->cache->get('error'));

	my $aref = $self->cache->get('works');

	return if not ref $aref eq 'ARRAY';

	foreach my $href (@$aref) {
		my $work = new Hopkins::Work;
		my $date = undef;

		$work->queue($self);
		$work->options($href->{options});

		if (my $id = $href->{id}) {
			$work->id($id);
		} else {
			Hopkins->log_error('unable to determine task ID when reading state');
			next;
		}

		if (my $date = Hopkins->parse_datetime($href->{date_enqueued})) {
			$work->date_enqueued($date);
		} else {
			Hopkins->log_error('unable to parse date/time information when reading state');
		}

		# FIXME: date_to_execute not yet implemented

		if (my $date = Hopkins->parse_datetime($href->{date_to_execute})) {
			$work->date_to_execute($date);
		} else {
			#Hopkins->log_error('unable to parse date/time information when reading state');
			$work->date_to_execute(DateTime->now(time_zone => 'local'));
		}

		if (my $val = $href->{date_started}) {
			if (my $date = Hopkins->parse_datetime($href->{date_started})) {
				$work->date_started($date);
			} else {
				Hopkins->log_error('unable to parse date/time information when reading state');
			}
		}

		# attempt to locate the referenced task.  if the
		# configuration has changed and we can't locate the
		# referenced task, we'll want to halt the queue
		# until an operator can take a look at it.

		if (my $task = $self->config->get_task_info($href->{task})) {
			$work->task($task);
		} else {
			Hopkins->log_error("unable to locate task '$href->{task}' when reading state");

			$self->kernel->post(store => notify => task_aborted => $work->serialize);
		}

		# if the task was already started or has an invalid
		# vconfiguration, mark it as orphaned.  otherwise,
		# go ahead and queue it up for execution.

		if ($work->date_started or not defined $work->task) {
			$self->kernel->post(store => notify => task_orphaned => $work->serialize);
		} else {
			$self->enqueue($work, write => 0);
		}
	}
}

sub spawn
{
	my $self = shift;

	Hopkins->log_debug('spawning queue ' . $self->name);

	# this passive queue will act as an on-demand task
	# execution queue, waiting for enqueue events to be
	# posted to the kernel.

	#POE::Component::JobQueue->spawn
	#(
	#	Alias		=> $self->alias,
	#	WorkerLimit	=> $self->concurrency,
	#	Worker		=> sub { $self->spawn_worker(@_) },
	#	Passive		=> { Prioritizer => \&Hopkins::Queue::prioritize },
	#);

	#foreach my $work ($self->tasks->Values) {
	#	$self->kernel->post($self->alias => enqueue => dequeue => $work);
	#}

	# this active queue will poll hopkins periodically,
	# checking the parent Hopkins::Queue object for new
	# tasks to spawn.

	POE::Component::JobQueue->spawn
	(
		Alias		=> $self->alias,
		WorkerLimit	=> $self->concurrency,
		Worker		=> sub { $self->fetch_and_spawn_worker(@_) },
		Active		=>
		{
			#PollInterval	=> $global->{poll},
			PollInterval	=> 15,
			AckAlias		=> 'manager',
			AckState		=> 'complete'
		}
	);
}

=item contents

=cut

sub contents
{
	my $self = shift;
	my $args = ref $_[0] eq 'HASH' ? shift : { @_ };

	my $date	= $args->{executing};
	my @works	= $self->works->Values;

	return $date ? grep { $_->date_to_execute < $date } @works : @works;
}

=item find

=cut

sub find
{
	my $self	= shift;
	my $id		= shift;

	return $self->works->FETCH($id);
}

=item enqueue

=cut

sub enqueue
{
	my $self = shift;
	my $work = shift;
	my $args = { @_ };

	$self->works->Push($work->id => $work);
	$self->write_state unless $args->{write} and $args->{write} == 0;
}

=item dequeue

=cut

sub dequeue
{
	my $self = shift;
	my $work = shift;
	my $args = { @_ };

	my $id = UNIVERSAL::isa($work, 'Hopkins::Work') ? $work->id : $work;

	$self->works->Delete($id);
	$self->write_state unless $args->{write} and $args->{write} == 0;
}

=item write_state

write the queue's state to disk.

=cut

sub write_state
{
	my $self = shift;

	$self->cache->set(frozen => $self->frozen);
	$self->cache->set(halted => $self->halted);
	$self->cache->set(error => $self->error);
	$self->cache->set(works => [ map { $_->serialize } $self->works->Values ]);
}

=item stop

stops the queue, shutting down the PoCo::JobQueue session
if running by sending a stop event to it.

=cut

sub stop
{
	my $self = shift;

	$self->kernel->post($self->alias => 'stop') if $self->kernel;
}

=item spawn_worker

=cut

sub spawn_worker
{
	my $self = shift;

	my $args =
	{
		postback	=> shift,
		work		=> shift,
		queue		=> $self
	};

	new Hopkins::Worker $args;
}

=item fetch_and_spawn_worker

=cut

sub fetch_and_spawn_worker
{
	my $self		= shift;
	my $postback	= shift;

	return if $self->halted;

	#Hopkins->log_debug('polling ' . $self->name . ' queue for tasks to execute');

	my $now		= DateTime->now(time_zone => 'local');
	my @work	=
		sort Hopkins::Queue::prioritize
		grep { not defined $_->worker and $_->date_to_execute < $now }
		$self->works->Values;

	if (my $work = shift @work) {
		my $args =
		{
			postback	=> $postback->($work),
			work		=> $work,
			queue		=> $self
		};

		new Hopkins::Worker $args;
	}
}

=item prioritize

=cut

sub prioritize
{
	my $apri = $a->priority;
	my $bpri = $b->priority;

	$apri = 1 if $apri < 1;
	$apri = 9 if $apri > 9;
	$bpri = 1 if $bpri < 1;
	$bpri = 9 if $bpri > 9;

	return $apri <=> $bpri;
}

=item is_running

=cut

sub is_running
{
	my $self = shift;
	my $name = shift;

	return Hopkins->is_session_active($self->alias);
}

=item status

=cut

sub status
{
	my $self = shift;

	return HOPKINS_QUEUE_STATUS_HALTED	if $self->halted;
	return HOPKINS_QUEUE_STATUS_RUNNING	if $self->works->Length > 0;

	return HOPKINS_QUEUE_STATUS_IDLE;
}

=item status_string

=cut

sub status_string
{
	my $self = shift;

	for ($self->status) {
		$_ == HOPKINS_QUEUE_STATUS_IDLE && return 'idle';

		#$_ == HOPKINS_QUEUE_STATUS_RUNNING && $self->frozen
		#	&& return 'running (frozen)';

		#$_ == HOPKINS_QUEUE_STATUS_HALTED && $self->frozen
		#	&& return 'halted (frozen)';

		$_ == HOPKINS_QUEUE_STATUS_RUNNING		&& return 'running';
		$_ == HOPKINS_QUEUE_STATUS_HALTED		&& return 'halted';
	}
}

=item num_queued

=cut

sub num_queued
{
	my $self = shift;
	my $task = shift;

	return $self->works->Length if not defined $task;

	if (not ref $task eq 'Hopkins::Task') {
		Hopkins->log_warn('Hopkins::Queue->num_queued called with argument that is not a Hopkins::Task object');
		return 0;
	}

	return scalar grep { $_->task->name eq $task->name } $self->works->Values
}

=item start

=cut

sub start
{
	my $self = shift;

	$self->error(undef);
	$self->halted(0);

	return HOPKINS_QUEUE_ALREADY_RUNNING if $self->is_running;

	$self->spawn;

	return HOPKINS_QUEUE_STARTED;
}

=item halt

halts the queue.  no tasks will be executed, although tasks
may still be enqueued.

=cut

sub halt
{
	my $self = shift;

	$self->halted(1);
}

=item continue

reverses the action of halt by starting the queue back up.
the existing state of the frozen flag will be preserved.

=cut

sub continue
{
	my $self = shift;

	$self->halted(0);
}

=item freeze

freezes the queue.  no more tasks will be enqueued, but
currently queued tasks will be allowed to execute.

=cut

sub freeze
{
	my $self = shift;

	$self->frozen(1);
}

=item thaw

reverses the action of freeze by unsetting the frozen flag.
tasks will not be queable.  the existing halt state will be
preserved.

=cut

sub thaw
{
	my $self = shift;

	$self->frozen(0);
}

=item shutdown

shuts the queue down.  this is basically a shortcut for the
freeze and halt actions.  no more tasks will be executed and
no further tasks may be enqueud.

=cut

sub shutdown
{
	my $self = shift;

	$self->freeze;
	$self->halt;
}

=item flush

flush the queue of any tasks waiting to execute.  stops the
PoCo::JobQueue session (if running) and clears the internal
list of tasks.  if the queue was running prior to the flush,
the PoCo::JobQueue session is spun back up.

=cut

sub flush
{
	my $self = shift;

	$self->stop;
	$self->works->Delete($self->works->Keys);
	$self->start if not $self->halted;
}

=item DESTROY

=cut

sub DESTROY { shift->shutdown }

=back

=head1 AUTHOR

Mike Eldridge <diz@cpan.org>

=head1 LICENSE

This program is free software; you may redistribute it
and/or modify it under the same terms as Perl itself.

=cut

1;
