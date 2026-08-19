# ex:ts=8 sw=4:
# $OpenBSD$
#
# Copyright (c) 2026 Dick Olsson <hi@senzilla.io>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

use v5.36;

package Fugu::MQTT;
our $VERSION = '0.1.2';

use Fugu::Log;
use Fugu::Timeout;

# Fugu::MQTT - a subscribing MQTT client for a single-threaded
# daemon.
#
# The module wraps Net::MQTT::Simple. It never blocks the caller: tick
# drains what arrived and returns, so an event loop can hold the MQTT
# connection beside its own descriptors.
#
# Net::MQTT::Simple loads at connect time. Thus the module keeps the
# core-Perl load contract of Fugu, and a daemon whose broker is
# optional still runs without the library.

# _log_warnings($format, \@warnings):
#	Send the warnings that Net::MQTT::Simple emitted to the
#	logger, without the program name it prefixes.
sub _log_warnings ( $format, $warnings )
{
	for my $warning (@$warnings) {
		chomp $warning;
		$warning =~ s{^(?:.*/)?[^/]+:\s+}{};
		Fugu::Log->default->debug( $format, $warning );
	}

	return;
}

sub new ( $class, %args )
{
	my $self = bless {
		host     => $args{host} // '127.0.0.1',
		port     => $args{port} // 1883,
		username => $args{username},
		password => $args{password},

		subscriptions    => {},
		pending_messages => [],
		connected        => 0,
		last_tick        => 0,
	}, $class;

	return $self;
}

sub mqtt_connect ( $self, $timeout = 10 )
{
	Fugu::Log->default->debug(
		'Connecting to MQTT broker at %s:%d (timeout: %ds)',
		$self->{host}, $self->{port}, $timeout );

	# Try to load Net::MQTT::Simple if it is available
	local $@;

	# Capture the warnings from Net::MQTT::Simple
	my @warnings;
	local $SIG{__WARN__} = sub {
		push @warnings, shift;
	};

	# The connect can block in the resolver or the handshake, and a
	# poll loop cannot interrupt either. Thus the guard is an alarm.
	my $success = eval {
		Fugu::Timeout::bounded(
			$timeout,
			sub {

				# On OpenBSD the packages install under
				# site_perl, which a perl started with a
				# pruned @INC does not hold
				unshift @INC,
				    '/usr/local/libdata/perl5/site_perl'
				    unless grep {
					$_ eq
					    '/usr/local/libdata/perl5/site_perl'
				    } @INC;

				require Net::MQTT::Simple;

				my $server = $self->{host};
				if ( $self->{port} != 1883 ) {
					$server .= ':' . $self->{port};
				}

				my $mqtt = Net::MQTT::Simple->new($server);

				# Set the login credentials if the
				# configuration has a username
				if ( defined $self->{username} ) {
					$mqtt->login(
						$self->{username},
						$self->{password} // ''
					);
				}

				$self->{client}    = $mqtt;
				$self->{connected} = 1;
				Fugu::Log->default->debug(
					'Successfully connected to MQTT broker'
				);
				return 1;
			} );
	};

	_log_warnings( 'MQTT connection warning: %s', \@warnings );

	if ( $@ || !$success ) {
		my $err = $@ || "no answer within ${timeout}s";
		Fugu::Log->default->error( 'MQTT connection failed: %s', $err );
		$self->{connected} = 0;
	}

	return $self->{connected};
}

# $self->subscribe($topic, $callback):
#	Subscribe to an MQTT topic with a callback for messages.
#	$callback receives ($topic, $payload).
sub subscribe ( $self, $topic, $callback )
{
	Fugu::Log->default->debug( 'Subscribing to MQTT topic: %s', $topic );
	$self->{subscriptions}{$topic} = $callback;

	return unless $self->{connected} && $self->{client};

	$self->_register($topic);
}

# $self->_register($topic):
#	Register one topic with the client. Net::MQTT::Simple uses a
#	different subscription model: the module registers the topics
#	and polls for messages in tick(). Since 1.33,
#	Net::MQTT::Simple passes a retain flag as a third argument.
#	Accept and ignore all extra arguments.
sub _register ( $self, $topic )
{
	eval {
		$self->{client}->subscribe(
			$topic,
			sub ( $topic_received, $payload, @ ) {
				push @{ $self->{pending_messages} },
				    [ $topic_received, $payload ];
			} );
	};

	if ($@) {
		Fugu::Log->default->error( 'MQTT subscribe error for %s: %s',
			$topic, $@ );
	}

	return;
}

sub publish ( $self, $topic, $payload, $retain = 0 )
{
	return unless $self->{connected} && $self->{client};

	Fugu::Log->default->debug(
		'Publishing to MQTT topic %s: %s',
		$topic,
		length($payload) > 50
		? substr( $payload, 0, 50 ) . '...'
		: $payload
	);
	eval {
		if ($retain) {
			$self->{client}->retain( $topic, $payload );
		}
		else {
			$self->{client}->publish( $topic, $payload );
		}
	};

	if ($@) {
		Fugu::Log->default->error( 'MQTT publish error: %s', $@ );
	}
}

# $self->tick($timeout):
#	Process the pending MQTT messages. Call this method from the
#	main event loop. $timeout is the maximum wait in seconds. The
#	default is 0, which does not block. The method returns the
#	number of processed messages.
sub tick ( $self, $timeout = 0 )
{
	return 0 unless $self->{connected} && $self->{client};

	my $processed = 0;

	# Process the incoming messages with the timeout.
	# Capture the warnings from Net::MQTT::Simple connection attempts.
	my @warnings;
	local $SIG{__WARN__} = sub {
		push @warnings, shift;
	};

	eval { $self->{client}->tick($timeout); };

	_log_warnings( 'MQTT: %s', \@warnings );

	if ($@) {

		# The connection is possibly lost
		if ( $@ =~ /connection|socket|closed/i ) {
			$self->{connected} = 0;
			Fugu::Log->default->warning( 'MQTT connection lost: %s',
				$@ );
			return 0;
		}
		Fugu::Log->default->error( 'MQTT tick error: %s', $@ );
	}

	# Process the pending messages through the callbacks
	while ( @{ $self->{pending_messages} } > 0 ) {
		my $msg = shift @{ $self->{pending_messages} };
		my ( $topic_received, $payload ) = @$msg;

		$processed +=
		    $self->_dispatch_message( $topic_received, $payload );
	}

	$self->{last_tick} = time;
	return $processed;
}

# $self->_dispatch_message($topic, $payload):
#	Send the message to the subscription callbacks that match.
#	$callback receives ($topic, $payload). The topic is the
#	actual received topic.
sub _dispatch_message ( $self, $topic, $payload )
{
	my $dispatched = 0;

	for my $pattern ( keys %{ $self->{subscriptions} } ) {
		if ( $self->_topic_matches( $pattern, $topic ) ) {
			my $callback = $self->{subscriptions}{$pattern};
			eval { $callback->( $topic, $payload ); };
			if ($@) {
				Fugu::Log->default->error(
					'MQTT callback error for %s: %s',
					$topic, $@ );
			}
			$dispatched++;
		}
	}

	return $dispatched;
}

# $self->_topic_matches($pattern, $topic):
#	Check if a topic matches a subscription pattern.
#	The pattern supports the + (single level) and # (multi level)
#	wildcards.
sub _topic_matches ( $self, $pattern, $topic )
{
	# Exact match
	return 1 if $pattern eq $topic;

	# The pattern has no wildcards, so the match must be exact
	return 0 unless $pattern =~ m{[+#]};

	my @pattern_parts = split m{/}, $pattern;
	my @topic_parts   = split m{/}, $topic;

	for my $i ( 0 .. $#pattern_parts ) {
		my $p = $pattern_parts[$i];

		# The multi-level wildcard matches all remaining levels
		return 1 if $p eq '#';

		# The topic is shorter than the pattern (without #)
		return 0 if $i > $#topic_parts;

		# The single-level wildcard matches any single level
		next if $p eq '+';

		# The level must match exactly
		return 0 if $p ne $topic_parts[$i];
	}

	# The loop matched all pattern levels. The topic must not
	# have more levels.
	return @topic_parts == @pattern_parts;
}

# $self->resubscribe():
#	Subscribe to all topics again after a reconnection.
sub resubscribe ($self)
{
	return unless $self->{connected} && $self->{client};

	$self->_register($_) for keys %{ $self->{subscriptions} };
}

# $self->reconnect():
#	Try to connect to the broker again.
#	The method returns 1 on success and 0 on failure.
sub reconnect ($self)
{
	Fugu::Log->default->debug('Attempting MQTT reconnection');
	$self->disconnect();

	if ( $self->mqtt_connect() ) {
		$self->resubscribe();
		Fugu::Log->default->debug('MQTT reconnected successfully');
		return 1;
	}

	return 0;
}

sub disconnect ($self)
{
	if ( $self->{connected} && $self->{client} ) {
		eval { $self->{client}->disconnect(); };
		$self->{client}    = undef;
		$self->{connected} = 0;
	}
	$self->{pending_messages} = [];
}

sub is_connected ($self)
{
	return $self->{connected};
}

# $self->subscriptions():
#	Return the list of subscribed topics.
sub subscriptions ($self)
{
	return keys %{ $self->{subscriptions} };
}

1;
