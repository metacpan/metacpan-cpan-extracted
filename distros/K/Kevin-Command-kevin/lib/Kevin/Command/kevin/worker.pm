package Kevin::Command::kevin::worker;
$Kevin::Command::kevin::worker::VERSION = '0.6.0';
# ABSTRACT: Alternative Minion worker command
use Mojo::Base 'Mojolicious::Command';

use Minion::Worker;
use Mojo::Util 'getopt';

has description => 'Start alternative Minion worker';
has usage => sub { shift->extract_usage };

sub _worker {
  my $minion = shift;
  return $minion->kevin_worker(@_) if $minion->can('kevin_worker');
  my $worker = Minion::Worker->with_roles('+Kevin')->new(minion => $minion, @_);
  $minion->emit(worker => $worker);
  return $worker;
}

sub run {
  my ($self, @args) = @_;

  my $defaults = {};
  getopt \@args,
    'C|command-interval=i'   => \$defaults->{command_interval},
    'D|dequeue-timeout=i'    => \$defaults->{dequeue_timeout},
    'f|fast-start'           => \$defaults->{fast_start},
    'I|heartbeat-interval=i' => \$defaults->{heartbeat_interval},
    'j|jobs=i'               => \$defaults->{jobs},
    'q|queue=s@'             => \$defaults->{queues},
    'R|repair-interval=i'    => \$defaults->{repair_interval};
  for (keys %$defaults) { delete $defaults->{$_} unless defined $defaults->{$_} }

  my $app = $self->app;
  my $worker = _worker($app->minion, defaults => $defaults, log => $app->log);
  $worker->run;
}

1;

#pod =encoding utf8
#pod
#pod =head1 SYNOPSIS
#pod
#pod   Usage: APPLICATION kevin worker [OPTIONS]
#pod
#pod     ./myapp.pl kevin worker
#pod     ./myapp.pl kevin worker -f
#pod     ./myapp.pl kevin worker -m production -I 15 -C 5 -R 3600 -j 10
#pod     ./myapp.pl kevin worker -q important -q default
#pod
#pod   Options:
#pod     -C, --command-interval <seconds>     Worker remote control command interval,
#pod                                          defaults to 10
#pod     -D, dequeue-timeout <seconds>        Maximum amount of time to wait for
#pod                                          jobs, defaults 5
#pod     -f, --fast-start                     Start processing jobs as fast as
#pod                                          possible and skip repairing on startup
#pod     -h, --help                           Show this summary of available options
#pod         --home <path>                    Path to home directory of your
#pod                                          application, defaults to the value of
#pod                                          MOJO_HOME or auto-detection
#pod     -I, --heartbeat-interval <seconds>   Heartbeat interval, defaults to 300
#pod     -j, --jobs <number>                  Maximum number of jobs to perform
#pod                                          parallel in forked worker processes,
#pod                                          defaults to 4
#pod     -m, --mode <name>                    Operating mode for your application,
#pod                                          defaults to the value of
#pod                                          MOJO_MODE/PLACK_ENV or "development"
#pod     -q, --queue <name>                   One or more queues to get jobs from,
#pod                                          defaults to "default"
#pod     -R, --repair-interval <seconds>      Repair interval, up to half of this
#pod                                          value can be subtracted randomly to
#pod                                          make sure not all workers repair at the
#pod                                          same time, defaults to 21600 (6 hours)
#pod
#pod =head1 DESCRIPTION
#pod
#pod L<Kevin::Command::kevin::worker> starts a L<Minion> worker. You can have as
#pod many workers as you like.
#pod
#pod This is a fork of L<Minion::Command::minion::worker>. The differences are:
#pod
#pod =over 4
#pod
#pod =item *
#pod
#pod During immediate stops, the worker stops sending heartbeats,
#pod processing remote commands and doing repairs.
#pod
#pod =item *
#pod
#pod During graceful stops, the worker stops doing repairs.
#pod
#pod =item *
#pod
#pod During a stop, when all jobs have finished, the worker
#pod will quit promptly (without sleeping).
#pod
#pod =item *
#pod
#pod Allow to disable repairs with C<-R 0>.
#pod
#pod =back
#pod
#pod =head1 SIGNALS
#pod
#pod The L<Kevin::Command::kevin::worker> process can be controlled at runtime
#pod with the following signals.
#pod
#pod =head2 INT, TERM
#pod
#pod Stop gracefully after finishing the current jobs.
#pod
#pod =head2 QUIT
#pod
#pod Stop immediately without finishing the current jobs.
#pod
#pod =head1 REMOTE CONTROL COMMANDS
#pod
#pod The L<Kevin::Command::kevin::worker> process can be controlled at runtime
#pod through L<Minion::Command::minion::job>, from anywhere in the network, by
#pod broadcasting the following remote control commands.
#pod
#pod =head2 jobs
#pod
#pod   $ ./myapp.pl minion job -b jobs -a '[10]'
#pod   $ ./myapp.pl minion job -b jobs -a '[10]' 23
#pod
#pod Instruct one or more workers to change the number of jobs to perform
#pod concurrently. Setting this value to C<0> will effectively pause the worker. That
#pod means all current jobs will be finished, but no new ones accepted, until the
#pod number is increased again.
#pod
#pod =head2 stop
#pod
#pod   $ ./myapp.pl minion job -b stop -a '[10025]'
#pod   $ ./myapp.pl minion job -b stop -a '[10025]' 23
#pod
#pod Instruct one or more workers to stop a job that is currently being performed
#pod immediately. This command will be ignored by workers that do not have a job
#pod matching the id. That means it is safe to broadcast this command to all workers.
#pod
#pod =head1 ATTRIBUTES
#pod
#pod L<Kevin::Command::kevin::worker> inherits all attributes from
#pod L<Mojolicious::Command> and implements the following new ones.
#pod
#pod =head2 description
#pod
#pod   my $description = $worker->description;
#pod   $worker         = $worker->description('Foo');
#pod
#pod Short description of this command, used for the command list.
#pod
#pod =head2 usage
#pod
#pod   my $usage = $worker->usage;
#pod   $worker   = $worker->usage('Foo');
#pod
#pod Usage information for this command, used for the help screen.
#pod
#pod =head1 METHODS
#pod
#pod L<Kevin::Command::kevin::worker> inherits all methods from
#pod L<Mojolicious::Command> and implements the following new ones.
#pod
#pod =head2 run
#pod
#pod   $worker->run(@ARGV);
#pod
#pod Run this command.
#pod
#pod =head1 DEBUGGING
#pod
#pod You can set the C<KEVIN_WORKER_TRACE> environment variable to have some
#pod extra diagnostics information printed to C<< $app->log >>.
#pod
#pod   KEVIN_WORKER_TRACE=1
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Minion>, L<Mojolicious::Guides>, L<http://mojolicious.org>.
#pod
#pod =cut

__END__

=pod

=encoding UTF-8

=head1 NAME

Kevin::Command::kevin::worker - Alternative Minion worker command

=head1 VERSION

version 0.6.0

=head1 SYNOPSIS

  Usage: APPLICATION kevin worker [OPTIONS]

    ./myapp.pl kevin worker
    ./myapp.pl kevin worker -f
    ./myapp.pl kevin worker -m production -I 15 -C 5 -R 3600 -j 10
    ./myapp.pl kevin worker -q important -q default

  Options:
    -C, --command-interval <seconds>     Worker remote control command interval,
                                         defaults to 10
    -D, dequeue-timeout <seconds>        Maximum amount of time to wait for
                                         jobs, defaults 5
    -f, --fast-start                     Start processing jobs as fast as
                                         possible and skip repairing on startup
    -h, --help                           Show this summary of available options
        --home <path>                    Path to home directory of your
                                         application, defaults to the value of
                                         MOJO_HOME or auto-detection
    -I, --heartbeat-interval <seconds>   Heartbeat interval, defaults to 300
    -j, --jobs <number>                  Maximum number of jobs to perform
                                         parallel in forked worker processes,
                                         defaults to 4
    -m, --mode <name>                    Operating mode for your application,
                                         defaults to the value of
                                         MOJO_MODE/PLACK_ENV or "development"
    -q, --queue <name>                   One or more queues to get jobs from,
                                         defaults to "default"
    -R, --repair-interval <seconds>      Repair interval, up to half of this
                                         value can be subtracted randomly to
                                         make sure not all workers repair at the
                                         same time, defaults to 21600 (6 hours)

=head1 DESCRIPTION

L<Kevin::Command::kevin::worker> starts a L<Minion> worker. You can have as
many workers as you like.

This is a fork of L<Minion::Command::minion::worker>. The differences are:

=over 4

=item *

During immediate stops, the worker stops sending heartbeats,
processing remote commands and doing repairs.

=item *

During graceful stops, the worker stops doing repairs.

=item *

During a stop, when all jobs have finished, the worker
will quit promptly (without sleeping).

=item *

Allow to disable repairs with C<-R 0>.

=back

=head1 SIGNALS

The L<Kevin::Command::kevin::worker> process can be controlled at runtime
with the following signals.

=head2 INT, TERM

Stop gracefully after finishing the current jobs.

=head2 QUIT

Stop immediately without finishing the current jobs.

=head1 REMOTE CONTROL COMMANDS

The L<Kevin::Command::kevin::worker> process can be controlled at runtime
through L<Minion::Command::minion::job>, from anywhere in the network, by
broadcasting the following remote control commands.

=head2 jobs

  $ ./myapp.pl minion job -b jobs -a '[10]'
  $ ./myapp.pl minion job -b jobs -a '[10]' 23

Instruct one or more workers to change the number of jobs to perform
concurrently. Setting this value to C<0> will effectively pause the worker. That
means all current jobs will be finished, but no new ones accepted, until the
number is increased again.

=head2 stop

  $ ./myapp.pl minion job -b stop -a '[10025]'
  $ ./myapp.pl minion job -b stop -a '[10025]' 23

Instruct one or more workers to stop a job that is currently being performed
immediately. This command will be ignored by workers that do not have a job
matching the id. That means it is safe to broadcast this command to all workers.

=head1 ATTRIBUTES

L<Kevin::Command::kevin::worker> inherits all attributes from
L<Mojolicious::Command> and implements the following new ones.

=head2 description

  my $description = $worker->description;
  $worker         = $worker->description('Foo');

Short description of this command, used for the command list.

=head2 usage

  my $usage = $worker->usage;
  $worker   = $worker->usage('Foo');

Usage information for this command, used for the help screen.

=head1 METHODS

L<Kevin::Command::kevin::worker> inherits all methods from
L<Mojolicious::Command> and implements the following new ones.

=head2 run

  $worker->run(@ARGV);

Run this command.

=head1 DEBUGGING

You can set the C<KEVIN_WORKER_TRACE> environment variable to have some
extra diagnostics information printed to C<< $app->log >>.

  KEVIN_WORKER_TRACE=1

=head1 SEE ALSO

L<Minion>, L<Mojolicious::Guides>, L<http://mojolicious.org>.

=head1 AUTHOR

Adriano Ferreira <ferreira@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Adriano Ferreira.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
