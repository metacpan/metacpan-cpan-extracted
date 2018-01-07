package Log::Dispatch::Scribe;

use strict;
use warnings;

our $VERSION = '0.07';

use Log::Dispatch 2.00;
use base qw(Log::Dispatch::Output);

use Scribe::Thrift::scribe;
use Thrift::Socket;
use Thrift::FramedTransport;
use Thrift::BinaryProtocol;

sub new {
    my($proto, %params) = @_;
    my $self = bless {}, ref $proto || $proto;

    $self->_basic_init(%params);
    $self->_init(%params);

    return $self;
}

sub _init {
    my $self = shift;
    my %params = @_;

    $self->{retry_plan_a} = 'buffer';
    $self->{retry_plan_b} = 'discard';
    for my $plan (qw/a b/) {
	my $retry_plan = "retry_plan_$plan";
	$self->{$retry_plan} = $params{$retry_plan} if defined $params{$retry_plan};
	die "retry_plan_$plan must be one of 'die', 'wait_forever', 'wait_count', 'discard', 'buffer'" 
	    unless $self->{$retry_plan} =~ m/^(?:die|wait_forever|wait_count|discard|buffer)$/;
    }
    $self->{retry_delay} = $params{retry_delay} || 10;
    $self->{retry_count} = $params{retry_count} || 100;
    $self->{retry_buffer_size} = $params{retry_buffer_size} || 1000;
    $self->{_retry_buffer} = [];
    $self->{default_category} = $params{default_category} || 'none';
    $self->{category} = $params{category};

    eval {
	my $socket = Thrift::Socket->new($params{host} || 'localhost', $params{port} || 1463);
	$self->{transport} = Thrift::FramedTransport->new($socket);
	my $proto = Thrift::BinaryProtocol->new($self->{transport});
	
	$self->{client} = Scribe::Thrift::scribeClient->new($proto, $proto);
    };
    if ($@) {
	if (ref($@) && $@->isa('Thrift::TException')) {
	    die $@->{message};
	}
	else {
	    die $@;
	}
    }

}

sub log_message {
    my $self = shift;
    my %params = @_;

    my $append = 1;
    my $looping = 1;
    my $count = $self->{retry_count};
    while ($looping) {
	eval { 
	    $self->{transport}->open() unless $self->{transport}->isOpen();
	    my $cat = $self->{category} || $params{category} || $params{log4p_category} || $self->{default_category};
	    push(@{$self->{_retry_buffer}}, 
		 Scribe::Thrift::LogEntry->new({ category => $cat, message => $params{message} }))
		if $append && @{$self->{_retry_buffer}} <= $self->{retry_buffer_size};
	    my $result = $self->{client}->Log($self->{_retry_buffer});
	    die "TRY_LATER" if $result == Scribe::Thrift::ResultCode::TRY_LATER;

	    $self->{_retry_buffer} = [];
	    $looping = 0;
	};
	if ($@) {
	    my $msg = $@;
	    if (ref($msg) && $msg->isa('Thrift::TException')) {
		$msg = $msg->{message};
	    }
	    my $retry_plan = $self->{'retry_plan_a'};
	    if ( @{$self->{_retry_buffer}} > $self->{retry_buffer_size}
		 || ($retry_plan eq 'wait_count' && $count < 0) ) {
		$retry_plan = $self->{'retry_plan_b'} 
	    }
	    die $msg if $retry_plan eq 'die';

	    if ($retry_plan eq 'wait_forever') {
		$append = 0;
		sleep($self->{retry_delay});
	    }
	    elsif ($retry_plan eq 'wait_count') {
		die "Retry limit reached following failure: $msg" if $count < 0;
		$append = 0;
		sleep($self->{retry_delay});
		$count--;
	    }
	    elsif ($retry_plan eq 'buffer') {
		die "Full buffer following failure: $msg" if @{$self->{_retry_buffer}} > $self->{retry_buffer_size};
		$looping = 0;
	    }
	    elsif ($retry_plan eq 'discard') {
		pop(@{$self->{_retry_buffer}});
		$looping = 0;
	    }
	}
    }
}

sub DESTROY {
    my $self = shift;
    $self->{transport}->close() if $self->{transport};
}

1;


=head1 NAME

Log::Dispatch::Scribe - Logging via Facebook's Scribe server software

=head1 SYNOPSIS

  use Log::Dispatch::Scribe;

  my $log = Log::Dispatch::Scribe->new(
      name       => 'scribe',
      min_level  => 'info',
      host       => 'localhost',
      port       => 1463,
      default_category => 'test',
      retry_plan_a => 'buffer',
      retry_plan_b => 'die',
  );

  $log->log(level => 'emergency', message => 'something BAD happened');
  $log->log(category => 'system', level => 'emergency', message => 'something BAD happened');

  # Or, via Log::Log4perl (using YAML style configuration in this example):

  log4perl.rootLogger: INFO, Scribe
  log4perl.appender.Scribe: Log::Dispatch::Scribe
  log4perl.appender.Scribe.host: localhost
  log4perl.appender.Scribe.port: 1465
  log4perl.appender.Scribe.category: system
  log4perl.appender.Scribe.layout: Log::Log4perl::Layout::PatternLayout
  log4perl.appender.Scribe.layout.ConversionPattern: "[%d] [%p] %m%n"

  use Log::Log4perl;
  Log::Log4perl->init('log4perlconfig.yml'); # initialise using config file

  $log = Log::Log4perl->get_logger('example.usage');
  $log->info("..."); # Log an info message via Log::Log4perl
  $log->log($INFO, "..."); # alternative syntax

=head1 DESCRIPTION

This module provides a L<Log::Dispatch> style interface to Scribe, and
is also fully compatible with L<Log::Log4perl>. 

Scribe is a server for aggregating log data streamed in real time from
a large number of servers. It is designed to be scalable, extensible
without client-side modification, and robust to failure of the network
or any specific machine. Scribe was developed at Facebook and released
as open source.

=head2 Installing Scribe and Thrift Perl Modules

Scribe, and the related Thrift Perl modules, are available from the
respective source distributions (as of this writing, the modules are not
available on CPAN).  When compiling Scribe, ensure that the namespace
is set to 'namespace perl Scribe.Thrift' in the scribe.thrift file.
Further information is available here:
L<http://notes.jschutz.net/109/perl/perl-client-for-facebooks-scribe-logging-software>.

=head2 Scribe Categories

A Scribe category is an identifier that determines how Scribe handles
the message.  Scribe configuration files define logging behaviour
per-category (or by category prefix, or by a default behaviour if no
matching category is found).

L<Log::Log4perl> also uses logger 'categories' which can be used to
filter messages.  Log4perl categories will typically be more
fine-grained that Scribe categories, but could also conceivably have a
1:1 mapping depending on system design.

C<Log::LogDispatch::Scribe> has several ways of specifying categories
to handle these situations.  'category' and 'default_category' values
may be passed to the constructor, and 'category' and 'log4p_category'
values may be passed to the log_message method.  These are handled as follows:

=over 4

=item * 'category' passed to the constructor overrides all other values and will always be used if defined.  This essentially fixes the Scribe category for this logger instance.

=item * 'category' passed to log_message() will be used otherwise, if defined.

=item * 'log4p_category' passed to log_message() will be used otherwise, if defined.  Log4perl sets this parameter from the logger category.

=item * 'default_category' passed to the constructor is used where no other category parameters have been set.  If no 'default_category' is given, it defaults to 'none'.

=back

=head2 Scribe Server and Error Handling

A Scribe server is expected to be listening for log messages on a given host and port number.

The standard behaviour of most Log::Dispatch::* loggers is to die on
error, such as when a file cannot be written.  It is feasible that the
Scribe server might be restarted from time to time resulting in
temporary connection failures, and it would not be very satisfactory
if one's Perl application should die just because of a temporary
outage of the Scribe server.  Log::Dispatch::Scribe offers several
options for retrying delivery of log messages.

The retry behaviour is set through 'retry_plan_a' and 'retry_plan_b'
parameters.  Plan A is tried first, and if that fails, then Plan B.
There is no Plan C. The 'retry_plan_*' parameters may have any of the
following values:

=over 4

=item * die

Die immediately.  Plan B becomes irrelevant if this is the setting for Plan A.

=item * wait_forever

The Perl application blocks, waiting forever in a loop to reconnect to
the Scribe server, retrying after a specified 'retry_delay'.  Plan B
becomes irrelevant if this is the setting for Plan A.

=item * wait_count

The Perl application blocks, waiting for 'retry_delay' seconds, up to
'retry_count' times, then move on to the next plan if possible,
otherwise die.  (Note that the count is not doubled if both Plan A and
B are 'wait_count').

=item * discard

Discard the current message and return immediately, allowing the Perl
application to continue.

=item * buffer

Buffer messages up to the given 'retry_buffer_size' (a count of number
of messages, not bytes), then move on to the next plan if the buffer
fills.  This allows the Perl application to continue at least until
the buffer fills.

=back

The default settings are:

    retry_plan_a => 'buffer',
    retry_buffer_size => 1000,
    retry_plan_b => 'discard',

in which case the first 1000 messages will be kept, then
subsequent messages discarded until the Scribe service recovers.  The
first 1000 messages will then be flushed to Scribe as soon as it
recovers.


=head1 METHODS

=over 4

=item new

  $log = Log::Dispatch::Scribe->new(%params);

This method takes a hash of parameters. The following options are valid:

=over 4

=item * name, min_level, max_level, callbacks

Same as various Log::Dispatch::* classes.

=item * host, port

The host and port number of the Scribe server.

=item * category, default_category

See above under L</Scribe Categories>.

=item * retry_plan_a, retry_plan_b

See above under L</Scribe Server and Error Handling>.

=item * retry_buffer_size

Maximum number of messages to hold in a memory buffer if Scribe
becomes unavailable and a retry plan is set to 'buffer'. See above
under L</Scribe Server and Error Handling>.  Defaults to 1000.

=item * retry_delay

For the 'wait_forever' and 'wait_count' retry plans, the time interval
(in seconds) between attempts to reconnect.  See above under L</Scribe
Server and Error Handling>.  Defaults to 10 seconds.

=item * retry_count

For the 'wait_count' retry plans, the number of times to retry before
giving up.  See above under L</Scribe Server and Error Handling>.  Defaults to 100.

=back

=item log

  $log->log( level => $level, message => $message, category => $category  )

As for L<Log::Dispatch/log>, but also supports passing in a 'category'
parameter to specify the Scribe category, and 'log4p_category'.  See
above under L</Scribe Categories>.

=back

=head1 SEE ALSO

=over 4

=item * L<http://notes.jschutz.net/109/perl/perl-client-for-facebooks-scribe-logging-software>

=item * L<http://github.com/facebook/scribe/>

=item * L<Log::LogDispatch>

=item * L<Log::Log4perl>

=item * L<File::Tail::Scribe>, L<tail_to_scribe.pl>

=back

=head1 AUTHOR

Jon Schutz, C<< <jon at jschutz.net> >>, L<http://notes.jschutz.net>

=head1 BUGS

Please report any bugs or feature requests to C<bug-log-dispatch-scribe at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Log-Dispatch-Scribe>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Log::Dispatch::Scribe


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Log-Dispatch-Scribe>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Log-Dispatch-Scribe>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Log-Dispatch-Scribe>

=item * Search CPAN

L<http://search.cpan.org/dist/Log-Dispatch-Scribe/>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2009 Jon Schutz, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Log::Dispatch::Scribe
