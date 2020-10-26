package Log::JSON::Lines;
use 5.006; use strict; use warnings; our $VERSION = '0.02';
use JSON::Lines; use POSIX; use Time::HiRes;
use Fcntl qw/ :flock /; use Clone;

sub new {
	my ($class, $file, $level, %jsonl_args) = @_;
        bless {
		_file	=> $file,
               	_jsonl	=> JSON::Lines->new( %jsonl_args ),
		_level  => defined $level ? $level : 8, 
		_levels	=> {
			emerg	=> 1,
			alert	=> 2,
			crit	=> 3,
			err	=> 4,
			warning	=> 5,
			notice	=> 6,
			info	=> 7,
			debug	=> 8,
		},
	}, $class;
}

sub file { $_[0]->{_file} }

sub levels { $_[0]->{_levels} }

sub level { $_[0]->{_level} }

sub jsonl {
	$_[0]->{_jsonl}->clear_stream;
	$_[0]->{_jsonl};
}

sub log {
	my($self, $level, $msg) = @_;
	die "Invalid level ${level} passed to Log::JSON::Lines->log" 
		unless $self->levels->{$level};
	return if $self->levels->{$level} > $self->level;
	$msg = ! ref $msg ? { message => $msg } : Clone::clone($msg);
	$msg->{level} = $level;
	my ($epoch, $microseconds) = Time::HiRes::gettimeofday;
	$msg->{timestamp} = sprintf "%s.%06.0f+00:00", 
		POSIX::strftime("%Y-%m-%dT%H:%M:%S", gmtime($epoch)),
		$microseconds;
	my @caller; my $i = 0; my @stack;
	while(@caller = caller($i++)){
		next if $caller[0] eq 'Log::JSON::Lines';
		$stack[$i+1]->{module} = $caller[0];
		$stack[$i+1]->{file} = $1 if $caller[1] =~ /([^\/]+)$/;;
		$stack[$i+1]->{line} = $1 if $caller[2] =~ /(\d+)/;
		$stack[$i]->{sub} = $1 if $caller[3] =~ /([^:]+)$/;
	}
	$msg->{stacktrace} = join '->', reverse map {
		my $module = $_->{module} !~ m/^main$/ ? $_->{module} : $_->{file};
		$_->{sub} 
			? $module . '::' . $_->{sub} . ':' . $_->{line}
			: $module . ':' . $_->{line} 
	} grep {
		$_ && $_->{module} && $_->{line} && $_->{file}
	} @stack;
	delete $msg->{stacktrace} unless $msg->{stacktrace};
	$msg = $self->jsonl->add_line($msg);
	open my $fh, ">>", $self->{_file} or die "Cannot open log file $self->{_file}: $!";
  	flock $fh, LOCK_EX;
	print $fh $msg;
  	close $fh;
	$msg;
}

sub emerg {
	my $self = shift;
	$self->log('emerg', @_);
}

sub alert {
	my $self = shift;
	$self->log('alert', @_);
}

sub crit {
	my $self = shift;
	$self->log('crit', @_);
}

sub err {
	my $self = shift;
	$self->log('err', @_);
}

sub warning {
	my $self = shift;
	$self->log('warning', @_);
}

sub notice {
	my $self = shift;
	$self->log('notice', @_);
}

sub info {
	my $self = shift;
	$self->log('info', @_);
}

sub debug {
	my $self = shift;
	$self->log('debug', @_);
}

=head1 NAME

Log::JSON::Lines - Log in JSONLines format

=head1 VERSION

Version 0.02

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

	use Log::JSON::Lines;

	my $logger = Log::JSON::Lines->new(
		'/var/log/definition.log', 
		4,
		pretty => 1,
		canonical => 1
	);
	
	$logger->log('info', 'Lets log JSON lines.');

	$logger->emerg({
		message => 'emergency',
		definition => [
			'a serious, unexpected, and often dangerous situation requiring immediate action.'
		]
	});
	   
	$logger->alert({
		message => 'alert',
		definition => [
			'quick to notice any unusual and potentially dangerous or difficult circumstances; vigilant.'
		]
	});

	$logger->crit({
		message => 'critical',
		definition => [
			'expressing adverse or disapproving comments or judgements.'
		]
	});

	$logger->err({
		message => 'error',
		definition => [
			'the state or condition of being wrong in conduct or judgement.'
		]
	});

	# the below will not log as the severity level is set to 4 (error)

	$logger->warning({
		message => 'warning',
		definition => [
			'a statement or event that warns of something or that serves as a cautionary example.'
		]
	});

	$logger->notice({
		message => 'notice',
		definition => [
			'the fact of observing or paying attention to something.'
		]
	});

	$logger->info({
		message => 'information',
		definition => [
			'what is conveyed or represented by a particular arrangement or sequence of things.'
		]
	});

	$logger->debug({
		message => 'debug',
		definition => [
			'identify and remove errors from (computer hardware or software).'
		]
	});

=head1 DESCRIPTION

This module is a simple logger that encodes data in JSON Lines format. 

JSON Lines is a convenient format for storing structured data that may be processed one record at a time.  It works well with unix-style text processing tools and shell pipelines. It's a great format for log files. It's also a flexible format for passing messages between cooperating processes. 

L<https://jsonlines.org>

=head1 SUBROUTINES/METHODS

=head2 new

Instantiate a new Log::JSON::Lines object. This expects a filename and optionally a level which value is between 0 to 8 and params that will be passed through to instantiate the JSON::Lines object.

	my $logger = Log::JSON::Lines->new($filename, $severity_level, %JSON::Lines::params);

=head2 file

Returns the current log file name.

	$logger->file();

=head2 levels

Returns the severity level mapping.

	$logger->levels();

=head2 level

Returns the current severity level.

	$logger->level();

=head2 jsonl

Returns the JSON::Lines object used to encode the line.

	$logger->jsonl();

=head2 log

Log a message to the specified log file. This expects a severity level to be passed and either a string message or hashref containing information that you would like to log.

	$logger->log($severity, $message);

=head2 emerg - 1

Log a emerg line to the specified log file. This expects either a string or hashref containing information that you would like to log.

	$logger->emerg($message);

=head2 alert - 2

Log a alert line to the specified log file. This expects either a string or hashref containing information that you would like to log.

	$logger->alert($message);

=head2 crit - 3

Log a critical line to the specified log file. This expects either a string or hashref containing information that you would like to log.

	$logger->crit($message);

=head2 err - 4

Log a error line to the specified log file. This expects either a string or hashref containing information that you would like to log.

	$logger->err($message);

=head2 warning - 5

Log a warning line to the specified log file. This expects either a string or hashref containing information that you would like to log.

	$logger->warning($message);

=head2 notice - 6

Log a notice line to the specified log file. This expects either a string or hashref containing information that you would like to log.

	$logger->notice($message);

=head2 info - 7

Log a info line to the specified log file. This expects either a string or hashref containing information that you would like to log.

	$logger->info($message);

=head2 debug - 8

Log a debug line to the specified log file. This expects either a string or hashref containing information that you would like to log.

	$logger->debug($message);

=head1 AUTHOR

LNATION, C<< <email at lngation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-log-json-lines at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Log-JSON-Lines>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Log::JSON::Lines

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Log-JSON-Lines>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Log-JSON-Lines>

=item * Search CPAN

L<https://metacpan.org/release/Log-JSON-Lines>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Log::JSON::Lines
