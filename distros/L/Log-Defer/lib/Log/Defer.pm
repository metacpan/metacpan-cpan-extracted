package Log::Defer;

use strict;

our $VERSION = '0.312';

use Time::HiRes;
use Carp qw/croak/;

use Guard;


sub new {
  my ($class, $cb, $opts) = @_;

  if ($cb) {
    if (ref $cb eq 'CODE') {
      $opts ||= {};
      croak "two callbacks provided" if $opts->{cb};
    } elsif (ref $cb eq 'HASH') {
      $opts = $cb;
      $cb = $opts->{cb};
    } else {
      croak "first arg to new must be a coderef or hashref";
    }
  }

  my $self = $opts;
  bless $self, $class;

  croak "must provide callback to Log::Defer" unless $cb && ref $cb eq 'CODE';

  my $msg = {
    start => format_time(Time::HiRes::time),
  };

  $self->{msg} = $msg;

  $self->{guard} = guard {
    my $end_time = format_time(Time::HiRes::time());
    my $duration = format_time($end_time - $msg->{start});
    $msg->{end} = $duration;

    if (exists $msg->{timers}) {
      foreach my $timer_entry (@{$msg->{timers}}) {
        push @$timer_entry, $duration
          if @$timer_entry == 2;
      }
    }

    $cb->($msg);
  };

  return $self;
}


sub error {
  my ($self, @logs) = @_;

  $self->add_log(10, @logs);
}

sub warn {
  my ($self, @logs) = @_;

  $self->add_log(20, @logs);
}

sub info {
  my ($self, @logs) = @_;

  $self->add_log(30, @logs);
}

sub debug {
  my ($self, @logs) = @_;

  $self->add_log(40, @logs);
}

sub add_log {
  my ($self, $verbosity, @logs) = @_;

  if (!exists $self->{verbosity} || $verbosity <= $self->{verbosity}) {
    my $time = format_time(Time::HiRes::time() - $self->{msg}->{start});

    @logs = $logs[0]->() if $logs[0] && ref $logs[0] eq 'CODE';

    push @{$self->{msg}->{logs}}, [$time, $verbosity, @logs];
  }
}


sub timer {
  my ($self, $name) = @_;

  ##croak "timer $name already registered" if defined $self->{msg}->{timers}->{$name};

  my $timer_start = format_time(Time::HiRes::time() - $self->{msg}->{start});

  ##$self->{msg}->{timers}->{$name} = [ $timer_start, ];

  my $msg = $self->{msg};

  my $timer_entry = [ $name, $timer_start, ];

  $msg->{timers} ||= [];

  push @{$msg->{timers}}, $timer_entry;

  return guard {
    my $timer_end = format_time(Time::HiRes::time() - $msg->{start});

    push @$timer_entry, $timer_end;
  }
}

sub data {
  my ($self) = @_;

  $self->{msg}->{data} ||= {};

  return $self->{msg}->{data};
}



sub merge {
  my ($self, $msg) = @_;

  my $time_offset = $msg->{start} - $self->{msg}->{start};

  ## Merge logs

  my @logs = (
               @{ $self->{msg}->{logs} || [] },
               (map { [ $_->[0] + $time_offset, @$_[1..(@$_-1)] ] } @{ $msg->{logs} || [] })
             );

  $self->{msg}->{logs} = [ sort { $a->[0] <=> $b->[0] } @logs ];

  ## Merge timers

  my $timers = [ @{ $msg->{timers} || [] } ];

  foreach my $timer_entry (@$timers) {
    $timer_entry->[1] += $time_offset;
    $timer_entry->[2] += $time_offset;
  }

  $self->{msg}->{timers} = [ @{ $self->{msg}->{timers} || [] }, @$timers, ];

  ## Merge data

  ## FIXME: This needs to do something like Hash::Merge but I don't want to add a dependency...

  $self->{msg}->{data} = { %{ $self->{msg}->{data} || {} }, %{ $msg->{data} || {} } };


  delete $self->{msg}->{logs} unless @{ $self->{msg}->{logs} };
  delete $self->{msg}->{timers} unless @{ $self->{msg}->{timers} };
  delete $self->{msg}->{data} unless keys %{ $self->{msg}->{data} };
}




#### INTERNAL ####

sub format_time {
  my $time = shift;

  $time = 0 if $time < 0;

  return 0.0 + sprintf("%.6f", $time);
}


1;




__END__

=encoding utf-8

=head1 NAME

Log::Defer - Deferred logs and timers

=head1 SYNOPSIS

    use Log::Defer;
    use JSON::XS; ## or whatever
    use Try::Tiny;

    sub my_logger_function {
      my $msg = shift;
      
      my $encoded_msg = try {
        JSON::XS->new->pretty(1)->encode($msg)
      }
      catch {
        "Failed to JSON encode msg : $_"
      };

      print $encoded_msg; ## usually you'd append this to a file
    }

    my $logger = Log::Defer->new({
                                   cb => \&my_logger_function,
                                   verbosity => 30,
                                 });

    $logger->info("hello world");

    my $timer = $logger->timer('some timer');
    undef $timer; ## stops timer

    undef $logger; ## write out log message

Prints:

    {
       "start" : 1340421702.16684,
       "end" : 0.000249,
       "logs" : [
          [
             0.000147,
             30,
             "hello world"
          ]
       ],
       "timers" : [
          [
             "some timer",
             0.000210,
             0.000233
          ]
       ]
    }



=head1 DESCRIPTION

I believe a lot of log processing is done too early.

This module lets you defer log processing in two ways:

=over 4

=item Defer recording of log messages until some "transaction" has completed

Typically this transaction is something like an HTTP request or a cron job. Generally log messages are easier to read if they are recorded atomically and are not intermingled with log messages created by other transactions.

=item Defer rendering of log messages

Sometimes you don't know how logs should be rendered until long after the message has been written. If you aren't sure what information you'll want to display, or you expect to display the same logs in multiple formats, it makes sense to store your logs in a highly structured format so they can be reliably parsed and processed later.

=back


B<This module doesn't actually write out logs!> To use this module for normal logging purposes you also need a logging library (some of them are mentioned in L<SEE ALSO>).





=head1 USAGE

To use Log::Defer, you create a logger object and pass in a code ref callback (either bare or as C<cb> in an argument hash-ref). This callback will be called once the Log::Defer object is destroyed or once all references to the object go out of scope:

    sub handle_request {
      my $logger = Log::Defer->new(\&logging_function);
      ...
      $logger->info("blah blah");
      ...
    } ## <- $logger goes out of scope here so log is written now

There is no need to manually ensure that every possible code path ends up calling your logging routine at the end because perl's reference counting system does that for you (unless you call C<POSIX::_exit> so don't do that).

In an asynchronous application where multiple asynchronous tasks are kicked off concurrently, each task can keep a reference to the logger object and the log writing will be deferred until all tasks are finished.

Log::Defer makes it easy to gather timing information about the various stages of your request. This is explained further below.




=head1 STRUCTURED LOGS

Free-form line-based log protocols are probably the most common log formats by far. The "format" is usually just coincidental -- whatever happened to be convenient for the programmer to record.

Unfortunately, doing analysis on ad-hoc unstructured logs requires lots of menial coding work writing parsers. Even more annoying is that these parsers are often regexp-based and brittle.

As well as being a perl module, Log::Defer is also a specification for a structured logging format. Although it doesn't impose any external encoding for log messages on you, some tools like the visualisation tool L<log-defer-viz> only support JSON at this time.

The currently recommended format to store logs in is newline-separated, minified JSON. The newline+minification is useful because it allows simple whole-request greping of the logs. With structured logs, much more accurate and flexible greping is also possible, as described in L<log-defer-viz>.



=head1 LOG MESSAGES

Log::Defer objects provide a very basic "log level" system. In order of increasing verbosity, here are the normal logging methods and their numeric log levels:

    $logger->error("...");  # 10
    $logger->warn("...");   # 20
    $logger->info("...");   # 30
    $logger->debug("...");  # 40

You can also use custom log levels:

    $logger->add_log(25, "...");

If you pass in a C<verbosity> argument to the Log::Defer constructor, messages with a higher log level will not be included in the final log message. Otherwise, all log messages are included.

Even if you record noisy debug logs you can filter them out with a visualisation tool at display time. The C<verbosity> argument is only useful for reducing the size of log messages or eliminating unnecessary processing overhead (see the no-overhead debug logs section below).

Note that you can pass in multiple items to a log message and they don't even need to be strings (but make sure you are handling any serialisation exceptions thrown by your encoder as done in the synopsis):

    $logger->error("peer timeout", { waited => $timeout });

In the deferred logging callback, the log messages are recorded in the C<logs> element of the C<$msg> hash. It is an array ref and here is the element that would be pushed onto C<logs> by the C<error> method call above:

    [ 30.201223, 10, "peer timeout", { waited => 30 } ]

The first element is a timestamp of how long the C<error> method was called after the C<start> in seconds (see L<TIMERS> below). The second element is the verbosity level of this message. The remaining elements are passed in untouched from the C<error> method.



=head1 NO-OVERHEAD DEBUG LOGS

If you would like to compute complex messages in debug mode but don't want to burden your production systems with this overhead, you can use delayed message generation:

    $logger->debug(sub { "Connection: " . dump_connection_info($conn) });

The sub will only be invoked if the logger object is instantiated with C<verbosity> of 40 or higher (or you omit C<verbosity> altogether).



=head1 DATA

Instead of log messages, you can directly add items to a C<data> hash reference with the C<data> method:

    $log->data->{ip} = $ENV{REMOTE_ADDR};

This is a useful place to record info that needs to be extracted programatically. Anything you put in the C<data> hash reference will be passed along untouched to your defered callback (but again, make sure you are catching encoder exceptions as shown in the synopsis).



=head1 TIMERS

When the logger object is first created, the current time is recorded as a L<Time::HiRes> absolute timestamp and is stored in the C<start> element of the log hash. C<start> is a L<Time::HiRes> absolute timestamp. All other times are relative offsets from C<start> in seconds.

When the logger object is destroyed, the time elapsed since C<start> is stored in C<end>.

In addition to the start and duration of the entire transaction, you can also record timing data of sub-portions of your transaction by using timer objects.

Timer objects are created by calling the C<timer> method on the logger object. This method should be passed a description of what you are timing.

The timer starts as soon as the timer object is created and stops once the last reference to the timer is destroyed or goes out of scope:

    {
        my $timer = $log_defer_object->timer('running some_code()');
        some_code();
    } ## <- timer is stopped here because $timer goes out of scope

If the logger object itself is destroyed or goes out of scope then all outstanding timers are terminated at that point.


=head1 EXAMPLE LOG MESSAGE

Each structured log message will be passed into the callback provided to C<new> as a perl hash reference that contains various other perl data-structures. What you do at this point is up to you.

Here is a prettified example of a JSON-encoded message:

    {
       "start" : 1340353046.93565,
       "end" : 0.202386,
       "logs" : [
          [
             0.000158,
             30,
             "This is an info message (log level=30)"
          ],
          [
             0.201223,
             20,
             "Warning! \n\n Here is some more data:",
             {
                 "whatever" : 987
             }
          ]
       ],
       "data" : {
          "junkdata" : "some data"
       },
       "timers" : [
          [
             "junktimer",
             0.000224,
             0.100655
          ],
          [
             "junktimer2",
             0.000281,
             0.202386
          ]
       ]
    }



=head1 VISUALISATION

See the L<log-defer-viz> command-line script that renders Log::Defer logs. Timers are shown something like this:

     download file |===============================================|
      cache lookup |==============|
         DB lookup                |======================|
      update cache                                       |==================|
        sent reply                                                 X
    ________________________________________________________________________________
    times in ms    0.2            32.4                             100.7
                                                         80.7              119.2



=head1 MERGING

Sometimes it's useful to create a "child logger" Log::Defer object which is later merged into your main logger. This can be accomplished with the C<merge> method:

    my $logger = Log::Defer->new(sub {
                                   my $merged_msg = shift;
                                   ## ...
                                 });

    ## ...

    {
      my $child_logger = Log::Defer->new(sub {
                                           my $msg = shift;
                                           $logger->merge($msg);
                                         });
    }

    ## ...

This technique is used in L<AnyEvent::Task> so that worker processes can log messages using Log::Defer and these are then merged into a client process's existing logger object.


=head1 ALTERNATE IMPLEMENTATIONS

Michael Pucyk's Python implementation: L<LogDefer Python module|https://github.com/mikep/LogDefer>

Doug Hoyte's C++ implementation: L<LogDefer-CXX|https://github.com/hoytech/LogDefer-CXX>

Richard Farr's D implementation: L<LogDefer-D|https://github.com/rfarr/LogDefer-D>

Mark Jubenville's Javascript implementation: L<log-defer|https://github.com/ioncache/log-defer>


=head1 SEE ALSO

L<Log::Defer github repo|https://github.com/hoytech/Log-Defer>

One way to visualize logs created by this module is with the command-line script L<log-defer-viz>

As mentioned above, this module doesn't itself log messages to disk so you still must use some other module to record your log messages. There are many libraries on CPAN that can do this and there should be at least one that fits your requirements. Some examples are: L<Sys::Syslog>, L<Log::Dispatch>, L<Log::Handler>, L<Log::Log4perl>, L<Log::Fast>, L<AnyEvent::Log>.

Additionally, this module doesn't provide any official serialization format. There are many choices for this, including L<JSON::XS> (JSON is the only format currently supported by L<log-defer-viz>), L<Sereal>, L<Storable>, and L<Data::MessagePack>.

Currently the timestamp generation system is hard-coded to C<Time::HiRes::time>. You should be aware of some caveats related to non-monotonic clocks that are discussed in L<Time::HiRes>.



=head1 AUTHOR

Doug Hoyte, C<< <doug@hcsw.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2012-2016 Doug Hoyte.

This module is licensed under the same terms as perl itself.

=cut
