package Minion::Command::minion::jobx;

use Mojo::Base 'Mojolicious::Command';

use Getopt::Long qw/GetOptionsFromArray :config no_auto_abbrev no_ignore_case/;
use Mojo::JSON qw/decode_json/;
use Mojo::Util qw/dumper tablify/;

our $VERSION = '0.05';

has description => 'Manage Minion jobs';
has usage => sub { shift->extract_usage };

sub run {
  my ($self, @args) = @_;

  my ($args, $options) = ([], {});
  GetOptionsFromArray \@args,
        'A|attempts=i'  => \$options->{attempts},
        'a|args=s'      => sub { $args = decode_json($_[1]) },
        'b|broadcast=s' => (\my $command),
        'd|delay=i'     => \$options->{delay},
        'e|enqueue=s'   => \my $enqueue,
        'l|limit=i'     => \(my $limit          = 100),
        'o|offset=i'    => \(my $offset         = 0),
        'P|parent=s'    => ($options->{parents} = []),
        'p|priority=i'  => \$options->{priority},
        'q|queue=s'     => \$options->{queue},
        'R|retry'       => \my $retry,
        'r|remove'      => \my $remove,
        'S|state=s'     => \$options->{state},
        's|stats'       => \my $stats,
        't|task=s'      => \$options->{task},
        'w|workers'     => \my $workers;

  # Worker remote control command
  return $self->app->minion->backend->broadcast($command, $args, \@args)
    if $command;

  # Enqueue
  return say $self->app->minion->enqueue($enqueue, $args, $options) if $enqueue;

  # Show stats
  return $self->_stats if $stats;

  # List jobs/workers
  my $id = @args ? shift @args : undef;

  return $id ? $self->_worker($id) : $self->_list_workers($offset, $limit) if $workers;
  return $self->_list_jobs($offset, $limit, $options) unless defined $id;
  die "Job does not exist.\n" unless my $job = $self->app->minion->job($id);

  # Remove job
  return $job->remove || die "Job is active.\n" if $remove;

  # Retry job
  return $job->retry($options) || die "Job is active.\n" if $retry;

  # Job info
  my $job_info = $job->info;

  $job_info->{created}  = localtime($job_info->{created}) if $job_info->{created};
  $job_info->{started}  = localtime($job_info->{started}) if $job_info->{started};
  $job_info->{delayed}  = localtime($job_info->{delayed}) if $job_info->{delayed};
  $job_info->{finished} = localtime($job_info->{finished}) if $job_info->{finished};

  print dumper($job_info);
}

sub _list_jobs {
  my $jobs = shift->app->minion->backend->list_jobs(@_);
  my @job_rows;
  push @job_rows, ['id','state','queue','created','started','finished','task'];
  foreach my $job (@$jobs) {
      foreach my $key (qw/created started finished/) {
         $job->{$key} = '[' .  localtime($job->{$key}) . ']' if defined($job->{$key});
         $job->{$key} = 'N/A' unless defined($job->{$key});
      }
      push @job_rows, [$job->{id}, $job->{state}, $job->{queue}, $job->{created}, $job->{started}, $job->{finished}, $job->{task}];
  }
  print tablify \@job_rows;
}

sub _list_workers {
  my $workers = shift->app->minion->backend->list_workers(@_);
  my @workers = map { [$_->{id}, $_->{host} . ':' . $_->{pid}] } @$workers;
  print tablify \@workers;
}

sub _stats { print dumper shift->app->minion->stats }

sub _worker {
   die "Worker does not exist.\n"
   unless my $worker = shift->app->minion->backend->worker_info(@_);
   print dumper $worker;
}

=encoding utf8

=head1 NAME

Minion::Command::minion::jobx - The clone of Minion::Command::minion::job but with some output changes.

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

This module will work the same as Minion::Command::minion::job but with some differences.

1) Display timestamps instead of epoch times.

   {
      "args" => [
         "/some/path/to/some/file",
         "/some/other/path/to/some/file"
       ],
       "attempts" => 1,
       "children" => [],
       "created" => "Wed Aug  3 15:05:00 2016",
       "delayed" => "Wed Aug  3 15:05:00 2016",
       "finished" => "Wed Aug  3 15:05:26 2016",
       "id" => 1853,
       "parents" => [
	      1852
        ],
        "priority" => 0,
        "queue" => "default",
        "result" => {
           "output" => "done"
        },
        "retried" => undef,
        "retries" => 0,
        "started" => "Wed Aug  3 15:05:05 2016",
        "state" => "finished",
        "task" => "task_a",
        "worker" => 108
   }

2) Add "created", "started" and "finished" times to the list of jobs.  Column headers included.

    $./script/app minion jobx -l 5
    id    state     queue    created                     started                     finished                    task
    2507  finished  default  [Thu Aug 18 16:23:25 2016]  [Thu Aug 18 16:23:32 2016]  [Thu Aug 18 16:23:38 2016]  some_task
    2506  finished  default  [Thu Aug 18 16:23:25 2016]  [Thu Aug 18 16:23:31 2016]  [Thu Aug 18 16:23:34 2016]  some_task
    2505  finished  default  [Thu Aug 18 16:23:25 2016]  [Thu Aug 18 16:23:30 2016]  [Thu Aug 18 16:23:41 2016]  some_task
    2504  finished  default  [Thu Aug 18 16:23:25 2016]  [Thu Aug 18 16:23:30 2016]  [Thu Aug 18 16:23:36 2016]  some_task
    2503  finished  default  [Thu Aug 18 16:23:25 2016]  [Thu Aug 18 16:23:25 2016]  [Thu Aug 18 16:23:33 2016]  some_task

=head1 USAGE

    Usage: APPLICATION minion jobx [OPTIONS] [ID]

      ./myapp.pl minion jobx
      ./myapp.pl minion jobx 10023
      ./myapp.pl minion jobx -w
      ./myapp.pl minion jobx -w 23
      ./myapp.pl minion jobx -s
      ./myapp.pl minion jobx -q important -t foo -S inactive
      ./myapp.pl minion jobx -e foo -a '[23, "bar"]'
      ./myapp.pl minion jobx -e foo -P 10023 -P 10024 -p 5 -q important
      ./myapp.pl minion jobx -R -d 10 10023
      ./myapp.pl minion jobx -r 10023

    Options:
      -A, --attempts <number>   Number of times performing this new job will be
                                attempted, defaults to 1
      -a, --args <JSON array>   Arguments for new job in JSON format
      -d, --delay <seconds>     Delay new job for this many seconds
      -e, --enqueue <name>      New job to be enqueued
      -h, --help                Show this summary of available options
      --home <path>             Path to home directory of your application,
                                defaults to the value of MOJO_HOME or
                                auto-detection
      -l, --limit <number>      Number of jobs/workers to show when listing them,
                                defaults to 100
      -m, --mode <name>         Operating mode for your application, defaults to
                                the value of MOJO_MODE/PLACK_ENV or "development"
      -o, --offset <number>     Number of jobs/workers to skip when listing them,
                                defaults to 0
      -P, --parent <id>         One or more jobs the new job depends on
      -p, --priority <number>   Priority of new job, defaults to 0
      -q, --queue <name>        Queue to put new job in, defaults to "default", or
                                list only jobs in this queue
      -R, --retry               Retry job
      -r, --remove              Remove job
      -S, --state <state>       List only jobs in this state
      -s, --stats               Show queue statistics
      -t, --task <name>         List only jobs for this task
      -w, --workers             List workers instead of jobs, or show information
                                for a specific worker

=head1 ATTRIBUTES
 
L<Minion::Command::minion::job> inherits all attributes from
L<Mojolicious::Command> and implements the following new ones.
 
=head2 description
 
  my $description = $job->description;
  $job            = $job->description('Foo');
     
  Short description of this command, used for the command list.
     
=head2 usage
 
  my $usage = $job->usage;
  $job      = $job->usage('Foo');
     
  Usage information for this command, used for the help screen.
     
=head1 METHODS
 
L<Minion::Command::minion::job> inherits all methods from
L<Mojolicious::Command> and implements the following new ones.
 
=head2 run
 
  $job->run(@ARGV);
   
  Run this command.

=head1 TO DO

 - Allow command line option to let user pick which timestamps are included in the list of jobs
   
=head1 SEE ALSO
 
L<Minion>, L<Mojolicious::Guides>, L<http://mojolicious.org>.

=head1 ACKNOWLEDGEMENTS

Most of the code comes from L<Minion::Command::minion::job> written by Sebastian Riedel (SRI). 

=cut

1; # End of Minion::Command::minion::jobx
