package Hopkins::Store::Backend;

use strict;
use warnings;

=head1 NAME

Hopkins::Store::Backend - synchronous database services

=head1 DESCRIPTION

Hopkins::Store::Backend encapsulates database functionality
in a simple event loop.  no POE services are utilized in the
event processing -- the loop is spawned off in a separate
process via POE::Child::Run in order to provide asynchronous
operation.  hence, database queries may block in the backend
without affecting the rest of hopkins.

Store::Backend communicates with the store session in the
parent process via message passing on stdin/stdout.  these
messages are YAML encoded via POE::Filter::Reference.

=cut

use Class::Accessor::Fast;
use POE::Filter::Reference;

use Hopkins::Store::Schema;

use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw(config filter schema));

=head1 METHODS

=over 4

=item new

create a new Hopkins::Store::Backend object for processing
requests received on STDIN.  under normal operations, this
constructor will return.  it will, however, return if there
are any errors processing events.

=cut

sub new
{
	my $self = shift->SUPER::new(@_);

	open STATUS, '>&STDOUT';
	open STDOUT, '>&STDERR';

	autoflush STATUS 1;

	$self->filter(new POE::Filter::Reference 'Storable');

	$self->connect and $self->loop;
}

=item connect

connects the schema's storage backend to the data source
described by the config object passed to the constructor.
this method returns the resulting schema object or undef
if there was an error.

=cut

sub connect
{
	my $self = shift;

	$self->schema(undef);

	my $config	= $self->config->fetch('database');
	my $dsn		= $config->{dsn};
	my $user	= $config->{user};
	my $pass	= $config->{pass};
	my $opts	= $config->{options};

	if (not defined $dsn) {
		Hopkins->log_error('database/dsn not specified');
		return undef;
	}

	Hopkins->log_debug("attempting to connect to $dsn as $user");

	# attempt to connect to the schema.  gracefully handle
	# any exceptions that may occur.

	my $schema;

	eval {
		# DBIx::Class is lazy.  it will wait until the last
		# possible moment to connect to the database.  this
		# prevents unnecessary database connections, but we
		# but we want to immediately and gracefully handle
		# any errors, so we force the connection now with
		# the storage object's ensure_connected method.

		$schema = Hopkins::Store::Schema->connect($dsn, $user, $pass, $opts);
		$schema->storage->ensure_connected;
	};

	# if the connection was successful, supply the schema
	# object to the Store::Backend object.

	if (my $err = $@) {
		Hopkins->log_error("failed to connect to schema: $err");
	} else {
		Hopkins->log_debug('successfully connected to schema');
		$self->schema($schema);
	}

	return $self->schema;
}

=item connected

checks to make sure that the schema's storage backend is
connected to the data source.  returns a truth value
indicating whether or not the schema is connected.

=cut

sub connected
{
	my $self = shift;

	my $ok = $self->schema->storage->ensure_connected ? 1 : 0;

	Hopkins->log_error('lost connection to database') if not $ok;

	return $ok;
}

=item loop

main event processing loop.  reads lines from STDIN and
passes them to POE::Filter for decoding.  each decoded
item is passed to the process method individually for
further processing.

under normal operating conditions, this method will never
return.  however, if processing of an individual item fails,
this method will return to its caller, resulting in the
destruction of the Store::Backend object.

=cut

sub loop
{
	my $self = shift;

	while (my $line = <STDIN>) {
		my $aref = $self->filter->get([ $line ]);

		foreach my $href (@$aref) {
			$self->process($href) or return;
		}
	}
}

=item process

process an action or event received from STDIN by the loop
method.  process will return a boolean value indicating the
success or failure of the processing.

=cut

sub process
{
	my $self = shift;
	my $href = shift;

	$self->connected or return 0;

	if ($href->{event}) {
		return $self->process_event($href->{event});
	}

	return 1;
}

=item process_event

process an event received from STDIN.  this method will
dispatch the event to an appropriate method as indicated
by the event name.  if Store::Backend does not have an
appropriate method to handle the event, it will be ignored.
if the event is successfully processed, the Store session
will be notified by sending a message on STDOUT.

=cut

sub process_event
{
	my $self	= shift;
	my $href	= shift;

	my $id		= $href->{id};
	my $aref	= $href->{contents};
	my $event	= $aref->[0];
	my $method	= "process_event_$event";

	if ($self->can($method) && $self->$method(@$aref[1..$#{$aref}])) {
		print STATUS $_
			foreach @{ $self->filter->put([ { eventproc => { id => $id } } ]) };
	}

	return 1;
}

=item process_event_task_enqueued

a task was enqueued: record it in the database

=cut

sub process_event_task_enqueued
{
	my $self = shift;
	my $href = shift;

	my $rsTask	= $self->schema->resultset('Task');
	my $task	= $rsTask->find_or_create({ id => $href->{id} });

	$task->name($href->{task}) if not defined $task->name;
	$task->queue($href->{queue}) if not defined $task->queue;
	$task->date_enqueued($href->{date_enqueued});
	$task->date_to_execute($href->{date_to_execute});

	$task->update;
}

=item process_event_task_started

a task was started: record it in the database

=cut

sub process_event_task_started
{
	my $self = shift;
	my $href = shift;

	my $rsTask	= $self->schema->resultset('Task');
	my $task	= $rsTask->find_or_create({ id => $href->{id} });

	$task->name($href->{task}) if not defined $task->name;
	$task->queue($href->{queue}) if not defined $task->queue;
	$task->started(1);
	$task->date_started($href->{date_started});

	$task->update;
}

=item process_event_task_completed

a task was completed: record it in the database

=cut

sub process_event_task_completed
{
	my $self = shift;
	my $href = shift;

	my $rsTask	= $self->schema->resultset('Task');
	my $task	= $rsTask->find_or_create({ id => $href->{id} });

	$task->name($href->{task}) if not defined $task->name;
	$task->queue($href->{queue}) if not defined $task->queue;
	$task->completed(1);
	$task->succeeded($href->{succeeded});
	$task->failed($href->{failed});
	$task->aborted($href->{aborted});
	$task->date_completed($href->{date_completed});
	$task->create_related(output => { text => $href->{output} })
		if defined $href->{output};

	$task->update;
}

=item process_event_task_orphaned

a task was lost: record it in the database

=cut

sub process_event_task_orphaned
{
	my $self = shift;
	my $href = shift;

	my $rsTask	= $self->schema->resultset('Task');
	my $task	= $rsTask->find_or_create({ id => $href->{id} });

	$task->name($href->{task}) if not defined $task->name;
	$task->queue($href->{queue}) if not defined $task->queue;
	$task->completed(1);
	$task->succeeded(0);
	$task->failed(0);
	$task->aborted(0);
	$task->date_completed($href->{date_completed});
	$task->create_related(output => { text => $href->{output} })
		if defined $href->{output};

	$task->update;
}

=back

=head1 AUTHOR

Mike Eldridge <diz@cpan.org>

=head1 LICENSE

=cut

1;

