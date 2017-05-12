package GearmanX::Starter;

use strict;
use warnings;

use Gearman::XS qw(:constants);
use Gearman::XS::Worker;
use Perl::Unsafe::Signals;
use POSIX;

our $VERSION = '0.05';

our $WORKER;

our $QUIT;

sub new {
  my $class = shift;

  bless {}, $class;
}

sub start {
  my $self = shift;

  my $args = shift;

  my $worker_name = $args->{name} || die "Need name for worker";

  my $init_func = $args->{init_func};

  my $logger = $args->{logger};

  my $servers = $args->{servers} || [[]];

  my $sigterm = $args->{sigterm} || [ 'TERM' ];
  my $sleep = $args->{sleep_and_retry} || 0;

  $logger->info("Forking daemon for $worker_name") if $logger;

  _Init() and return 1;

  my $critical;
  for my $sig (@$sigterm) {
    $SIG{$sig} = sub {
      $QUIT++;
      die "GearmanXQuitLoop\n" if !$critical
    };
  }
  $init_func->() if $init_func;

  $logger->info("Creating $worker_name worker") if $logger;
  $0 = $worker_name;

  $WORKER = $args->{worker} || Gearman::XS::Worker->new;

  for my $server (@$servers) {
    if ($WORKER->add_server(@$server) != GEARMAN_SUCCESS) {
      $logger->logdie("Unable to add job server [@$server] to worker $worker_name: " . $WORKER->error)
        if $logger;
    }
  }

  # Wrap each function in another function that flags
  # that we're in a critical section of code
  $logger->info("Adding functions to $worker_name worker") if $logger;
  my $func_list = $args->{func_list} || [];
  if ( !exists($args->{dereg_func}) || $args->{dereg_func} ) {
    my $dereg_fn_name = $args->{dereg_func} || "dereg:$$";
    $dereg_fn_name =~ s/%PID%/$$/;
    push @$func_list, [ $dereg_fn_name, \&_unregister ];
  }
  for my $fun (@$func_list) {
    my ($name, $f, $dont_wrap, $options) = @$fun;
    my $wrapper = $dont_wrap ? $f : sub { $critical = 1; goto $f };
    my $ret2 = $WORKER->add_function($name, 0, $wrapper, $options);
    if ($ret2 != GEARMAN_SUCCESS) {
      $logger->logdie("Failed to register callback function ($name) for worker $worker_name:" . $WORKER->error)
        if $logger;
    }
  }

  $logger->info("Starting $worker_name loop") if $logger;
  my $error_method = $sleep ? 'logwarn' : 'logdie';
  while (1) {
    my $res = eval {
      $critical = 0;
      my $ret;
      UNSAFE_SIGNALS { $ret = $WORKER->work };
      if ($ret != GEARMAN_SUCCESS) {
        $logger->$error_method('Failed to initiate waiting for a job: '. $WORKER->error)
          if $logger;
        sleep $sleep;
      }
      1;
    };
    if ( !$res && $@ !~ /GearmanXQuitLoop/ ) {
      $logger->logdie("Error running loop for worker $worker_name [$@]:".$WORKER->error)
        if $logger;
    }
    last if $QUIT;
  }
  $logger->info("Exiting $worker_name")
    if $logger;
  exit 0;
}

# Daemon code co-opted from Proc::Daemon
sub _Fork {
  my $self = shift;

  my $pid;
  if (defined($pid = fork)) {
    return $pid;
  } else {
    die "Can't fork: $!";
  }
}

sub _OpenMax {
    my $openmax = POSIX::sysconf( &POSIX::_SC_OPEN_MAX );
    (!defined($openmax) || $openmax < 0) ? 64 : $openmax;
}

# Daemonize this process
sub _Init {
  my $sess_id;

  _Fork() and return 1;

  die "Unable to detach from controlling terminal"
    unless $sess_id = POSIX::setsid();

  $SIG{'HUP'} = 'IGNORE';

  _Fork() and exit 0;

  ## Change working directory
  chdir "/";
  ## Clear file creation mask
  umask 0;
  ## Close open file descriptors
  foreach my $i (0 .. _OpenMax()) { POSIX::close($i); }

  ## Reopen stderr, stdout, stdin to /dev/null
  open(STDIN,  "+>/dev/null");
  open(STDOUT, "+>&STDIN");
  open(STDERR, "+>&STDIN");

  return 0;
}

sub _unregister {
  my $job = shift;

  $WORKER->unregister($job->workload);

  return "1";
}

1;

__END__

=head1 NAME

GearmanX::Starter - Start Gearman Workers

=head1 SYNOPSIS

  use GearmanX::Starter;

  my $gms = GearmanX::Starter->new();

  my $f = sub {
    my $job = shift;
  
    my $workload = $job->workload();
    my $result   = reverse($workload);
  
    return $result;
  };

  $gms->start({
    name => 'Reverser',
    func_list => [
      [ 'reverse', $f ],
    ],
    logger => $logger,
    init_func => sub { Log::Log4Perl::init($conf_file) },
  });

  # Also possible
  # Delayed local worker creation
  my $args = {
    name => 'Reverser',
    func_list => [
      [ 'reverse', $f ],
    ],
    logger => $logger,
  };
  $args->{init_func} = sub {
    Log::Log4Perl::init($conf_file);
    $args->{worker} = Gearman::XS::Worker->new()
  };
  $gms->start($args);

=head1 DESCRIPTION

Starts a Gearman worker and registers functions. Forks and backgrounds
the forked process as a daemon. When the worker receives a SIGTERM signal,
it will complete any current request and then exit.

=head1 METHODS

=head2 new()

Returns a Gearman starter object.

=head2 start()

Starts the Gearman worker with the supplied function list.
Accepts the following options as a hash reference:

=over 4

=item name

This is the name which will be assigned to C<$0> and is what will show up
in C<ps> output as the program name.

=item func_list

A list of function name and callback pairs that will be registered with the
Gearman worker, and an optional flag to not mark this function
as 'critical' to complete in case of a termination signal. A fourth argument is
a scalar that will be used as the Gearman worker "options" argument when registering
the function. If the fourth argument is supplied, you must also supply the
third argument.
E.g.:

  my $not_critical = 1;
  my $options = "abc";
  ...
  func_list => [
    ['func1', \&func1],
    ['func2', \&func2, $not_critical]
    ['func3', \&func3, '', $options]
  ],
  ...

=item dereg_func

Optional. By default, a function will be registered that will unregister a
function in the worker. The name of the function will be 'dereg:%PID%'
where '%PID%' will be the pid of the worker process.
You can use this option to change the name, and you can use the string '%PID%' in
the name and it will be replaced by the pid of the worker. If a false value is
used for this option, the dereg function will not be registered.

=item sigterm

Optional. A list of signal names that will terminate the worker loop. Default
is C<['TERM']>. You can also pass an empty arrayref to not install a signal
handler.

=item logger

Optional. A L<Log::Log4perl> logger object.

=item init_func

Optional. A function to call after forking the daemon process, but before entering
the worker loop, and just before creating the L<Gearman::XS::Worker> object.
In this function, you may want to re-open the log filehandles.

=item servers

Optional. A list of gearman server host/port pairs. Default is an arrayref
containing one empty list: C<[[]]> (which defaults to the gearman server
on the localhost). You can pass in an empty arrayref if you are passing
in a worker with servers already added.

=item worker

Optional. A L<Gearman::XS::Worker> object. A new object is created if this is
not supplied.

=item sleep_and_retry

Optional. If a gearman error is returned from the work() method, sleep for this many
seconds, and retry.

=back

=head1 VARIABLES

=over 4

=item $QUIT

A package global varible that, if set, will cause
the worker to exit after finishing the current job.

=back

=head1 AUTHOR

Douglas Wilson, C<< <dougw at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-gearmanx-starter at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=GearmanX-Starter>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc GearmanX::Starter


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=GearmanX-Starter>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/GearmanX-Starter>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/GearmanX-Starter>

=item * Search CPAN

L<http://search.cpan.org/dist/GearmanX-Starter/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Douglas Wilson.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
