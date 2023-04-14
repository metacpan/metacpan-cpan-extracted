package Log::Any::Progress;

use 5.006;
use strict;
use warnings;

=head1 NAME

Log::Any::Progress - log incremental progress using Log::Any

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';

=head1 SYNOPSIS

  use Log::Any::Progress;

  use Log::Any::Adapter 'Stderr';

  my $progress = Log::Any::Progress->new(
      count  => $num_things_to_do,
      prefix => 'Processing widgets',
  );

  foreach my $thing_to_do (@things_to_do) {
      do_the_thing($thing_to_do);
      $progress->update;
  }

=head1 DESCRIPTION

This module makes it easy to use L<Log::Any> to log incremental
progress, similar in concept to L<Term::ProgressBar>.  It can be
useful for monitoring the progress of a long-running process and to
get an idea of how long that process might take to finish.

It is generally applied to a processing loop.  In the typical case
where the expected number of iterations is known in advance, it
produces output containing the iteration count, percent completion,
elapsed time, average time per iteration, and estimated time remaining.
For example:

  Progress: Iteration:0/5 0% STARTING
  Progress: Iteration:1/5 20% Elapsed:2.000s Avg:2.000s Remaining:8.001s
  Progress: Iteration:2/5 40% Elapsed:4.001s Avg:2.000s Remaining:6.001s
  Progress: Iteration:3/5 60% Elapsed:6.001s Avg:2.000s Remaining:4.001s
  Progress: Iteration:4/5 80% Elapsed:8.001s Avg:2.000s Remaining:2.000s
  Progress: Iteration:5/5 100% FINISHED Elapsed:10.002s Avg:2.000s

The remaining time estimate as of any particular iteration is a
simple linear calculation based on the average time per iteration up
to that point, and the number of remaining iterations.

If the expected number of iterations is not known in advance, it still
reports on incremental progress, but cannot compute either percent
completion or estimated remaining time.  For example:

  Progress: Iteration:0 STARTING
  Progress: Iteration:1 Elapsed:2.000s Avg:2.000s
  Progress: Iteration:2 Elapsed:4.001s Avg:2.000s
  Progress: Iteration:3 Elapsed:6.001s Avg:2.000s
  Progress: Iteration:4 Elapsed:8.001s Avg:2.000s
  Progress: Iteration:5 Elapsed:10.001s Avg:2.000s

=cut

use Log::Any ();
use Time::HiRes qw( gettimeofday tv_interval );

use constant {
    DEFAULT_LOG_LEVEL                => 'infof',
    DEFAULT_LOG_LEVEL_START_FINISH   => 'noticef',
    DEFAULT_MIN_SEC_BETWEEN_MESSAGES => 10,
    DEFAULT_PREFIX                   => 'Progress',
};

=head1 METHODS

=head2 new

  my $progress = Log::Any::Progress->new(

      count => $num_things_to_do,    # mandatory

      delayed_start            => 1,
      logger                   => $logger,
      log_level                => 'info',
      log_level_start_finish   => 'notice',
      min_sec_between_messages => 10,
      prefix                   => 'Processing widgets',
  );

Create a new object for logging incremental progress.  Options include:

=over 4

=item count

A mandatory non-zero count of the expected number of iterations for
progress tracking.

Specifying C<-1> indicates that the expected number of iterations is
unknown, in which case abbreviated statistics will be logged for each
iteration (percent completion and estimated finish time cannot be
computed without knowing the expected number of iterations in advance).

=item delayed_start

An optional boolean value controlling whether or not L</start> should
be automatically called at time of object construction.  It defaults
to false, in which case L</start> is automatically called, assuming
that progress tracking will commence immediately after.

Specifying a true value for C<delayed_start> will prevent L</start>
from being automatically called, in which case it should be explicitly
called just before progress iteration begins.

=item logger

An optional L<Log::Any> logger object to use for logging.

If not specified, a logger object will be obtained via
C<< Log::Any->get_logger() >>, which will in turn use whatever
L<Log::Any::Adapter> might be configured.

If not specifying a logger object, you will want to make sure that
some adapter other than the default L<Log::Any::Adapter::Null>
adapter is configured (for example, L<Log::Any::Adapter::Stderr>),
otherwise no log messages will be emitted.

=item log_level

An optional L<Log::Any> log level for the incremental progress lines.
It defaults to C<info>.

Valid log levels include:

  trace
  debug
  info (inform)
  notice
  warning (warn)
  error (err)
  critical (crit, fatal)
  alert
  emergency

=item log_level_start_finish

An optional L<Log::Any> log level for the start and finish progress
lines.  It defaults to C<notice>.

Valid log levels include:

  trace
  debug
  info (inform)
  notice
  warning (warn)
  error (err)
  critical (crit, fatal)
  alert
  emergency

=item min_sec_between_messages

An optional value for the minimum number of seconds to wait before
emitting the next incremental progress log message (as a result of
calling L</update>).  Values specifying fractional seconds are allowed
(e.g. C<0.5>).  It defaults to C<10> seconds.

Setting C<min_sec_between_messages> appropriately can be used to
control log verbosity in cases where many hundreds or thousands of
iterations are being processed and it's not necessary to report after
each iteration.  Setting it to C<0> will result in every incremental
progress message will be emitted.

=item prefix

An optional string which will be used to prefix each logged message.
It defaults to C<Progress>.

=back

=cut

sub new
{
    my $class_or_instance = shift;

    my %args = @_ == 1 && ref $_[0] eq 'HASH' ? %{$_[0]} : @_;

    my $logger = $args{logger} || Log::Any->get_logger;

    die $logger->fatal('No "count" specified') unless $args{count};

    my $class = ref $class_or_instance || $class_or_instance;
    my $self  = bless {
        delayed_start            => 0,
        logger                   => $logger,
        log_level                => DEFAULT_LOG_LEVEL,
        log_level_start_finish   => DEFAULT_LOG_LEVEL_START_FINISH,
        min_sec_between_messages => DEFAULT_MIN_SEC_BETWEEN_MESSAGES,
        prefix                   => DEFAULT_PREFIX,
        %args,
        _initialized       => 0,
        _finished          => 0,
        _current_iteration => 0,
    }, $class;

    for ( qw( log_level log_level_start_finish ) ) {
        $self->{$_} .= "f" unless $self->{$_} =~ /f\z/;
    }

    $self->{_format}         = $self->{prefix} . ': Iteration:%d/%d %.0f%% Elapsed:%s Avg:%s Remaining:%s';
    $self->{_format_nocount} = $self->{prefix} . ': Iteration:%d Elapsed:%s Avg:%s';

    $self->start unless $self->{delayed_start};

    return $self;
}

=head2 start

  my $progress = Log::Any::Progress->new(
      count => $num_things_to_do,
      delayed_start => 1,  # don't start the timer yet
  );

  # Do some other work here that might take some time...

  $progress->start;

  foreach my $thing_to_do (@things_to_do) {
      do_the_thing($thing_to_do);
      $progress->update;
  }

Initialize (or reinitialize) the progress object by resetting the
start time, elapsed time, etc.

This is normally called automatically at object construction time
unless L</delayed_start> is specified, in which case it should be
called explicitly at the appropriate time.

Initializing the progress object (whether done automatically or
manually) causes the first log message to be emitted.

=cut

sub start { shift->update(0) }

=head2 update

  my $progress = Log::Any::Progress->new(
      count => $num_things_to_do,
  );

  foreach my $thing_to_do (@things_to_do) {
      do_the_thing($thing_to_do);
      $progress->update;
  }

Update the iteration count within the progress object and maybe emit
a corresponding log message showing the current progress statistics
(depending on timing and the value of L</min_sec_between_messages>).

Calling C<update> with no arguments increments the internal iteration
count by one.  A positive interger may be passed as an argument to
explicitly update the iteration count to a particular value.

Once the iteration count reaches the specified L</count> value, the
progress is considered to be complete and a final log message is
emitted with summary statistics, and subsequent calls to C<update>
will have no effect.

=cut

sub update
{
    my ($self, $current_iteration) = @_;

    if (defined $current_iteration) {
        $self->{_current_iteration} = $current_iteration;
    }
    else {
        $current_iteration = ++$self->{_current_iteration};
    }

    return if $current_iteration < 0;

    # Allow for reinitialization even if finished:
    return if $self->{_finished} && $current_iteration != 0;

    my $now = [ gettimeofday ];

    my $have_count = $self->{count} > 0;

    if ($current_iteration == 0 || !$self->{_initialized}) {
        $self->{_time_elapsed}      = 0;
        $self->{_time_start}        = $now;
        $self->{_time_last_log}     = $now;
        $self->{_current_iteration} = $current_iteration;
        $self->{_finished}          = 0;
        $self->{_initialized}       = 1;

        my $level  = $self->{log_level_start_finish};
        my $format = $have_count
                         ? $self->{prefix} . ': Iteration:0/%d 0%% STARTING'
                         : $self->{prefix} . ': Iteration:0 STARTING';
        $self->{logger}->$level(
            $format,
            $self->{count},
        );
    }

    return if $current_iteration == 0;

    $self->{_time_elapsed} = tv_interval $self->{_time_start}, $now;

    my $elapsed_sec = $self->{_time_elapsed};
    my $elapsed     = $self->format_seconds($elapsed_sec);

    my $avg_sec = $self->{_time_elapsed} / $current_iteration;
    my $avg     = $self->format_seconds($avg_sec);

    if ($have_count && $current_iteration >= $self->{count}) {

        $self->{_current_iteration} = $current_iteration = $self->{count};
        $self->{_finished} = 1;

        my $level = $self->{log_level_start_finish};
        $self->{logger}->$level(
            $self->{prefix} . ': Iteration:%d/%d 100%% FINISHED Elapsed:%s Avg:%s',
            $current_iteration,
            $self->{count},
            $elapsed,
            $avg,
        );
    }
    else {

        my $elapsed_since_last_log = tv_interval $self->{_time_last_log}, $now;
        return if $elapsed_since_last_log < $self->{min_sec_between_messages};
        $self->{_time_last_log} = $now;

        my $remaining;    # unused if no count
        if ($have_count) {
            my $remaining_sec = ($self->{count}-$current_iteration) * $avg_sec;
            $remaining        = $self->format_seconds($remaining_sec);
        }

        my $level  = $self->{log_level};
        my $format = $have_count ? $self->{_format} : $self->{_format_nocount};
        $self->{logger}->$level(
            $format,
            $current_iteration,
            $have_count ? (
                $self->{count},
                100 * $current_iteration / $self->{count},
            ) : (),
            $elapsed,
            $avg,
            $remaining,
        );
    }

    return;
}

=head2 format_seconds

  my $string = $progress->format_seconds($elapsed_seconds);

This methods formats the elapsed time, average time, and remaining time
values from seconds into something more easily readable.  For example,
C<10000> seconds is formatted as C<2h46m40.000s>.

It can be overridden in a subclass if desired.

=cut

sub format_seconds
{
    my ($self, $sec) = @_;

    my $formatted = '';

    if ($sec >= 60) {
        my $min = int($sec / 60);
        $sec = $sec - ($min * 60);

        if ($min >= 60) {
            my $hours = int($min / 60);
            $min = $min - ($hours * 60);

            if ($hours >= 24) {
                my $days = int($hours / 24);
                $hours = $hours - ($days * 24);

                $formatted .= sprintf '%dd', $days;
            }

            $formatted .= sprintf '%dh', $hours;
        }

        $formatted .= sprintf '%dm', $min;
    }

    $formatted .= sprintf '%.3fs', $sec;

    return $formatted;
}

=head1 AUTHOR

Larry Leszczynski, C<< <larryl at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/larryl/Log-Any-Progress>.

I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc Log::Any::Progress

You can also look for information at:

=over 4

=item * GitHub (report bugs or suggest features here)

L<https://github.com/larryl/Log-Any-Progress>.

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Log-Any-Progress>

=item * Search CPAN

L<https://metacpan.org/release/Log-Any-Progress>

=back

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by Larry Leszczynski.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Log::Any::Progress

