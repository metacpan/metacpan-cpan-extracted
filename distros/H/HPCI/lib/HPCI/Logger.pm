package HPCI::Logger;

use namespace::autoclean;

use Moose::Role;
use Moose::Util::TypeConstraints;

use autodie;
use Carp;

use Log::Log4perl qw(:easy get_logger);
use Log::Log4perl::Appender::Screen;
use Log::Log4perl::Level;
use MooseX::Types::Path::Class qw(Dir File);

=head1 NAME

HPCI::Logger - This role gives the consumer a simple logger attribute

=head1 DESCRIPTION

Defines a log attribute which handles the logging methods
(debug, info, warn, error, fatal).  If a log attribute (of type
Log::Log4perl::Logger) is not provided, one will be created
automatically.

Also allows specifying the directory/file that will be used for
the automatically-created log (if not log was provided), and the
level of message that will be logged.

=head1 Attributes

=over 4

=item * log - A Log::Log4perl object

Used to log all cluster-control activities of HPCI.

If log is not provided, one will be created, using the log_dir and
log_file attributes, or the log_path attribute to specify the file
location where the log will be written.

If a log B<is> provided, then HPCI log messages can be put into
the same log as other logged aspects of the calling program.

=item * log_path - path to file where the log will be written

Optional, only used if no log was explicitly provided.  If this
attribute is not provided, the following two attributes are used.

=item * log_dir - directory where the log will be written

Optional, only used if no log was explicitly provided.  Default value
is B<group_dir>

=item * log_file - filename where the log will be written

Optional, only used if no log was explicitly provided.  Default value
is: "group.log"

=item * log_level - set the log level

Accepts a Log4perl log level value, or a string which can be
converted to such a value.  the default is "info"

=item * log_no_stderr, log_no_file - suppress default logging to stderr or log file

Normally, the default log is written to both stderr and to the log file.
Either of those can be suppressed by setting the corresponding attribute to a true value.
These attributes have no effect if the user provides their own logger instead of using the default one.

=back

=cut

requires qw(group_dir name);

has 'log_dir' => (
	is       => 'ro',
	isa      => Dir,
	coerce   => 1,
	lazy     => 1,
	default  => sub { my $self = shift; $self->group_dir },
);

has 'log_file' => (
	is       => 'ro',
	isa      => 'Str',
	lazy     => 1,
	default  => "group.log",
);

has 'log_path' => (
	is      => 'ro',
	isa     => File,
	coerce  => 1,
	lazy    => 1,
	default => sub {
		my $self = shift;
		$self->log_dir->file( $self->log_file )
	},
);

has 'log_no_stdout' => (
	is      => 'ro',
	isa     => 'Bool',
	default => $ENV{HPCI_LOG_NO_STDOUT} // '0',
);

has 'log_no_file' => (
	is      => 'ro',
	isa     => 'Bool',
	default => $ENV{HPCI_LOG_NO_FILE} // '0',
);

subtype 'LogLevel',
	as 'Num';

coerce 'LogLevel', from 'Str', via { Log::Log4perl::Level::to_priority( uc $_ ) };

has '_log' => (
	is       => 'rw',
	isa      => 'Log::Log4perl::Logger',
	init_arg => undef,
);

has 'log' => (
	is      => 'ro',
	isa     => 'Log::Log4perl::Logger',
	lazy    => 1,
	trigger => \&_log_provided,
	builder => '_default_logger',
);

before 'BUILD' => sub {
	my $self = shift;
	$self->log;
	$self->info( "Log fully initialized." );
};

sub _log_provided {
	my $self = shift;
	$self->_init_stage(2);
}

has '_init_stage' => (
	is => 'rw',
	isa => 'Num',
	init_arg => undef,
	default => 0,
);

has '_log_stack' => (
	is => 'ro',
	isa => 'ArrayRef',
	init_arg => undef,
	default => sub { [] },
);

sub _do_log {
	my $self = shift;
	my $stack = $self->_log_stack;
	if ($self->_init_stage < 2) {
		push @$stack, [ @_ ];
		return;
	}
	$self->_do_a_log( @{ pop @$stack } ) while @$stack;
	$self->_do_a_log( @_ );
}

sub _do_a_log {
	my $self  = shift;
	my $level = shift;
	$self->log->$level( @_ );
}

sub debug {
	my $self = shift;
	$self->_do_log( 'debug', @_ );
}

sub info {
	my $self = shift;
	$self->_do_log( 'info', @_ );
}

sub warn {
	my $self = shift;
	$self->_do_log( 'warn', @_ );
}

sub error {
	my $self = shift;
	$self->_do_log( 'error', @_ );
}

sub fatal {
	my $self = shift;
	$self->_do_log( 'fatal', @_ );
}

has 'log_level' => (
	is      => 'rw',
	isa     => 'LogLevel',
	lazy    => 1,
	coerce  => 1,
	trigger => \&_log_level_change,
	default => 'info',
);

# update log when log_level changes (but not during initialization)
sub _log_level_change {
	my $self      = shift;
	my $new_level = shift;
	$self->log->level($new_level) if @_;
}

sub _default_logger {
	my $self = shift;

	return $self->_log if $self->_init_stage;

	my $log  = get_logger(__PACKAGE__.$self->_unique_name);
	$self->_init_stage(1);
	$self->_log($log);

	$log->level( $self->log_level );

	# Layouts - output formats for appenders. See here for specification:
	# (http://search.cpan.org/~mschilli/Log-Log4perl-1.40/lib/Log/Log4perl/Layout/PatternLayout.pm)
	my %layout = (
		simple  => "%d %6p> %m%n",
		verbose => "%d (%10r) %6p> %m%n",
	);
	$_ = Log::Log4perl::Layout::PatternLayout->new($_) for values %layout;

	if ($self->log_no_file) {
		$log->debug("No file logger initialized");
	}
	else {
		my $file_appender = Log::Log4perl::Appender->new(
			"Log::Log4perl::Appender::File",
			filename => $self->log_path,
			mode     => 'append',
		);
		$file_appender->layout($layout{verbose});
		$log->add_appender($file_appender);
		$log->debug("File logger initialized");
	}

	if ($self->log_no_stdout) {
		$log->debug("No stdout logger initialized");
	}
	else {
		my $stdout_appender = Log::Log4perl::Appender->new(
			'Log::Log4perl::Appender::Screen',
			stderr => 0,
			utf8  => 1,
		);
		$stdout_appender->layout($layout{simple});
		$log->add_appender($stdout_appender);
		$log->debug("Stdout logger initialized");
	}

	$self->_init_stage(2);
	return $log;
}

1;
