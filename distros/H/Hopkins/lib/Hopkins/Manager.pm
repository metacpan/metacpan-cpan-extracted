package Hopkins::Manager;

use strict;

=head1 NAME

Hopkins::Manager - hopkins manager session states

=head1 DESCRIPTION

Hopkins::Manager encapsulates the manager session, which is
responsible for configuration parsing and change scanning,
queue and plugin management, and last, but certainly not
least, task scheduling.

=cut

use POE;
use Class::Accessor::Fast;

use Data::UUID;
use Path::Class::Dir;

use Hopkins::Store;
use Hopkins::Config;
use Hopkins::Queue;
use Hopkins::Task;
use Hopkins::Work;

use Hopkins::Constants;

use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw(kernel hopkins config plugins queues));

my $ug = new Data::UUID;

=head1 STATES

=over 4

=item new

=cut

sub new
{
	my $self = shift->SUPER::new(@_);

	$self->plugins({});
	$self->queues({});
	$self->kernel($poe_kernel);

	# create the POE Session that will be the bread and butter
	# of the job daemon's normal function.  the manager session
	# will read the configuration upon execution and will begin
	# the rest of the startup process in the following order:
	#
	#	- storage initialization via DBIx::Class
	#	- queue creation via POE::Component::JobQueue
	#	- RPC session creation via POE::Component::Server::SOAP

	# create manager session
	POE::Session->create
	(
		object_states =>
		[
			$self =>
			{
				_start			=> 'start',
				_stop			=> 'stop',

				config_scan		=> 'config_scan',
				config_load		=> 'config_load',

				init_config		=> 'init_config',
				init_queues		=> 'init_queues',
				init_plugins	=> 'init_plugins',
				init_store		=> 'init_store',

				queue_check_all	=> 'queue_check_all',
				queue_check		=> 'queue_check',
				queue_failure	=> 'queue_failure',
				queue_start		=> 'queue_start',
				queue_halt		=> 'queue_halt',
				queue_continue	=> 'queue_continue',
				queue_freeze	=> 'queue_freeze',
				queue_thaw		=> 'queue_thaw',
				queue_shutdown	=> 'queue_shutdown',
				queue_flush		=> 'queue_flush',

				scheduler		=> 'scheduler',
				executor		=> 'executor',
				enqueue			=> 'enqueue',
				complete		=> 'complete',
				abort			=> 'abort',

				shutdown		=> 'shutdown'
			}
		]
	);

	return $self;
}

=item start

=cut

sub start
{
	my $self	= $_[OBJECT];
	my $kernel	= $_[KERNEL];

	# set the alias for the current session
	$kernel->alias_set('manager');

	# log that we are starting up
	Hopkins->log_info("starting hopkins version $Hopkins::VERSION");

	# post events for initial setup
	$kernel->call(manager => 'init_config');	# configuration file
	$kernel->post(manager => 'init_store');		# database storage sessage
	$kernel->post(manager => 'init_queues');	# worker queue sessions
}

=item stop

=cut

sub stop
{
	my $self = $_[OBJECT];

	Hopkins->log_debug('manager exiting');
}

=item init_queues

=cut

sub init_queues
{
	my $self	= $_[OBJECT];
	my $kernel	= $_[KERNEL];

	Hopkins->log_info('creating queues');

	# create a queue object for each configured queue.  we
	# use an active POE::Component::JobQueue and leave the
	# scheduling up to the manager session.

	foreach my $name ($self->config->get_queue_names) {
		my $opts	= $self->config->get_queue_info($name);
		my $queue	= new Hopkins::Queue { kernel => $kernel, config => $self->config, %$opts };

		$self->queues->{$name} = $queue;

		$kernel->post(manager => queue_start => $name) unless $queue->halted;
	}
}

sub queue_start
{
	my $self	= $_[OBJECT];
	my $name	= $_[ARG0];
	my $queue	= $self->queue($name);

	return HOPKINS_QUEUE_NOT_FOUND if not defined $queue;

	return $queue->start;
}

sub queue_halt
{
	my $self	= $_[OBJECT];
	my $name	= $_[ARG0];
	my $queue	= $self->queue($name);

	return HOPKINS_QUEUE_NOT_FOUND if not defined $queue;

	return $queue->halt;
}

sub queue_continue
{
	my $self	= $_[OBJECT];
	my $name	= $_[ARG0];
	my $queue	= $self->queue($name);

	return HOPKINS_QUEUE_NOT_FOUND if not defined $queue;

	return $queue->continue;
}

sub queue_freeze
{
	my $self	= $_[OBJECT];
	my $name	= $_[ARG0];
	my $queue	= $self->queue($name);

	return HOPKINS_QUEUE_NOT_FOUND if not defined $queue;

	return $queue->freeze;
}

sub queue_thaw
{
	my $self	= $_[OBJECT];
	my $name	= $_[ARG0];
	my $queue	= $self->queue($name);

	return HOPKINS_QUEUE_NOT_FOUND if not defined $queue;

	return $queue->thaw;
}

sub queue_flush
{
	my $self	= $_[OBJECT];
	my $name	= $_[ARG0];
	my $queue	= $self->queue($name);

	return HOPKINS_QUEUE_NOT_FOUND if not defined $queue;

	return $queue->flush;
}

sub queue_shutdown
{
	my $self	= $_[OBJECT];
	my $name	= $_[ARG0];
	my $queue	= $self->queue($name);

	return HOPKINS_QUEUE_NOT_FOUND if not defined $queue;

	return $queue->shutdown;
}

sub queue_check
{
	my $self	= $_[OBJECT];
	my $name	= $_[ARG0];

	return $self->queues->{$name};
}

sub queue_check_all
{
	my $self = $_[OBJECT];

	return values %{ $self->queues };
}

=item queue_failure

=cut

sub queue_failure
{
	my $self	= $_[OBJECT];
	my $kernel	= $_[KERNEL];
	my $queue	= $_[ARG0];
	my $error	= $_[ARG1];

	my $msg = 'task failure in ' . $queue->name . ' queue';

	if (my $action = $queue->onerror) {
		$queue->$action($error);
	}

	$queue->error($error);

	Hopkins->log_warn($msg);
}

=item init_store

=cut

sub init_store
{
	my $self = shift;

	new Hopkins::Store { config => $self->config };
}

=item init_config

=cut

sub init_config
{
	my $self	= $_[OBJECT];
	my $kernel	= $_[KERNEL];

	my $class = 'Hopkins::Config::' . $self->hopkins->conf->[0];

	eval "use $class";

	if (my $err = $@) {
		Hopkins->log_error("unable to load config class: $err");
		return $kernel->post(manager => 'shutdown');
	}

	eval {
		$self->config($class->new($self->hopkins->conf->[1]));
		die 'constructor did not return a Hopkins::Config object'
			if not UNIVERSAL::isa($self->config, 'Hopkins::Config');
	};

	if (my $err = $@) {
		Hopkins->log_error("unable to create config object: $err");
		return $kernel->post(manager => 'shutdown');
	}

	$kernel->call(manager => 'config_load');
	$kernel->alarm(config_scan => time + $self->hopkins->scan);
}

=item init_plugins

=cut

sub init_plugins
{
	my $self	= $_[OBJECT];
	my $kernel	= $_[KERNEL];

	Hopkins->log_info('loading plugins');

	my $config	= $self->config;
	my $plugins	= $self->plugins;

	delete $plugins->{$_}
		foreach grep { not $config->has_plugin($_) } keys %$plugins;

	foreach my $name ($config->get_plugin_names) {
		if (not exists $plugins->{$name}) {
			my $options	= $config->get_plugin_info($name);
			my $package = $name =~ /^\+/ ? $name : "Hopkins::Plugin::$name";
			my $path	= $package;

			$path =~ s{::}{/}g;

			eval {
				require "$path.pm";

				my $plugin = $package->new({ manager => $self, config => $options });

				$plugins->{$name} = $plugin;
			};

			Hopkins->log_error("failed to load plugin $name: $@") if $@;
		}
	}
}

=item config_load

=cut

sub config_load
{
	my $self	= $_[OBJECT];
	my $kernel	= $_[KERNEL];

	my $status	= $self->config->load;

	$kernel->post(manager => 'shutdown') unless $status->ok;

	if ($status->failed) {
		my $err = $status->parsed
			? 'errors in configuration, discarding new version'
			: 'unable to load configuration: ' . $status->errmsg;

		Hopkins->log_error($err);
	}

	$kernel->post(manager => 'shutdown') if not $self->config->loaded;

	return unless $status->updated;

	Hopkins->log_info('configuration loaded');

	if ($status->store_modified) {
		Hopkins->log_info('store information changed');
		$kernel->post(store => 'init');
	}

	$kernel->alarm('executor');

	$kernel->post(manager => 'init_plugins');
	$kernel->post(manager => 'scheduler');
}

=item config_scan

=cut

sub config_scan
{
	my $self	= $_[OBJECT];
	my $kernel	= $_[KERNEL];

	if ($self->config->scan) {
		Hopkins->log_info('configuration file changed');
		$kernel->post(manager => 'config_load')
	}

	$kernel->alarm(config_scan => time + $self->hopkins->scan);
}

=item shutdown

=cut

sub shutdown
{
	my $self	= $_[OBJECT];
	my $kernel	= $_[KERNEL];

	Hopkins->log_info('received shutdown request');

	$kernel->alarm('executor');
	$kernel->alarm('config_scan');

	foreach my $name ($self->config->get_queue_names) {
		Hopkins->log_debug("posting stop event for $name queue");
	    $kernel->post(manager => queue_halt => $name);
	}

	$kernel->post(store => 'shutdown');
	$kernel->alias_remove('manager');
}

=item scheduler

=cut

sub scheduler
{
	my $self	= $_[OBJECT];
	my $kernel	= $_[KERNEL];

	my $now = DateTime->now(time_zone => 'local');

	$now->truncate(to => 'seconds');

	foreach my $name ($self->config->get_task_names) {
		my $task = $self->config->get_task_info($name);

		next if not defined $task->schedule;
		next if not $task->enabled;

		my $next = $task->schedule->next($now);

		Hopkins->log_debug('scheduling ' . $task->name . ' for ' . $next->iso8601);

		$kernel->alarm_add(executor => $next->epoch => $task);
	}
}

=item executor

=cut

sub executor
{
	my $self	= $_[OBJECT];
	my $kernel	= $_[KERNEL];
	my $task	= $_[ARG0];

	Hopkins->log_debug('executor alarm for ' . $task->name);

	my $now		= DateTime->now(time_zone => 'local');

	Hopkins->log_debug('current time: ' . $now->iso8601);

	my $state	= $kernel->call(manager => enqueue => $task->name => $task->params);
	my $next	= $task->schedule->next($now);

	Hopkins->log_error('failed to enqueue ' . $task->name) if not $state;

	Hopkins->log_debug('scheduling ' . $task->name . ' for ' . $next->iso8601);

	$kernel->alarm_add(executor => $next->epoch => $task);
}

=item enqueue

enqueue a task by creating a Work object and adding it to
the destination Queue object's list.  if the destination
queue is not running, no Work will be created and an error
0 will be returned to the caller.

this state may be posted to by any session, but is primarily
utilized by the manager session's executor alarms.  the RPC
plugin exposes an enqueue method via SOAP that posts to this
event.  the HMI plugin also exposes an enqueuing mechanism
via a web interface.

=cut

sub enqueue
{
	my $self	= $_[OBJECT];
	my $kernel	= $_[KERNEL];
	my $name	= $_[ARG0];
	my $topts	= $_[ARG1];
	my $qopts	= $_[ARG2] || {};

	my $task	= $self->config->get_task_info($name);
	my $now		= DateTime->now(time_zone => 'local');
	my $when	= $qopts->{when} || $now;
	my $pri		= $qopts->{priority} || 5;

	# make sure the Task exists

	if (not defined $task) {
		Hopkins->log_warn("unable to enqueue $name; task not found");
		return HOPKINS_ENQUEUE_TASK_NOT_FOUND;
	}

	# ensure that the Task's queue exists

	my $queue = $self->queue($task->queue);

	if (not defined $queue) {
		Hopkins->log_warn("unable to enqueue $name; queue " . $task->queue . ' not found');
		return HOPKINS_ENQUEUE_QUEUE_UNAVAILABLE;
	}

	# ensure that the queue is not frozen

	if ($queue->frozen) {
		Hopkins->log_warn("unable to enqueue $name; queue " . $task->queue . ' frozen');
		return HOPKINS_ENQUEUE_QUEUE_FROZEN;
	}

	# ensure that the requested start time is sane

	if ($when and not UNIVERSAL::isa($when, 'DateTime')) {
		eval { $when = DateTime::Format::ISO8601->parse_datetime($when) };
		if ($@) {
			Hopkins->log_warn("unable to enqueue $name; invalid date/time specified");
			return HOPKINS_ENQUEUE_DATETIME_INVALID;
		}
	}

	# ensure that we don't stack tasks if requested

	if ($task->stack && $when <= $now && $task->stack <= $queue->num_queued($task)) {
		Hopkins->log_warn("unable to enqueue $name; stack limit reached");
		return HOPKINS_ENQUEUE_TASK_STACK_LIMIT;
	}

	# all of our sanity checks have passed.  looks like we
	# are good to queue up some work for the queue!  create
	# and populate a new Work object.  assigning a new UUID
	# to the work so that we can reference it later.

	my $work = new Hopkins::Work;

	$work->id($ug->create_str);
	$work->task($task);
	$work->queue($queue);
	$work->options($topts);
	$work->priority($pri);
	$work->date_enqueued($now);
	$work->date_to_execute($when);

	# pass the Work to the Queue for enqueuing

	$queue->enqueue($work);

	Hopkins->log_debug("enqueued task $name (" . $work->id . ')');

	# notify the Store that we've enqueued a task

	$kernel->post(store => notify => task_enqueued => $work->serialize);

	return HOPKINS_ENQUEUE_OK;
}

sub complete
{
	my $self	= $_[OBJECT];
	my $kernel	= $_[KERNEL];
	my $work	= $_[ARG0]->[0];

	Hopkins->log_debug('completed task ' . $work->task->name . ' (' . $work->id . ')');

	$work->date_completed(DateTime->now(time_zone => 'local'));

	$work->queue->dequeue($work);

	$kernel->post(store => notify => task_completed => $work->serialize);
}

sub abort
{
	my $self	= $_[OBJECT];
	my $kernel	= $_[KERNEL];
	my $name	= $_[ARG0];
	my $id		= $_[ARG1];

	my $queue	= $self->queue($name)	or return;
	my $work	= $queue->find($id)		or return;

	Hopkins->log_debug('aborting task ' . $work->task->name . ' (' . $work->id . ')');

	if ($work->worker) {
		$kernel->post($work->worker->alias => 'terminate');
	} else {
		$queue->dequeue($work);
		$work->aborted(1);

		$kernel->post(store => notify => task_completed => $work->serialize);
	}
}

sub queue
{
	my $self = shift;
	my $name = shift;

	return $self->queues->{$name};
}

=back

=head1 AUTHOR

Mike Eldridge <diz@cpan.org>

=head1 LICENSE

=cut

1;
