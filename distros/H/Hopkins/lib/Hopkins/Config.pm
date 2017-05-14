package Hopkins::Config;

use strict;
use warnings;

=head1 NAME

Hopkins::Config - hopkins configuration

=head1 DESCRIPTION

Hopkins::Config is a framework for configuring queues and
tasks as well as state tracking and storage backends.
hopkins supports a pluggable configuration model, allowing
configuration via XML, YAML, RDBMS -- pretty much anything
that implements the methods below.

=cut

use Hopkins::Config::Status;

=head1 METHODS

=over 4

=item new

=cut

sub new
{
	Hopkins->log_error('constructor must return a Hopkins::Config object');

	return undef;
}

=item load

=cut

sub load
{
	Hopkins->log_error('virtual method Hopkins::Config->load must be implemented');

	my $status = new Hopkins::Config::Status;

	$status->parsed(0);
	$status->failed(1);
	$status->ok(0);
	$status->errmsg('load method not implemented');

	return $status;
}

=item scan

=cut

sub scan
{
	Hopkins->log_error('virtual method Hopkins::Config->scan must be implemented');

	return 0;
}

=item get_queue_names

=cut

sub get_queue_names
{
	Hopkins->log_error('virtual method Hopkins::Config->get_queue_names must be implemented');

	return ();
}

=item get_task_names

=cut

sub get_task_names
{
	Hopkins->log_error('virtual method Hopkins::Config->get_task_names must be implemented');

	return ();
}

=item get_task_info

=cut

sub get_task_info
{
	Hopkins->log_error('virtual method Hopkins::Config->get_task_info must be implemented');

	return undef;
}

=item get_queue_info

=cut

sub get_queue_info
{
	Hopkins->log_error('virtual method Hopkins::Config->get_queue_info must be implemented');

	return undef;
}

=item get_plugin_names

=cut

sub get_plugin_names
{
	Hopkins->log_error('virtual method Hopkins::Config->get_plugin_names must be implemented');

	return ();
}

=item get_plugin_info

=cut

sub get_plugin_info
{
	Hopkins->log_error('virtual method Hopkins::Config->get_plugin_info must be implemented');

	return undef;
}

=item has_plugin

=cut

sub has_plugin
{
	Hopkins->log_error('virtual method Hopkins::Config->has_plugin must be implemented');

	return 0;
}

=item fetch

=cut

sub fetch
{
	Hopkins->log_error('virtual method Hopkins::Config->fetch must be implemented');

	return undef;
}

=item loaded

=cut

sub loaded
{
	Hopkins->log_error('virtual method Hopkins::Config->loaded must be implemented');

	return 0;
}

=back

=head1 AUTHOR

Mike Eldridge <diz@cpan.org>

=head1 LICENSE

=cut

1;
