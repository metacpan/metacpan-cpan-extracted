package Gears::Logger;
$Gears::Logger::VERSION = '0.101';
use v5.40;
use Mooish::Base -standard;

use Data::Dumper;
use Time::Piece;

# apache format
has param 'date_format' => (
	isa => Str,
	default => '%a %b %d %T %Y'
);

# apache-like format
has param 'log_format' => (
	isa => Maybe [Str],
	default => '[%s] [%s] %s'
);

# implements actual logging of a single message
# must be reimplemented
sub _log_message ($self, $level, $message)
{
	...;
}

sub message ($self, $level, @messages)
{
	my $format = $self->log_format;
	my $date;

	for my $message (@messages) {
		$message = ref $message ? Dumper($message) : $message;
		chomp $message;

		if (defined $format) {
			$date //= localtime->strftime($self->date_format);
			$message = sprintf $format, $date, uc $level, $message;
		}

		$self->_log_message($level, $message);
	}

	return $self;
}

__END__

=head1 NAME

Gears::Logger - Abstract logging interface

=head1 SYNOPSIS

	package My::Gears::Logger;

	use v5.40;
	use Mooish::Base -standard;

	extends 'Gears::Logger';

	sub _log_message ($self, $level, $message)
	{
		say STDERR $message;
	}

	# In your code
	use My::Gears::Logger;

	my $logger = My::Gears::Logger->new;
	$logger->message(error => 'Something went wrong');
	$logger->message(info => 'All is well');

=head1 DESCRIPTION

Gears::Logger is an abstract base class for logging functionality. It provides
message formatting capabilities but leaves the actual logging implementation to
subclasses. This allows different logging backends (files, STDERR, syslog, etc.)
to be used with a consistent interface.

The logger formats messages with a timestamp and log level, and can handle both
scalar and reference values using Data::Dumper for complex data structures.

=head1 EXTENDING

This logger is abstract by design. A subclass must be created that implements
the C<_log_message> method to define where and how log messages are written.

Here is how a minimal working logger subclass could be implemented:

	package My::Gears::Logger;

	use v5.40;
	use Mooish::Base -standard;

	extends 'Gears::Logger';

	sub _log_message ($self, $level, $message)
	{
		# Write to STDERR
		say STDERR $message;
	}

=head1 INTERFACE

=head2 Attributes

=head3 date_format

A string specifying the date format for log timestamps. Uses L<Time::Piece>
strftime format. Defaults to C<'%a %b %d %T %Y'> (Apache log format).

I<Available in constructor>

=head3 log_format

A string specifying the overall log message format. Uses sprintf format with
three placeholders: timestamp, log level, and message. Defaults to
C<'[%s] [%s] %s'>.

I<Available in constructor>

=head2 Methods

=head3 new

	$object = $class->new(%args)

A standard Mooish constructor. Consult L</Attributes> section to learn what
keys can be passed in C<%args>.

=head3 message

	$logger = $logger->message($level, @messages)

Logs one or more messages at the specified level. The C<$level> is a string
(typically C<'error'>, C<'warn'>, C<'info'>, C<'debug'>, etc.) and C<@messages>
can be scalar strings or references. References will be formatted using
L<Data::Dumper>.

Returns the logger object for method chaining.

