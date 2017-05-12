=head1 NAME

C<Gearman::JobScheduler::Admin> - Gearman administration utilities.

Reimplements functionality of "gearadmin"
(http://bazaar.launchpad.net/~tangent-trunk/gearmand/1.2/view/head:/bin/gearadmin.cc)
in Perl.

=cut
package Gearman::JobScheduler::Admin;

use strict;
use warnings;
use Modern::Perl "2012";

use Gearman::JobScheduler;
use Gearman::JobScheduler::Configuration;

# Neither "Gearman" nor "Gearman::XS" modules provide the administration
# functionality, so we'll connect directly to Gearman and send / receive
# commands ourselves.
use Net::Telnet;

# Connection timeout
use constant GJS_ADMIN_TIMEOUT => 10;


=head2 (static) C<server_version($config)>

Get the version number from all the configured servers.

Parameters:

=over 4

=item * Instance of Gearman::JobScheduler::Configuration

=back

Returns hashref of configured servers and their versions, e.g.:

=begin text

	{
		'localhost:4730' => '1.1.9',
		# ...
	}

=end text

Returns C<undef> on error.

=cut
sub server_version($)
{
	my $config = shift;

	unless ($config) {
		die "Configuration is undefined.";
	}

	my $versions = {};

	foreach my $server (@{$config->gearman_servers}) {

		my $version = server_version_on_server($server);
		unless (defined $version) {
			say STDERR "Unable to determine version of server $server.";
			return undef;
		}

		$versions->{ $server } = $version;
	}

	return $versions;
}


=head2 (static) C<server_version_on_server($server)>

Get the version number from a server.

Parameters:

=over 4

=item * Server as "host:port" (e.g. "localhost:4730")

=back

Returns a string server version, e.g. '1.1.9'.

Returns C<undef> on error.

=cut
sub server_version_on_server($)
{
	my $server = shift;

	my $telnet = _net_telnet_instance_for_server($server);

	$telnet->print('version');
	my $version = $telnet->getline();
	chomp $version;

	unless ($version =~ /^OK /) {
		say STDERR "Server $server didn't respond with 'OK': $version";
		return undef;
	}

	$version =~ s/^OK //;
	unless ($version) {
		say STDERR "Version string is empty.";
		return undef;
	}

	return $version;
}


=head2 (static) C<server_verbose($config)>

Get the verbose setting from all the configured servers.

Parameters:

=over 4

=item * Instance of Gearman::JobScheduler::Configuration

=back

Returns hashref of configured servers and their verbosity levels, e.g.:

=begin text

	{
		'localhost:4730' => 'ERROR',
		# ...
	}

=end text

Available verbosity levels:

=over 4

* C<FATAL>

* C<ALERT> (currently unused in Gearman)

* C<CRITICAL> (currently unused in Gearman)

* C<ERROR>

* C<WARN>

* C<NOTICE>

* C<INFO>

* C<DEBUG>

=back

Returns C<undef> on error.

=cut
sub server_verbose($)
{
	my $config = shift;

	unless ($config) {
		die "Configuration is undefined.";
	}

	my $verbose_levels = {};

	foreach my $server (@{$config->gearman_servers}) {

		my $verbose = server_verbose_on_server($server);
		unless (defined $verbose) {
			say STDERR "Unable to determine verbosity level of server $server.";
			return undef;
		}

		$verbose_levels->{ $server } = $verbose;
	}

	return $verbose_levels;
}


=head2 (static) C<server_verbose_on_server($server)>

Get the verbose setting from a server.

Parameters:

=over 4

=item * Server as "host:port" (e.g. "localhost:4730")

=back

Returns string verbose setting (see C<server_verbose> for possible values).

Returns C<undef> on error.

=cut
sub server_verbose_on_server($)
{
	my $server = shift;

	my $telnet = _net_telnet_instance_for_server($server);

	$telnet->print('verbose');
	my $verbose = $telnet->getline();
	chomp $verbose;

	unless ($verbose =~ /^OK /) {
		say STDERR "Server $server didn't respond with 'OK': $verbose";
		return undef;
	}

	$verbose =~ s/^OK //;
	unless ($verbose) {
		say STDERR "Verbose string is empty.";
		return undef;
	}

	return $verbose;
}


=head2 (static) C<create_function($function_name, $config)>

Create the function on all the configured servers.

Parameters:

=over 4

=item * Function name (e.g. C<hello_world>)

=item * Instance of Gearman::JobScheduler::Configuration

=back

Returns true (1) if the function has been created, false (C<undef>) on error.

=cut
sub create_function($$)
{
	my ($function_name, $config) = @_;

	unless ($config) {
		die "Configuration is undefined.";
	}

	foreach my $server (@{$config->gearman_servers}) {

		my $result = create_function_on_server($function_name, $server);
		unless ($result) {
			say STDERR "Unable to create function '$function_name' on server $server.";
			return undef;
		}
	}

	return 1;
}


=head2 (static) C<create_function_on_server($function_name, $server)>

Create the function on a server.

Parameters:

=over 4

=item * Function name (e.g. C<hello_world>)

=item * Server as "host:port" (e.g. "localhost:4730")

=back

Returns true (1) if the function has been created, false (C<undef>) on error.

=cut
sub create_function_on_server($$)
{
	my ($function_name, $server) = @_;

	unless ($function_name) {
		say STDERR "Function name can't be empty (Gearman would allow that, but I don't)";
		return undef;
	}
	if ($function_name =~ /\n/ or $function_name =~ /\r/ or $function_name =~ /\s/) {
		say STDERR "Function name can't contain line breaks or whitespace";
		return undef;
	}

	my $telnet = _net_telnet_instance_for_server($server);

	$telnet->print('create function ' . $function_name);
	my $function_created = $telnet->getline();
	chomp $function_created;

	unless ($function_created eq 'OK') {
		say STDERR "Server $server didn't respond with 'OK': $function_created";
		return undef;
	}

	return 1;
}


=head2 (static) C<drop_function($function_name, $config)>

Drop the function on all the configured servers.

Parameters:

=over 4

=item * Function name (e.g. C<hello_world>)

=item * Instance of Gearman::JobScheduler::Configuration

=back

Returns true (1) if the function has been dropped, false (C<undef>) on error.

=cut
sub drop_function($$)
{
	my ($function_name, $config) = @_;

	unless ($config) {
		die "Configuration is undefined.";
	}

	foreach my $server (@{$config->gearman_servers}) {

		my $result = drop_function_on_server($function_name, $server);
		unless ($result) {
			say STDERR "Unable to drop function '$function_name' on server $server.";
			return undef;
		}
	}

	return 1;
}


=head2 (static) C<drop_function_on_server($function_name, $server)>

Drop the function on a server.

Parameters:

=over 4

=item * Function name (e.g. C<hello_world>)

=item * Server as "host:port" (e.g. "localhost:4730")

=back

Returns true (1) if the function has been dropped, false (C<undef>) on error.

=cut
sub drop_function_on_server($$)
{
	my ($function_name, $server) = @_;

	unless ($function_name) {
		say STDERR "Function name can't be empty (Gearman would allow that, but I don't)";
		return undef;
	}
	if ($function_name =~ /\n/ or $function_name =~ /\r/ or $function_name =~ /\s/) {
		say STDERR "Function name can't contain line breaks or whitespace";
		return undef;
	}

	my $telnet = _net_telnet_instance_for_server($server);

	$telnet->print('drop function ' . $function_name);
	my $function_dropped = $telnet->getline();
	chomp $function_dropped;

	unless ($function_dropped eq 'OK') {
		say STDERR "Server $server didn't respond with 'OK': $function_dropped";
		return undef;
	}

	return 1;
}


=head2 (static) C<show_jobs($config)>

Show all jobs on all the configured servers.

Parameters:

=over 4

=item * Instance of Gearman::JobScheduler::Configuration

=back

Returns a hashref of servers and their jobs, e.g.:

=begin text

	{
		'localhost:4730' => {
			# See show_jobs_on_server() for an example of the jobs hashref
		},

		# ...
	}

=end text

Returns C<undef> on error.

=cut
sub show_jobs($)
{
	my $config = shift;

	unless ($config) {
		die "Configuration is undefined.";
	}

	my $jobs = {};

	foreach my $server (@{$config->gearman_servers}) {

		my $server_jobs = show_jobs_on_server($server);
		unless (defined $server_jobs) {
			say STDERR "Unable to fetch jobs from server $server.";
			return undef;
		}

		$jobs->{ $server } = $server_jobs;
	}

	return $jobs;
}


=head2 (static) C<show_jobs_on_server($server)>

Show all jobs on a server.

Parameters:

=over 4

=item * Server as "host:port" (e.g. "localhost:4730")

=back

Returns a hashref of job statuses, e.g.:

=begin text

	{
		# Gearman job ID that was passed as a parameter
		'H:tundra.home:8' => {

			# Whether or not the job is currently running
			'running' => 1,

			# Numerator and denominator of the job's progress
			# (in this example, job is 1333/2000 complete)
			'numerator' => 1333,	# 0 if the job haven't been started yet
			'denominator' => 2000	# 1 if the job haven't been started yet;
									# 0 if the job has been cancelled
			
		},

		# ...

	};

=end text

Returns C<undef> on error.

=cut
sub show_jobs_on_server($)
{
	my $server = shift;

	my $telnet = _net_telnet_instance_for_server($server);
	my $jobs = {};

	$telnet->print('show jobs');

	while ( my $line = $telnet->getline() ) {
		chomp $line;
		last if $line eq '.';

		my @job = split("\t", $line);
		unless (scalar @job == 4) {
			say STDERR "Unable to parse line from server $server: $line";
			return undef;
		}

		my $job_id = $job[0];
		my $job_running = $job[1] + 0;
		my $job_numerator = $job[2] + 0;
		my $job_denominator = $job[3] + 0;

		if (defined $jobs->{ $job_id }) {
			say STDERR "Job with job ID '$job_id' already exists in the jobs hashref, strange.";
			return undef;
		}

		$jobs->{ $job_id } = {
			'running' => $job_running,
			'numerator' => $job_numerator,
			'denominator' => $job_denominator
		};
	}

	return $jobs;
}


=head2 (static) C<show_unique_jobs($config)>

Show unique jobs on all the configured servers.

Parameters:

=over 4

=item * Instance of Gearman::JobScheduler::Configuration

=back

Returns an arrayref of unique job identifiers, e.g.:

=begin text

	{
		'localhost:4730' => [
			# See show_unique_jobs_on_server() for an example of the unique job
			# identifiers arrayref
		],

		# ...
	}

=end text

Returns C<undef> on error.

=cut
sub show_unique_jobs($)
{
	my $config = shift;

	my $job_identifiers = {};

	foreach my $server (@{$config->gearman_servers}) {

		my $server_job_identifiers = show_unique_jobs_on_server($server);
		unless (defined $server_job_identifiers) {
			say STDERR "Unable to fetch job identifiers from server $server.";
			return undef;
		}

		$job_identifiers->{ $server } = $server_job_identifiers;
	}

	return $job_identifiers;
}


=head2 (static) C<show_unique_jobs_on_server($server)>

Show unique jobs on a server.

Parameters:

=over 4

=item * Server as "host:port" (e.g. "localhost:4730")

=back

Returns an arrayref of unique job identifiers, e.g.:

=begin text

	[
		# SHA256 hashes of "function_name(params)" strings as generated by GJS
		'1455d13e979c2c94445a47d2fed0854557c3afb195aceb55286c304d2dd86a8',
		'fe9ffb3eee42b1f983a974e5a68d263ac0930ac0d5fda57a253238243a981b3',
		'184e1c19a67d84fbeac1e1affab7ce725c8fb427a78ef203a15a67648b6eb60',
	]

=end text

Returns C<undef> on error.

=cut
sub show_unique_jobs_on_server($)
{
	my $server = shift;

	my $telnet = _net_telnet_instance_for_server($server);
	my $job_identifiers = [];

	$telnet->print('show unique jobs');

	while ( my $line = $telnet->getline() ) {
		chomp $line;
		last if $line eq '.';

		unless ($line) {
			say STDERR "Job identifier is empty for server $server";
			return undef;
		}

		push(@{$job_identifiers}, $line);
	}

	return $job_identifiers;
}


=head2 (static) C<cancel_job($gearman_job_id, $config)>

Remove a given job from all the configured servers' queues.

Parameters:

=over 4

=item * Gearman job ID (e.g. "H:localhost.localdomain:8")

=item * Instance of Gearman::JobScheduler::Configuration

=back

Returns true (1) if the job has been cancelled, false (C<undef>) on error.

=cut
sub cancel_job($$)
{
	my ($gearman_job_id, $config) = @_;

	unless ($config) {
		die "Configuration is undefined.";
	}

	foreach my $server (@{$config->gearman_servers}) {

		my $result = cancel_job_on_server($gearman_job_id, $server);
		unless ($result) {
			say STDERR "Unable to cancel job '$gearman_job_id' on server $server.";
			return undef;
		}
	}

	return 1;
}


=head2 (static) C<cancel_job_on_server($gearman_job_id, $server)>

Remove a given job from a server's queue.

Parameters:

=over 4

=item * Gearman job ID (e.g. "H:localhost.localdomain:8")

=item * Server as "host:port" (e.g. "localhost:4730")

=back

Returns true (1) if the job has been cancelled, false (C<undef>) on error.

=cut
sub cancel_job_on_server($$)
{
	my ($gearman_job_id, $server) = @_;

	unless ($gearman_job_id) {
		say STDERR "Gearman job ID is empty.";
		return undef;
	}
	if ($gearman_job_id =~ /\n/ or $gearman_job_id =~ /\r/) {
		say STDERR "Gearman job ID can't contain line breaks";
		return undef;
	}

	my $telnet = _net_telnet_instance_for_server($server);

	$telnet->print('cancel job ' . $gearman_job_id);
	my $job_cancelled = $telnet->getline();
	chomp $job_cancelled;

	unless ($job_cancelled eq 'OK') {
		say STDERR "Server $server didn't respond with 'OK': $job_cancelled";
		return undef;
	}

	return 1;
}


=head2 (static) C<get_pid($config)>

Get Process ID (PID) of all the configured servers.

Parameters:

=over 4

=item * Instance of Gearman::JobScheduler::Configuration

=back

Returns hashref of configured servers and their integer PIDs, e.g.:

=begin text

	{
		'localhost:4730' => 1234,
		# ...
	}

=end text

Returns C<undef> on error.

=cut
sub get_pid($)
{
	my $config = shift;

	unless ($config) {
		die "Configuration is undefined.";
	}

	my $pids = {};

	foreach my $server (@{$config->gearman_servers}) {

		my $pid = get_pid_for_server($server);
		unless (defined $pid) {
			say STDERR "Unable to get PID of server $server.";
			return undef;
		}

		$pids->{ $server } = $pid + 0;
	}

	return $pids;
}


=head2 (static) C<get_pid_for_server($server)>

Get Process ID (PID) of a server.

Parameters:

=over 4

=item * Server as "host:port" (e.g. "localhost:4730")

=back

Returns integer PID (e.g. 1234).

Returns C<undef> on error.

=cut
sub get_pid_for_server($)
{
	my $server = shift;

	my $telnet = _net_telnet_instance_for_server($server);

	$telnet->print('getpid');
	my $pid = $telnet->getline();
	chomp $pid;

	unless ($pid =~ /^OK /) {
		say STDERR "Server $server didn't respond with 'OK': $pid";
		return undef;
	}

	$pid =~ s/^OK //;
	unless ($pid) {
		say STDERR "PID string is empty.";
		return undef;
	}

	return $pid + 0;
}


=head2 (static) C<status($config)>

Get status from all the configured servers.

Parameters:

=over 4

=item * Instance of Gearman::JobScheduler::Configuration

=back

Returns a hashref of servers and their statuses, e.g.:

=begin text

	{
		'localhost:4730' => {
			# See status_on_server() for an example of the status hashref
		}

		# ...

	};

=end text

Returns C<undef> on error.

=cut
sub status($)
{
	my $config = shift;

	unless ($config) {
		die "Configuration is undefined.";
	}

	my $statuses = {};

	foreach my $server (@{$config->gearman_servers}) {

		my $status = status_on_server($server);
		unless (defined $status) {
			say STDERR "Unable to fetch status from server $server.";
			return undef;
		}

		$statuses->{ $server } = $status;
	}

	return $statuses;
}


=head2 (static) C<status_on_server($server)>

Get status of a server.

Parameters:

=over 4

=item * Server as "host:port" (e.g. "localhost:4730")

=back

Returns a hashref of Gearman functions and their statuses, e.g.:

=begin text

	{
		# Gearman function name
		'NinetyNineBottlesOfBeer' => {

			# Number of enqueued (waiting to be run) jobs
			'total'	=> 4,

			# Number of currently running jobs
			'running' => 1,

			# Number of currently registered workers
			'available_workers' => 1
			
		},

		# ...

	};

=end text

Returns C<undef> on error.

=cut
sub status_on_server($)
{
	my $server = shift;

	my $telnet = _net_telnet_instance_for_server($server);
	my $functions = {};

	$telnet->print('status');

	while ( my $line = $telnet->getline() ) {
		chomp $line;
		last if $line eq '.';

		my @function = split("\t", $line);
		unless (scalar @function == 4) {
			say STDERR "Unable to parse line from server $server: $line";
			return undef;
		}

		my $function_name = $function[0];
		my $function_total = $function[1] + 0;
		my $function_running = $function[2] + 0;
		my $function_available_workers = $function[3] + 0;

		if (defined $functions->{ $function_name }) {
			say STDERR "Function with name '$function_name' already exists in the functions hashref, strange.";
			return undef;
		}

		$functions->{ $function_name } = {
			'total' => $function_total,
			'running' => $function_running,
			'available_workers' => $function_available_workers
		};
	}

	return $functions;
}


=head2 (static) C<workers($config)>

Get a list of workers from all the configured servers.

Parameters:

=over 4

=item * Instance of Gearman::JobScheduler::Configuration

=back

Returns a hashref of servers and their workers, e.g.:

=begin text

	{
		'localhost:4730' => {
			# See workers_on_server() for an example of the workers hashref
		}

		# ...

	};

=end text

Returns C<undef> on error.

=cut
sub workers($)
{
	my $config = shift;

	unless ($config) {
		die "Configuration is undefined.";
	}

	my $workers = {};

	foreach my $server (@{$config->gearman_servers}) {

		my $server_workers = workers_on_server($server);
		unless (defined $server_workers) {
			say STDERR "Unable to fetch workers from server $server.";
			return undef;
		}

		$workers->{ $server } = $server_workers;
	}

	return $workers;
}


=head2 (static) C<workers_on_server($server)>

Get a list of workers on a server.

Parameters:

=over 4

=item * Server as "host:port" (e.g. "localhost:4730")

=back

Returns an arrayref of hashrefs for each of the registered worker, e.g.:

=begin text

	[
		{
			# Unique integer file descriptor of the worker
			'file_descriptor' => 23,
			
			# IP address of the worker
			'ip_address' => '127.0.0.1',

			# Client ID of the worker (might be undefined if the ID is '-')
			'client_id' => undef,

			# List of functions the worker covers
			'functions' => [
				'NinetyNineBottlesOfBeer',
				'Addition'
			]
		},
		# ...
	]

=end text

Returns C<undef> on error.

=cut
sub workers_on_server($)
{
	my $server = shift;

	my $telnet = _net_telnet_instance_for_server($server);
	my $workers = [];

	$telnet->print('workers');

	while ( my $line = $telnet->getline() ) {
		chomp $line;
		last if $line eq '.';

		my $colon_pos = index($line, ':');
		if ($colon_pos == -1) {
			say STDERR "Unable to parse line from server $server: $line";
			return undef;
		}

		my @worker_description = split(/\s+/, substr($line, 0, $colon_pos));
		unless (scalar @worker_description == 3) {
			say STDERR "Unable to parse line from server $server: $line";
			return undef;
		}
		my @worker_functions = split(/\s+/, substr($line, $colon_pos+1));

		my $worker_file_descriptor = $worker_description[0] + 0;
		my $worker_ip_address = $worker_description[1];
		my $worker_client_id = ($worker_description[2] ne '-' ? $worker_description[2] : undef);

		push(@{$workers}, {
			'file_descriptor' => $worker_file_descriptor,
			'ip_address' => $worker_ip_address,
			'client_id' => $worker_client_id,
			'functions' => \@worker_functions
		});
	}

	return $workers;
}


=head2 (static) C<shutdown_all_servers($config)>

Shutdown all the configured servers.

Parameters:

=over 4

=item * Instance of Gearman::JobScheduler::Configuration

=back

Returns true (1) if the Gearman servers have been shutdown.

Returns false (C<undef>) on error.

=cut
sub shutdown_all_servers($)
{
	my $config = shift;

	unless ($config) {
		die "Configuration is undefined.";
	}

	foreach my $server (@{$config->gearman_servers}) {

		my $result = shutdown_server($server);
		unless ($result) {
			say STDERR "Unable to shutdown server $server.";
			return undef;
		}
	}

	return 1;
}


=head2 (static) C<shutdown_server($server)>

Shutdown a server.

Parameters:

=over 4

=item * Server as "host:port" (e.g. "localhost:4730")

=back

Returns true (1) if the Gearman server has been shutdown.

Returns false (C<undef>) on error.

=cut
sub shutdown_server($)
{
	my $server = shift;

	my $telnet = _net_telnet_instance_for_server($server);

	$telnet->print('shutdown');
	my $server_shutdown = $telnet->getline();
	chomp $server_shutdown;

	unless ($server_shutdown eq 'OK') {
		say STDERR "Server $server didn't respond with 'OK': $server_shutdown";
		return undef;
	}

	return 1;
}


# Connects to Gearman, returns Net::Telnet instance
sub _net_telnet_instance_for_server($)
{
	my $server = shift;

	my ($host, $port) = split(':', $server);
	$port //= 4730;

	my $telnet = new Net::Telnet(Host => $host,
								 Port => $port,
								 Timeout => GJS_ADMIN_TIMEOUT);
	$telnet->open();

	return $telnet;
}


1;
