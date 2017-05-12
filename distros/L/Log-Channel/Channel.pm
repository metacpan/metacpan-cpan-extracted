package Log::Channel;

=head1 NAME

Log::Channel - yet another logging package

=head1 SYNOPSIS

  use Log::Channel;
  my $log = new Log::Channel("topic");
  sub mylog { $log->(@_) }

  $log->("this is a log message, by default going to stderr\n");
  mylog "this is the same as the above\n";
  mylog sprintf ("Hello, %s\n", $user);

  decorate Log::Channel "topic", "%d: (%t) %m\n";
  mylog "this msg will be prefixed with 'timestamp: (topic) ' and end with newline";

  use Log::Dispatch::File;
  Log::Channel::dispatch("topic",
                         new Log::Dispatch::File(name => 'file1',
                                                 min_level => 'info',
                                                 filename  => 'foo.log',
                                                 mode      => 'append'
                                                ));
  mylog "now the message, with decorations, will go to the file, but not stderr";

=head1 DESCRIPTION

Allows for code to specify channels for delivery of logging messages,
and for users of the code to control the delivery and formatting of
the messages.

Yes, this is yet another logging module.  Some differences between
Log::Channel and other logging packages:

=over 4

=item *

Log::Channel does not define a strict classification of logging "levels"
(debug, info, warn, crit, etc.).  You may define a priority for a channel
using set_priority(), but this is optional, and you can name your priority
levels anything you want.

=item *

Able to take over carp and croak events from other modules and route the
output according to the Log::Channel configuration.

=back

=head1 CONFIGURATION

If $ENV{LOG_CHANNEL_CONFIG} is set, then this is taken as the name of a
file containing log configuration instructions which will be loaded the
first time a Log::Channel is created.  Config file syntax is XML:

  <channel_config>
    <dispatch_config>/home/user/configs/log_disp.conf</dispatch_config>
    <channel>
      <topic>One</topic>
      <active />
      <decoration>%t %d: %m</decoration>
      <dispatch>stderr</dispatch>
    </channel>
    <channel>
      <topic>Two::Three</topic>
      <dispatch>Log::Dispatch</dispatch>
      <priority>crit</priority>
    </channel>
    <channel>
      <topic>Four</topic>
      <suppress />
      <dispatch>Log::Dispatch</dispatch>
      <priority>crit</priority>
    </channel>
  </channel_config>

=over 4

=item *

If <dispatch> is omitted, logging defaults to STDERR.

=item *

Logging defaults on for all topics without an explicit <active> or
<suppress> directive.  Omitted topics default on as well.

=item *

To use Log::Dispatch for message dispatch,
specify Log::Dispatch for <dispatch>.  If a filename is
specified in <dispatch_config>, then the Log::Dispatch module will be
configured from that file (see Log::Dispatch::Config), otherwise
Log::Dispatch must be initialized explicitly

=back

=head1 METHODS

=over 4

=cut

use strict;
use vars qw($VERSION);
$VERSION = '0.7';

use Log::Dispatch;
use POSIX qw(strftime);

my %Channel;
my %Config_by_channel;

my $Configuration;

=item B<new>

  my $log_coderef = new Log::Channel "topic";

Define a new channel for logging messages.  All new logs default to
output to stderr.  Specifying a dispatcher (see dispatch method below)
will override this behavior.  Logs default active, but can be disabled.

Note that the object returned from the constructor is a coderef,
not the usual hashref.  This seems to me to be an appropriate use
of closures.

The channel will remember the topic specified when it was
created, prepended by the name of the current package.

Suggested usage is

  sub logme { $log_coderef->(@_) }

So that you can write logging entries like

  logme "This is the message\n";

If omitted, topic will default to the name of the current package.  A
channel must have something for the topic, so the parameter is required
for channels created in the main package.

=cut

sub new {
    my $proto = shift;
    my $class = ref ($proto) || $proto;

    if (!$Configuration) {
	$Configuration = new Log::Channel::Config;
    }

    my $package = (caller)[0];
    if ($package ne "main") {
	unshift @_, $package;
    }
    if (!$Channel{$package}) {
	# make sure channel exists for the entire package
	$class->_make($package);
    }

    return $class->_make(@_);
}

sub _make {
    my $proto = shift;
    my $class = ref ($proto) || $proto;

    my $topic = join("::", @_);
    die "Missing topic for Log::Channel->new" unless $topic;

    my $existing_channel = $Channel{$topic}->{channel};
    return $existing_channel if $existing_channel;

    my $config = _config($topic);

    my $self = _makesub($class, $config);
    bless $self, __PACKAGE__;

    $config->{channel} = $self;
    $Channel{$topic} = $config;
    $Config_by_channel{$self} = $config;

    $Configuration->configure($config) if $Configuration;

    return $self;
}

sub _config {
    # Assumes that caller has verified that there is not an existing
    # channel for this topic.

    my %config;
    $config{topic} = shift;

    return \%config;
}

sub _makesub {
    my ($class, $config) = @_;

    *sym = "${class}::_transmit";
    my $transmit = *sym{CODE};

    return
      sub {
          return if $config->{disabled};

	  my $dispatchers = $config->{dispatchers};
	  if ($dispatchers) {
	      foreach my $dispatcher (@$dispatchers) {
		  $dispatcher->log(level => $config->{priority} || "info",
				   message => _construct($config, @_));
	      }
	  } else {
	      $transmit->($config, _construct($config, @_));
	  }
      };
}

=item B<disable>

  disable Log::Channel "topic";

No further log messages will be transmitted on this topic.  Any
dispatchers configured for the channel will not be closed.

A channel can be disabled before it is created.

Recursively disables sub-topics.

=cut

sub disable {
    shift if $_[0] eq __PACKAGE__;

    my ($topic, $channel_config) = _topic(@_);

    _recurse ($topic, \&disable);

    $channel_config->{disabled} = 1;
}

=item B<enable>

  enable Log::Channel "topic";

Restore transmission of log messages for this topic.  Any dispatchers
configured for the channel will start receiving the new messages.

A channel can be enabled before it is created.

Recursively enables sub-topics.

=cut

sub enable {
    shift if $_[0] eq __PACKAGE__;

    my ($topic, $channel_config) = _topic(@_);

    _recurse ($topic, \&enable);

    $channel_config->{disabled} = 0;
}

=item B<commandeer>

  Log::Channel::commandeer ([$package, $package...]);

Take over delivery of 'carp' log messages for specified packages.  If
no packages are specified, all currently-loaded packages will be
commandeered.

When a package is taken over in this fashion, messages generated via
'carp', 'croak' and so on will be delivered according to the active
dispatch instructions.  Remember, Log::Channel defaults all message
delivery to OFF.

Note that the Carp verbose setting should still work correctly.

=cut

sub commandeer {
    shift if $_[0] eq __PACKAGE__;

    local $^W = 0;		# hide 'subroutine redefined' messages

    if (!@_) {
	# commandeer ALL active modules
	_commandeer_package ("main");
    } else {
	foreach my $package (@_) {
	    _commandeer_package ($package);
	}
    }
}

sub _commandeer_package {
    my ($package) = shift;

    no strict 'refs';

    # The subroutine-override code here was cribbed from Exporter.pm

    *{"$package\::carp"} = \&{__PACKAGE__ . '::_carp'};
    *{"$package\::croak"} = \&{__PACKAGE__ . '::_croak'};

    # Recurse through all sub-packages and commandeer carp in each case.
    # The package-detection code here was taken from Devel::Symdump.

    while (my ($key,$val) = each %{*{"$package\::"}}) {
	local *sym = $val;
	if (defined $val
	    && defined *sym{HASH}
	    && $key =~ /::$/
	    && $key ne "main::"
	    && $key ne "<none>::") {
	    my $subpkg = "$package\::$key";
	    $subpkg =~ s/::$//;
	    _commandeer_package($subpkg);
	}
    }
}

=item B<_carp>

This is the function that is used to supersede the regular Carp::carp
whenever Carp is commandeered on a module.  Note that we still use
Carp::shortmess to generate the actual text, so that if Carp verbose mode
is specified, the full verbose text will go to the log channel.

=cut

sub _carp {
    my $topic = (caller)[0];

    my $channel = $Channel{$topic}->{channel};
    $channel = Log::Channel->_make($topic) unless $channel;

    $channel->(Carp::shortmess @_);
}

=item B<_croak>

Substitute for Carp::croak.  Note that in this case the message will
be output to two places - the channel, and STDERR (or whatever die() does).

=cut

sub _croak {
    my $topic = (caller)[0];

    my $channel = $Channel{$topic}->{channel};
    $channel = Log::Channel->_make($topic) unless $channel;

    $channel->(Carp::shortmess @_);
    die Carp::shortmess @_;
}


=item B<decorate>

  decorate Log::Channel "topic", "decoration-string";

Specify the prefix elements that will be included in each message
logged to the channel identified by "topic".  The formatting options
have been modeled on the log4j system.  Options include:

  %t - channel topic name
  %d{format} - current timestamp; defaults to 'scalar localtime', but
	if an optional strftime format may be provided
  %F - filename where the log message is generated from
  %L - line number
  %p - priority string for this channel (see set_priority)
  %x - context string for this channel (see set_context)
  %m - log message text

Any other textual elements will be transmitted verbatim, eg.
e.g. "%t: %m", "(%t) [%d] %m\n", etc.

Comment on performance: I haven't benchmarked the string formatting
here.  s///egx might not be the fastest way to do this.

=cut

sub decorate {
    shift if $_[0] eq __PACKAGE__;
    my $decorator = pop;
    my ($topic, $channel_config) = _topic(@_);

    $channel_config->{decoration} = $decorator;
}


=item B<set_context>

  set_context Log::Channel "topic", $context;

Associate some information (a string) with a log channel, specified
by topic.  This string will be included in log messages if the 'context'
decoration is activated.

This is intended for when messages should include reference info that
changes from call to call, such as a current session id, user id,
transaction code, etc.

=cut

sub set_context {
    shift if $_[0] eq __PACKAGE__;
    my $context = pop;
    my ($topic, $channel_config) = _topic(@_);

    $channel_config->{context} = $context;
}


# copying the decorator formats from http://jakarta.apache.org/log4j

my %decorator_func = (
		      "t" => \&_decorate_topic,
		      "d" => \&_decorate_timestamp,
		      "m" => \&_decorate_message,
		      "F" => \&_decorate_filename,
		      "L" => \&_decorate_lineno,
		      "p" => \&_decorate_priority,
		      "x" => \&_decorate_context,
		     );

sub _decorate_topic {
    my ($config, $format, $textref) = @_;
    return $config->{topic};
}
sub _decorate_timestamp {
    my ($config, $format, $textref) = @_;
    return scalar localtime if !$format;
    return strftime $format, localtime;
}
sub _decorate_message {
    my ($config, $format, $textref) = @_;
    return join("", @$textref);
}
sub _decorate_filename {
    my ($config, $format, $textref) = @_;
    return (caller(3+$format))[1];
}
sub _decorate_lineno {
    my ($config, $format, $textref) = @_;
    return (caller(3+$format))[2];
}
sub _decorate_priority {
    my ($config, $format, $textref) = @_;
    return $config->{priority};
}
sub _decorate_context {
    my ($config, $format, $textref) = @_;
    return $config->{context};
}

sub _construct {
    my ($config) = shift;

    my $decoration = $config->{decoration} or return join("", @_);

    $decoration =~
      s/
	%((.)(\{([^\}]+)\})*)	# decorator directive can have a format string
       /
	$decorator_func{$2}->($config, $4, \@_);
       /egx;

    return $decoration;
}


# internal method - default output destination in stderr

sub _transmit {
    my ($config) = shift;

    print STDERR @_;
}


=item B<dispatch>

  dispatch Log::Channel "topic", (new Log::Dispatch::Xyz(...),...);

Map a logging channel to one or more Log::Dispatch dispatchers.

Any existing dispatchers for this channel will be closed.

Dispatch instructions can be specified for a channel that has not
been created.

The only requirement for the dispatcher object is that it supports
a 'log' method.  Every configured dispatcher on a channel will receive
all messages on that channel.

=cut

sub dispatch {
    shift if $_[0] eq __PACKAGE__;
    my ($topic, $channel_config) = _topic(shift);

    # input validation
    foreach my $dispatcher (@_) {
	_croak "Expected a Log::Dispatch object"
	  unless UNIVERSAL::can($dispatcher, "log");
    }

    _recurse($topic, \&dispatch, @_);

    $channel_config->{dispatchers} = \@_;
}

=item B<undispatch>

  undispatch Log::Channel "topic";

Restore a channel to its default destination (ie. STDERR).

Any existing dispatchers for this channel will be closed.

=cut

sub undispatch {
    shift if $_[0] eq __PACKAGE__;
    my ($topic, $channel_config) = _topic(shift);

    delete $channel_config->{dispatchers};
    _recurse($topic, \&undispatch);
}

=item B<set_priority>

# if we need to be able to associate priority (debug, info, emerg, etc.)
# with each log message, this might be enough.  It's by channel, though,
# not per message.  Since the overhead of creating a channel is minimal,
# I prefer to associate one priority to all messages on the channel.
# This also means that a module developer doesn't have to specify the
# priority of a message - a user of the module can set a particular
# channel to a different priority.
# Valid priority values are not enforced here.  These could potentially
# vary between dispatchers.  UNIX syslog specifies one set of priorities
# (emerg, alert, crit, err, warning, notice, info, debug).
# The log4j project specifies a smaller set (error, warn, info, debug, log).
# Priority ranking is also controlled by the dispatcher, not the channel.

=cut

sub set_priority {
    shift if $_[0] eq __PACKAGE__;
    my $priority = pop;
    my ($topic, $channel_config) = _topic(@_);

    $channel_config->{priority} = $priority;
}


=item B<status>

  status Log::Channel;

Return a blob of information describing the state of all the configured
logging channels, including suppression state, decorations, and dispatchers.

Currently does nothing.

=cut

sub status {
    return \%Channel;
}


# _recurse
#
# Call the specified function on the name of every sub-package
# in this package.  Used to recursively apply constraints to
# sub-packages (disable, enable, commandeer).
#
sub _recurse {
    my $package = shift;
    my $coderef = shift;

    foreach my $topic (keys %Channel) {
	if ($topic =~ /^$package\::/) {
	    $coderef->($topic, @_);
	}
    }
}

sub _topic {
    my ($topic, $channel_config);

    if (ref $_[0] eq __PACKAGE__) {
	# invoked as $channel->disable
	$channel_config = $Config_by_channel{$_[0]};
	$topic = $channel_config->{topic};
    } else {
	$topic = join("::", @_);
	die "Missing topic for Log::Channel->disable" unless $topic;
	$channel_config = $Channel{$topic};
	if (!$channel_config) {
	    Log::Channel->_make($topic);
	    $channel_config = $Channel{$topic};
	}
    }

    return ($topic, $channel_config);
}

=item B<export>

  $channel->export("subname");

Exports a logging subroutine into the calling package's namespace.
Does the same thing as

  sub mylog { $channel->(@_) }

=cut

sub export {
    my ($channel, $subname) = @_;

    my $package = (caller)[0];

    no strict 'refs';

    *{"$package\::$subname"} = sub { $channel->(@_) };
}

1;

=back

=head1 TO DO

=over 4

=item *

Syntax-checking on decorator format strings.

=item *

Status reporting available for what log classes have been initiated,
activation status, and where the messages are going.

=item *

Ability to commandeer "print STDERR".  To pick up other types of module
logging - and capture die() messages.

=back

=head1 AUTHOR

Jason W. May <jmay@pobox.com>

=head1 COPYRIGHT

Copyright (C) 2001,2002 Jason W. May.  All rights reserved.
This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

  Log::Dispatch and Log::Dispatch::Config
  http://jakarta.apache.org/log4j

And many other logging modules:
  Log::Agent
  CGI::Log
  Log::Common
  Log::ErrLogger
  Log::Info
  Log::LogLite
  Log::Topics
  Log::TraceMessages
  Pat::Logger
  POE::Component::Logger
  Tie::Log
  Tie::Syslog
  Logfile::Rotate
  Net::Peep::Log
  Devel::TraceFuncs
  Devel::TraceMethods
  Log::AndError

=cut


package Log::Channel::Config;

use strict;

use Carp;
use Log::Channel;
use XML::Simple;
use Log::Dispatch::Config;

sub new {
    my $proto = shift;
    my $class = ref ($proto) || $proto;

    my $config_file = $ENV{LOG_CHANNEL_CONFIG};
    return if !$config_file;	# this is not an error condition

    my $config = XMLin($config_file);

    if ($config) {
	# validate configuration
	my $dispatcher;
	if ($config->{dispatch_config}) {
	    Log::Dispatch::Config->configure($config->{dispatch_config});
	}

	foreach my $channel_config (@{$config->{channel}}) {
	    $config->{topic}->{$channel_config->{topic}} = $channel_config;
	}
    }

    bless $config, $class;
    return $config;
}

sub configure {
    my ($self, $channel_config) = @_;

    my $topic = $channel_config->{topic};
    while ($topic) {
	if ($self->{topic}->{$topic}) {
	    _configure($self->{topic}->{$topic}, $channel_config->{channel});
	    return;
	}
	# climb the hierarchy
	($topic) = $topic =~ /(.*)::\w+$/;
    }
    # if we get here, there's no configuration for this topic, use defaults
}

sub _configure {
    my ($config, $channel) = @_;

    if ($config->{suppress}) {
	disable $channel;
    } else {
	# default is enabled
	enable $channel;
    }

    decorate $channel ($config->{decoration})
      if $config->{decoration};

    if (defined $config->{dispatch}
	&& $config->{dispatch} =~ /Log::Dispatch/oi) {
	dispatch $channel (Log::Dispatch::Config->instance);
    }

    $channel->set_priority($config->{priority})
      if $config->{priority};
}

1;
