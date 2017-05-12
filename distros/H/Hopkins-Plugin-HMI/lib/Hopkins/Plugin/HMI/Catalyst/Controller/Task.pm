package # hide from PAUSE
	Hopkins::Plugin::HMI::Catalyst::Controller::Task;
BEGIN {
  $Hopkins::Plugin::HMI::Catalyst::Controller::Task::VERSION = '0.900';
}

use strict;
use warnings;

=head1 NAME

Hopkins::Plugin::HMI::Catalyst::Controller::Task

=head1 DESCRIPTION

=cut

use base 'Hopkins::Plugin::HMI::Catalyst::Controller';

use LWP::UserAgent;

=head1 METHODS

=cut

=over 4

=item enqueue

=cut

sub enqueue : Local
{
	my $self	= shift;
	my $c		= shift;

	my $hopkins	= $c->config->{hopkins};
	my @tasks	= $hopkins->config->get_task_names;
	my $name	= $c->req->params->{name} || $tasks[0];
	my $task	= $hopkins->config->get_task_info($name);

	if ($c->req->method eq 'POST') {
		my @keys = map { /^option_(.*)/ } keys %{ $c->req->params };
		my $opts = { map { $_ => $c->req->params->{"option_$_"} } @keys };
		my $task = $c->req->params->{task};
		my $args = { };

		$args->{priority}	= $c->req->params->{priority};
		$args->{when}		= $c->req->params->{date_to_execute};

		$hopkins->kernel->post(manager => enqueue => $task => $opts => $args);

		$c->res->redirect($c->uri_for('/status'));
	}

	$c->stash->{task}	= $task;
	$c->stash->{tasks}	= [ sort @tasks ];
}

=back

=head1 AUTHOR

Mike Eldridge <diz@cpan.org>

=head1 LICENSE

This program is free software; you may redistribute it
and/or modify it under the same terms as Perl itself.

=cut

1;
