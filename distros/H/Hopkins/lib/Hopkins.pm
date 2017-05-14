package Hopkins;

use strict;
use warnings;
use version 0.77;

our $VERSION = version->declare('0.9.2');

=head1 NAME

Hopkins - complete multiqueue job scheduling and execution system

=head1 DESCRIPTION

Hopkins is, in simplest terms, a better cron.  In depth,
though, Hopkins is an extensible application geared toward
the management, scheduling, and execution of both inline
perl as well as external binaries.

Hopkins's advantages include:

=over 4

=item * simple

There are many job management systems out there, varying in
complexity.  Hopkins was designed to be simple to understand
and simple to configure.

=item * agnostic implementation

While Hopkins is written in perl and will dynamically load,
instantiate, and execute any object that provides a "run"
method, it does not require your class to be aware of its
environment.  In fact, Hopkins does not require your task
to be written in perl at all.

=item * live, extensible configuration

Hopkins ships with Hopkins::Config::XML, which allows your
queues and tasks to be defined entirely in XML, validated
before load via XML Schema.  However, Hopkins::Config may
be subclassed to provide configuration any way you like.

Hopkins also provides a mechanism by which your config may
be scanned for changes.  For example, Hopkins::Config::XML
periodically checks the configuration file for changes and
validates the XML before replacing the existing config.

=item * multiple queues

Hopkins supports an infinite number of queues that each
have their own concurrency limits and behaviors upon task
failure.  Per-queue concurrencies allow you to define serial
queues (concurrency=1) or worker queues (concurrency > 1).

Each queue's behavior on task failure is configurable.  For
example, queues may be configured to halt upon task failure,
stopping the execution of queued tasks until a human has a
chance to examine the failure.

=item * multiple schedules per task

Each configured task may have a number of schedules defined,
including none.

=item * output/execution logging via DBI

Each queued task records state information to a configurable
database backend.  Information stored includes enqueue time,
time to execute, execution time, completion time, status
flags, as well as all output generated on stdout and stderr.

=item * disconnected operation

If the database backend ever becomes unavailable, Hopkins
will continue to run, queueing up database requests.

=item * extensible

Hopkins supports loadable plugins which may hook into the
running system by making use of POE.  Two plugins include
a web-based user interface (Hopkins::Plugin::HMI) as well
as a SOAP-based interface (Hopkins::Plugin::RPC).

=item * log4perl

Hopkins makes use of the excellent Log::Log4perl module for
its logging, allowing you to direct task execution errors
and other output to the appropriate parties with ease.

=item * durability

Queue (both task and database) contents are written to disk
upon entering/exiting the queue.  Thus, if the daemon were
to be restarted for any reason, it will continue processing
from where it left off.

=item * reliability

Hopkins has been used in an environment handling > 60 tasks
in four separate queues and does not eat resources.  I make
no promises as to its scalability beyond that.

=back

See L<Hopkins::Manual::Configuration::XML> for information
on configuring Hopkins using the default XML configuration.

=cut

#sub POE::Kernel::TRACE_REFCNT () { 1 }

use base 'Class::Accessor::Fast';

use POE qw(Component::JobQueue Wheel::Run);

use Class::Accessor::Fast;
use POE::API::Peek;

use DateTime;
use Log::Log4perl;
use Log::Log4perl::Level;

use Hopkins::Manager;

__PACKAGE__->mk_accessors(qw(conf l4pconf scan poll manager));

{
	package DateTime::Duration;

	sub stringify
	{
		my $self = shift;

		my @units = $self->in_units('days', 'hours', 'minutes', 'seconds');

		join ' ', map { my $v = shift @units; $v ? $v . $_ : () } qw(d h m s);
	}

	use overload '""' => \&stringify;
}

# prevent perl from bitching and complaining about prototype
# mismatches and constant subroutine redefinitions.  the
# warnings pragma doesn't prevent ALL of them from spewing,
# so we have to get raunchy with perl by defining them at
# runtime with a localized no-op warn handler.

{
	local $SIG{__WARN__} = sub { 1 };

	# forcefully disable the unavoidable debugging output
	# from several of the POE components.

	eval q/
		sub POE::Wheel::SocketFactory::DEBUG () { 0 }
		sub POE::Kernel::alias { (shift->alias_list(@_))[0] }
	/;
}

=head1 METHODS

=head2 new

instantiates a new Hopkins object.  the Hopkins constructor
accepts a hash of options.  currently supported options are:

=over 4

=item conf

path to the hopkins XML configuration file

=item lp4conf

path to the log4perl configuration file

=item scan

configuration scan resolution (in seconds)

=item poll

scheduler poll resolution (in seconds)

=back

=cut

sub new
{
	my $proto	= shift;
	my $opts	= shift;

	# defaults

	$opts->{conf}		||= [ XML => { file => '/etc/hopkins/hopkins.xml' } ];
	$opts->{lp4conf}	||= '/etc/hopkins/log4perl.conf';
	$opts->{scan}		||= 30;
	$opts->{poll}		||= 30;

	# make me majikal wif ur holy waterz.  plzkthx.

	my $self = $proto->SUPER::new($opts);

	# initialize log4perl using the contents of the supplied
	# configuration file.
	#
	# after initialization (which may have failed), we'll
	# create a logger and associated appender for logging
	# all error level log messages to stderr.  this allows
	# logging error messages to the console using log4perl
	# regardless of the configuration that the user loads.

	eval { Log::Log4perl->init_and_watch($opts->{l4pconf}, $opts->{scan}) };

	my $l4perr = $@;
	my $logger = Log::Log4perl->get_logger('hopkins');
	my $layout = new Log::Log4perl::Layout::PatternLayout '%X{session}: %p: %m%n';

	my $appender = new Log::Log4perl::Appender
		'Log::Log4perl::Appender::Screen',
		name	=> 'stderr',
		stderr	=> 1;

	$appender->layout($layout);
	$appender->threshold($ERROR);
	$logger->add_appender($appender);

	Hopkins->log_error("unable to load log4perl configuration file: $l4perr")
		if $l4perr;

	$self->manager(new Hopkins::Manager { hopkins => $self });

	return $self;
}

=head2 run

start the hopkins daemon.  this method will never return.

=cut

sub run { POE::Kernel->run }

=head2 is_session_running

returns a truth value indicating whether or not a session
exists with the specified alias.

=cut

sub is_session_active
{
	my $self = shift;
	my $name = shift;

	my $api			= new POE::API::Peek;
	my @sessions	= map { POE::Kernel->alias($_) } $api->session_list;

	#Hopkins->log_debug("checking for session $name");

	return scalar grep { $name eq $_ } @sessions;
}

=head2 get_running_sessions

returns a list of currently active session aliases

=cut

sub get_running_sessions
{
	my $self = shift;

	my $api = new POE::API::Peek;

	return map { POE::Kernel->alias($_) } $api->session_list;
}

=head2 parse_datetime

DateTime::Format::ISO8601->parse_datetime wrapper that traps
exceptions.  this really shouldn't be necessary.

=cut

sub parse_datetime
{
	my $self = shift;

	my $date;

	eval { $date = DateTime::Format::ISO8601->parse_datetime(@_) };

	return $@ ? undef : $date;
}

=head2 get_logger

returns a Log::Log4perl logger for the current session.  the
get_logger expects the POE kernel to be passed to it.  if no
POE::Kernel is passed, it will default to $poe_kernel.

=cut

my $loggers = {};

sub get_logger
{
	my $self	= shift;
	my $kernel	= shift || $poe_kernel;
	my $alias	= $kernel->alias;
	my $session	= 'hopkins' . ($alias ? '.' . $alias : '');
	my $name	= lc ((caller(2))[3]);

	$alias = 'unknown' if not defined $alias;

	if (not exists $loggers->{$name}) {
		$loggers->{$name} = Log::Log4perl->get_logger($name);
	}

	Log::Log4perl::MDC->put('session', $session);

	return $loggers->{$name};
}

sub get_worker_logger
{
	my $self	= shift;
	my $task	= shift;
	my $kernel	= shift || $poe_kernel;
	my $alias	= $kernel->alias;
	my $session	= 'hopkins' . ($alias ? '.' . $alias : '');
	my $name	= "hopkins.task.$task";

	$alias = 'unknown' if not defined $alias;

	if (not exists $loggers->{$name}) {
		$loggers->{$name} = Log::Log4perl->get_logger($name);
	}

	Log::Log4perl::MDC->put('session',	$session);
	Log::Log4perl::MDC->put('task',		$task);

	return $loggers->{$name};
}

sub log_debug	{ return shift->get_logger->debug(@_)	}
sub log_info	{ return shift->get_logger->info(@_)	}
sub log_warn	{ return shift->get_logger->warn(@_)	}
sub log_error	{ return shift->get_logger->error(@_)	}
sub log_fatal	{ return shift->get_logger->fatal(@_)	}

sub log_worker_stdout { return shift->get_worker_logger(shift)->info(@_) }
sub log_worker_stderr { return shift->get_worker_logger(shift)->warn(@_) }

=head1 BUGS

this is my first foray into POE territory.  the way the
system is architected may be horribly inefficient, cause
cancer, or otherwise be a general nuisance to its intended
user(s).  my bad.

=head1 AUTHOR

Mike Eldridge <diz@cpan.org>

=head1 LICENSE

Copyright (c) 2010 Mike Eldridge.  All rights reserved.

This program is free software; you may redistribute it
and/or modify it under the same terms as Perl itself.

=head1 HOME

http://github.com/tripside/hopkins

=cut

1;
