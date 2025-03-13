package Log::Abstraction;

use strict;
use warnings;
use Carp;	# Import Carp for warnings
use Config::Auto;
use Params::Get;	# Import Params::Get for parameter handling
use Sys::Syslog;	# Import Sys::Syslog for syslog support
use Scalar::Util 'blessed';	# Import Scalar::Util for object reference checking

=head1 NAME

Log::Abstraction - Logging abstraction layer

=head1 VERSION

0.06

=cut

our $VERSION = 0.06;

=head1 SYNOPSIS

  use Log::Abstraction;

  my $logger = Log::Abstraction->new(logger => 'logfile.log');

  $logger->debug('This is a debug message');
  $logger->info('This is an info message');
  $logger->notice('This is a notice message');
  $logger->trace('This is a trace message');
  $logger->warn({ warning => 'This is a warning message' });

=head1 DESCRIPTION

The C<Log::Abstraction> class provides a flexible logging layer that can handle different types of loggers,
including code references, arrays, file paths, and objects.
It also supports logging to syslog if configured.

=head1 METHODS

=head2 new

  my $logger = Log::Abstraction->new(%args);

Creates a new C<Log::Abstraction> object.
The argument can be a hash,
a reference to a hash or the C<logger> value.
The following arguments can be provided:

=over

=item * C<config_file>

Points to a configuration file which contains the parameters to C<new()>.
The file can be in any common format including C<YAML>, C<XML>, and C<INI>.
This allows the parameters to be set at run time.

=item * C<logger> - A logger can be a code reference, an array reference, a file path, or an object.

=item * C<syslog> - A hash reference for syslog configuration.

=item * C<script_name> - Name of the script, needed when C<syslog> is given

=back

=cut

sub new {
	my $class = shift;

	# Handle hash or hashref arguments
	my %args;
	if(@_ == 1) {
		if(ref $_[0] eq 'HASH') {
			# If the first argument is a hash reference, dereference it
			%args = %{$_[0]};
		} else {
			$args{'logger'} = shift;
		}
	} elsif((scalar(@_) % 2) == 0) {
		# If there is an even number of arguments, treat them as key-value pairs
		%args = @_;
	} else {
		# If there is an odd number of arguments, treat it as an error
		croak(__PACKAGE__, ': Invalid arguments passed to new()');
	}

	# Load the configuration from a config file, if provided
	if(exists($args{'config_file'})) {
		my $config = Config::Auto::parse($args{'config_file'});
		# my $config = YAML::XS::LoadFile($args{'config_file'});
		%args = (%{$config}, %args);
	}

	if($args{'syslog'} && !$args{'script_name'}) {
		croak(__PACKAGE__, ' syslog needs to know the script name');
	}

	my $self = {
		messages => [],  # Initialize messages array
		%args,
	};
	return bless $self, $class;  # Bless and return the object
}

# Internal method to log messages. This method is called by other logging methods.
# $logger->_log($level, @messages);
# $logger->_log($level, \@messages);

sub _log {
	my ($self, $level, @messages) = @_;

	if(!UNIVERSAL::isa((caller)[0], __PACKAGE__)) {
		Carp::croak('Illegal Operation: This method can only be called by a subclass or ourself');
	}

	if((scalar(@messages) == 1) && (ref($messages[0]) eq 'ARRAY')) {
		# Passed a reference to an array
		@messages = @{$messages[0]};
	}

	# Push the message to the internal messages array
	push @{$self->{messages}}, { level => $level, message => join('', grep defined, @messages) };

	if(my $logger = $self->{logger}) {
		if(ref($logger) eq 'CODE') {
			# If logger is a code reference, call it with log details
			$logger->({
				class => blessed($self) || __PACKAGE__,
				file => (caller(1))[1],
				# function => (caller(1))[3],
				line => (caller(1))[2],
				level => $level,
				message => \@messages,
			});
		} elsif(ref($logger) eq 'ARRAY') {
			# If logger is an array reference, push the log message to the array
			push @{$logger}, { level => $level, message => join('', grep defined, @messages) };
		} elsif(!ref($logger)) {
			# If logger is a file path, append the log message to the file
			if(open(my $fout, '>>', $logger)) {
				print $fout uc($level), ': ', blessed($self) || __PACKAGE__, ' ', (caller(1))[1], (caller(1))[2], ' ', join('', @messages), "\n";
				close $fout;
			}
		} else {
			# If logger is an object, call the appropriate method on the object
			$logger->$level(@messages);
		}
	}
}

=head2 debug

  $logger->debug(@messages);

Logs a debug message.

=cut

sub debug {
	my $self = shift;
	$self->_log('debug', @_);
}

=head2 info

  $logger->info(@messages);

Logs an info message.

=cut

sub info {
	my $self = shift;
	$self->_log('info', @_);
}

=head2 notice

  $logger->notice(@messages);

Logs a notice message.

=cut

sub notice {
	my $self = shift;
	$self->_log('notice', @_);
}

=head2 trace

  $logger->trace(@messages);

Logs a trace message.

=cut

sub trace {
	my $self = shift;
	$self->_log('trace', @_);
}

=head2 warn

  $logger->warn(@messages);
  $logger->warn(\@messages);
  $logger->warn(warning => \@messages);

Logs a warning message. This method also supports logging to syslog if configured.
If not logging mechanism is set,
falls back to C<Carp>.

=cut

sub warn {
	my $self = shift;
	my $params = Params::Get::get_params('warning', @_);	# Get parameters

	# Validate input parameters
	return unless ($params && (ref($params) eq 'HASH'));
	my $warning = $params->{warning};
	if(!defined($warning)) {
		if(scalar(@_) && !ref($_[0])) {
			# Given an array
			$warning = join('', @_);
		} else {
			return;
		}
	}
	if(ref($warning) eq 'ARRAY') {
		# Given "message => [ ref to array ]"
		$warning = join('', @{$warning});
	}

	if($self eq __PACKAGE__) {
		# If called from a class method, use Carp to warn
		Carp::carp($warning);
		return;
	}

	if($self->{syslog}) {
		# Handle syslog-based logging
		if(ref($self->{syslog}) eq 'HASH') {
			Sys::Syslog::setlogsock($self->{syslog});
		}
		openlog($self->{script_name}, 'cons,pid', 'user');
		syslog('warning|local0', $warning);
		closelog();
	}

	# Log the warning message
	$self->_log('warn', $warning);
	if((!defined($self->{logger})) && (!defined($self->{syslog}))) {
		# Fallback to Carp if no logger or syslog is defined
		Carp::carp($warning);
	}
}

=head1 AUTHOR

Nigel Horne C< <njh@nigelhorne.com> >

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2025 Nigel Horne

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
