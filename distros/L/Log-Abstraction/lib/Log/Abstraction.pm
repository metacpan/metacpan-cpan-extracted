package Log::Abstraction;

# TODO: add a minimum logging level

use strict;
use warnings;
use Carp;	# Import Carp for warnings
use Config::Abstraction 0.25;
use Data::Dumper;
use Email::Simple;
use Email::Sender::Simple qw(sendmail);
use Email::Sender::Transport::SMTP;
use Params::Get 0.05;	# Import Params::Get for parameter handling
use Readonly::Values::Syslog 0.02;
use Sys::Syslog 0.28;	# Import Sys::Syslog for syslog support
use Scalar::Util 'blessed';	# Import Scalar::Util for object reference checking

=head1 NAME

Log::Abstraction - Logging Abstraction Layer

=head1 VERSION

0.24

=cut

our $VERSION = 0.24;

=head1 SYNOPSIS

  use Log::Abstraction;

  my $logger = Log::Abstraction->new(logger => 'logfile.log');

  $logger->debug('This is a debug message');
  $logger->info('This is an info message');
  $logger->notice('This is a notice message');
  $logger->trace('This is a trace message');
  $logger->warn({ warning => 'This is a warning message' });

=head1 DESCRIPTION

The C<Log::Abstraction> class provides a flexible logging layer on top of different types of loggers,
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

=item * C<carp_on_warn>

If set to 1,
and C<logger> is not given,
call C<Carp:carp> on C<warn()>.

=item * C<config_file>

Points to a configuration file which contains the parameters to C<new()>.
The file can be in any common format,
including C<YAML>, C<XML>, and C<INI>.
This allows the parameters to be set at run time.

On a non-Windows system,
the class can be configured using environment variables starting with C<"Log::Abstraction::">.
For example:

  export Log::Abstraction::script_name=foo

It doesn't work on Windows because of the case-insensitive nature of that system.

=item * C<level>

The minimum level at which to log something,
the default is "warning".

=item * C<logger>

A logger can be one or more of:

=over

=item * a code reference

=item * an array reference

=item * a file path

=item * a file descriptor

=item * an object

=item * a hash of options

=item * sendmail - send higher priority messages to an email address

=over

=item * array - a reference to an array

=item * fd - containing a file descriptor to log to

=item * file - containing the filename

=back

=back

Defaults to L<Log::Log4perl>.
In that case the argument 'verbose' to new() will raise the logging level.

=item * C<syslog>

A hash reference for syslog configuration.
Only warnings and above will be sent to syslog.
This restriction should be lifted in the future,
since it's reasonable to send notices and above to the syslog.

=item * C<script_name>

The name of the script.
It's needed when C<syslog> is given,
if none is passed, the value is guessed.

=back

Clone existing objects with or without modifications:

    my $clone = $logger->new();

=cut

sub new {
	my $class = shift;

	# Handle hash or hashref arguments
	my %args;

	if((scalar(@_) == 1) && (ref($_[0]) ne 'HASH')) {
		$args{'logger'} = shift;
	} elsif(my $params = Params::Get::get_params(undef, @_)) {
		%args = %{$params};
	}

	# Load the configuration from a config file, if provided
	if(exists($args{'config_file'})) {
		# my $config = YAML::XS::LoadFile($params->{'config_file'});
		if(!-r $args{'config_file'}) {
			croak("$class: ", $args{'config_file'}, ': File not readable');
		}
		if(my $config = Config::Abstraction->new(config_dirs => [''], config_file => $args{'config_file'}, env_prefix => "${class}::")) {
			$config = $config->all();
			if($config->{$class}) {
				$config = $config->{$class};
			}
			my $array = $args{'array'};
			%args = (%{$config}, %args);
			if($array) {
				$args{'array'} = $array;
			}
		} else {
			croak("$class: Can't load configuration from ", $args{'config_file'});
		}
	}

	if(!defined($class)) {
		if((scalar keys %args) > 0) {
			# Using Log::Abstraction:new(), not Log::Abstraction->new()
			carp(__PACKAGE__, ' use ->new() not ::new() to instantiate');
			return;
		}

		# FIXME: this only works when no arguments are given
		$class = __PACKAGE__;
	} elsif(Scalar::Util::blessed($class)) {
		# If $class is an object, clone it with new arguments
		my $clone = bless { %{$class}, %args }, ref($class);
		$clone->{messages} = [ @{$class->{messages}} ];	# Deep copy
		return $clone;
	}

	if($args{'syslog'} && !$args{'script_name'}) {
		require File::Basename && File::Basename->import() unless File::Basename->can('basename');

		# Determine script name
		$args{'script_name'} = File::Basename::basename($ENV{'SCRIPT_NAME'} || $0);

		croak("$class: syslog needs to know the script name") if(!defined($args{'script_name'}));
	}

	my $level = $args{'level'};
	if(defined(my $logger = $args{logger})) {
		if(Scalar::Util::blessed($logger) && (ref($logger) eq __PACKAGE__)) {
			croak("$class: attempt to encapulate ", __PACKAGE__, ' as a logging class, that would add a needless indirection');
		}
	} elsif((!$args{'file'}) && (!$args{'array'})) {
		# Default to Log4perl
		require Log::Log4perl;
		Log::Log4perl->import();

		# FIXME: add default minimum logging level
		Log::Log4perl->easy_init($args{verbose} ? $Log::Log4perl::DEBUG : $Log::Log4perl::ERROR);
		$args{'logger'} = Log::Log4perl->get_logger();
	}

	if($level) {
		if(ref($level) eq 'ARRAY') {
			$level = $level->[0];
		}
		$level = lc($level);
		if(!defined($syslog_values{$level})) {
			Carp::croak("$class: invalid syslog level '$level'");
		}
		$args{'level'} = $level;
	} else {
		# The default minimum level at which to log something is 'warning'
		$args{'level'} = 'warning';
	}

	# Bless and return the object
	return bless {
		messages => [],	# Initialize messages array
		%args,
		level => $syslog_values{$args{'level'}},
	}, $class;
}

# Internal method to log messages. This method is called by other logging methods.
# $logger->_log($level, @messages);
# $logger->_log($level, \@messages);

sub _log
{
	my ($self, $level, @messages) = @_;

	if(!UNIVERSAL::isa((caller)[0], __PACKAGE__)) {
		Carp::croak('Illegal Operation: This method can only be called by a subclass or ourself');
	}

	if(!defined($syslog_values{$level})) {
		Carp::Croak(ref($self), ": Invalid level '$level'");	# "Can't happen"
	}

	if($syslog_values{$level} > $self->{'level'}) {
		# The level is too low to log
		return;
	}

	if((scalar(@messages) == 1) && (ref($messages[0]) eq 'ARRAY')) {
		# Passed a reference to an array
		@messages = @{$messages[0]};
	}
	@messages = grep defined, @messages;

	my $str = join('', @messages);
	chomp($str);

	# Push the message to the internal messages array
	push @{$self->{messages}}, { level => $level, message => join('', @messages) };

	my $class = blessed($self) || '';
	if($class eq __PACKAGE__) {
		$class = '';
	}

	if(my $logger = $self->{'logger'}) {
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
			push @{$logger}, { level => $level, message => join('', @messages) };
		} elsif(ref($logger) eq 'HASH') {
			if(my $file = $logger->{'file'}) {
				# if($file =~ /^([-\@\w.\/\\]+)$/) {
				if($file =~ /^([^<>|*?;!`$"\0-\037]+)$/) {
					$file = $1;	# Will untaint
				} else {
					Carp::croak(ref($self), ": Invalid file name: $file");
				}
				if(open(my $fout, '>>', $logger->{'file'})) {
					print $fout uc($level), "> $class ", (caller(1))[1], ' ', (caller(1))[2], " $str\n" or
						Carp::croak(ref($self), ": Can't write to $file: $!");
					close $fout;
				}
			}
			if(my $array = $logger->{'array'}) {
				push @{$array}, { level => $level, message => join('', @messages) };
			}
			if($logger->{'sendmail'}->{'to'}) {
				# Send an email
				# TODO: throttle the number of emails
				if((!defined($logger->{'sendmail'}->{'level'})) ||
				   ($syslog_values{$level} <= $syslog_values{$logger->{'sendmail'}->{'level'}})) {
					eval {
						my $email = Email::Simple->new('');
						$email->header_set('to', $logger->{'sendmail'}->{'to'});
						if(my $from = $logger->{'sendmail'}->{'from'}) {
							$email->header_set('from', $from);
						} else {
							$email->header_set('from', 'noreply@localhost');
						}
						if(my $subject = $logger->{'sendmail'}->{'subject'}) {
							$email->header_set('subject', $subject);
						}
						$email->body_set(join(' ', @messages));

						# Configure SMTP transport (adjust for your SMTP server)
						my $transport = Email::Sender::Transport::SMTP->new({
							host => $logger->{'sendmail'}->{'host'} || 'localhost',
							port => $logger->{'sendmail'}->{'port'} || 25
						});

						sendmail($email, { transport => $transport });
					};

					if ($@) {
						Carp::carp("Failed to send email: $@");
						return;
					}
				}
			}
			if(my $syslog = $logger->{'syslog'}) {
				if((!defined($syslog->{'level'})) || ($syslog_values{$level} <= $syslog->{'level'})) {
					if(!$self->{_syslog_opened}) {
						# Open persistent syslog connection
						my $facility = delete $syslog->{'facility'} || 'local0';
						my $min_level = delete $syslog->{'level'};
						# CHI uses server, Sys::Syslog uses host :-(
						if($syslog->{'server'}) {
							$syslog->{'host'} = delete $syslog->{'server'};
						}
						Sys::Syslog::setlogsock($syslog) if(scalar keys %{$syslog});
						$syslog->{'facility'} = $facility;
						$syslog->{'level'} = $min_level;

						openlog($self->{script_name}, 'cons,pid', 'user');
						$self->{_syslog_opened} = 1;	# Flag to track active connection
					}

					# Handle syslog-based logging
					eval {
						my $priority = ($level eq 'error') ? 'err' : 'warning';
						my $facility = $syslog->{'facility'};
						Sys::Syslog::syslog("$priority|$facility", join(' ', @messages));
					};
					if($@) {
						my $err = $@;
						$err .= ":\n" . Data::Dumper->new([$syslog])->Dump();
						Carp::carp($err);
					}
				}
			}
				
			if(my $fout = $logger->{'fd'}) {
				print $fout uc($level), "> $class ", (caller(1))[1], ' ', (caller(1))[2], " $str\n" or
					die "ref($self): Can't write to file descriptor: $!";
			} elsif((!$logger->{'file'}) && (!$logger->{'syslog'}) && (!$logger->{'sendmail'})) {
				croak(ref($self), ": Don't know how to deal with the $level message");
			}
		} elsif(!ref($logger)) {
			# If logger is a file path, append the log message to the file
			if(open(my $fout, '>>', $logger)) {
				print $fout uc($level),
					"> $class ",
					(caller(1))[1],
					' (',
					(caller(1))[2],
					"): $str\n";
				close $fout;
			}
		} elsif(Scalar::Util::blessed($logger)) {
			# If logger is an object, call the appropriate method on the object
			if(!$logger->can($level)) {
				if(($level eq 'notice') && $logger->can('info')) {
					# Map notice to info for Log::Log4perl
					$level = 'info';
				} else {
					croak(ref($self), ': ', ref($logger), " doesn't know how to deal with the $level message");
				}
			}
			$logger->$level(@messages);
		} else {
			croak(ref($self), ": configuration error, no handler written for the $level message");
		}
	} elsif($self->{'array'}) {
		push @{$self->{'array'}}, { level => $level, message => join('', @messages) };
	}

	if($self->{'file'}) {
		my $file = $self->{'file'};

		# Untaint the file name
		# if($file =~ /^([-\@\w.\/\\]+)$/) {
		if($file =~ /^([^<>|*?;!`$"\0-\037]+)$/) {
			$file = $1;	# untainted version
		} else {
			croak(ref($self), ": Tainted or unsafe filename: $file");
		}

		if(open(my $fout, '>>', $file)) {
			if(blessed($self) eq __PACKAGE__) {
				print $fout uc($level), '> ', (caller(1))[1], '(', (caller(1))[2], ") $str\n" or
					die "ref($self): Can't write to ", $self->{'file'}, ": $!";
			} else {
				print $fout uc($level), '> ', blessed($self) || '', ' ', (caller(1))[1], '(', (caller(1))[2], ") $str\n" or
					die "ref($self): Can't write to ", $self->{'file'}, ": $!";
			}
			close $fout;
		}
	}
	if(my $fout = $self->{'fd'}) {
		print $fout uc($level), '> ', blessed($self) || '', ' ', (caller(1))[1], '(', (caller(1))[2], ") $str\n" or
			croak(ref($self), ": Can't write to file descriptor: $!");
	}
}

=head2 level

Get/set the minimum level to log at

=cut

sub level
{
	my ($self, $level) = @_;

	if($level) {
		if(!defined($syslog_values{$level})) {
			Carp::carp(ref($self), ": invalid syslog level '$level'");
			return;
		}
		$self->{'level'} = $syslog_values{$level};
	}
	return $self->{'level'};
}

=head2 messages

Return all the messages emmitted so far

=cut

sub messages
{
	my $self = shift;

	return $self->{'messages'};
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

=head2 error

    $logger->error(@messages);

Logs an error message. This method also supports logging to syslog if configured.
If not logging mechanism is set,
falls back to C<Carp>.

=cut

# TODO: do similar things to warn()
sub error {
	my $self = shift;

	$self->_high_priority('error', @_);
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

	$self->_high_priority('warn', @_);
}

=head2 _high_priority

Helper to handle important messages.

=cut

sub _high_priority
{
	my $self = shift;
	my $level = shift;	# 'warn' or 'error'
	my $params = Params::Get::get_params('warning', @_);	# Get parameters

	# Validate input parameters
	return unless ($params && (ref($params) eq 'HASH'));

	# Only logging things higher than warn level
	return if($syslog_values{$level} > $WARNING);

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

	# Log the warning message
	$self->_log($level, $warning);

	if($self->{'carp_on_warn'} || !defined($self->{logger})) {
		# Fallback to Carp if no logger or syslog is defined
		Carp::carp($warning);
	}
}

# Destructor to close syslog connection
sub DESTROY {
	my $self = shift;
	if ($self->{_syslog_opened}) {
		closelog();
		delete $self->{_syslog_opened};
	}
}

=head1 AUTHOR

Nigel Horne C< <njh@nigelhorne.com> >

=head1 SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to C<bug-log-abstraction at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Log-Abstraction>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Log::Abstraction

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/dist/Log-Abstraction>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Log-Abstraction>

=item * CPAN Testers' Matrix

L<http://matrix.cpantesters.org/?dist=Log-Abstraction>

=item * CPAN Testers Dependencies

L<http://deps.cpantesters.org/?module=Log::Abstraction>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2025 Nigel Horne

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
