package Log::Deep;

# Created on: 2008-10-19 04:44:02
# Create by:  ivan
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use version;
use Carp qw/croak longmess/;
use List::MoreUtils qw/any/;
use Readonly;
use Clone qw/clone/;
use Data::Dump::Streamer;
use POSIX qw/strftime/;
use Fcntl qw/SEEK_END/;
use English qw/ -no_match_vars /;
use base qw/Exporter/;

our $VERSION     = version->new('0.3.5');

Readonly my @LOG_LEVELS => qw/info message debug warn error fatal/;

sub new {
	my $class  = shift;
	my %param  = @_;
	my $self   = {};

	bless $self, $class;

	$self->{dump} = Data::Dump::Streamer->new()->Indent(0)->Names('DATA');

	# set up log levels
	if (!$param{-level}) {
		$self->level(qw/warn error fatal/);
	}
	else {
		$self->level(ref $param{-level} eq 'ARRAY' ? @{$param{-level}} : $param{-level});
	}

	# set up the log file parameters
	$self->{file}     = $param{-file};
	$self->{log_dir}  = $param{-log_dir};
	$self->{log_name} = $param{-name};
	$self->{date_fmt} = $param{-date_fmt};
	$self->{style}    = $param{-style} || 'none';

	# set up the maximum random session id
	$self->{rand_max} = $param{-rand_max} || 10_000;

	# set up tracked variables
	# Configuration variables - These are only recorded with calls to session()
	$self->{vars_config}      = $param{-vars_config} || {};
	$self->{vars_config}{ENV} = \%ENV;

	# runtime varibles - These are recorded with every log message
	$self->{vars} = $param{-vars} || {};

	if ($param{-catchwarn}) {
		$self->catch_warnings(1);
	}

	# check if we are starting a session or not
	if ($param{-nosession}) {
		$self->{session} = $param{-session_id};
	}
	else {
		$self->session($param{-session_id});
	}

	return $self;
}

sub info {
	my ($self, @params) = @_;

	return if !$self->is_info;

	if (!ref $params[0] || ref $params[0] ne 'HASH') {
		unshift @params, {};
	}

	$params[0]{-level} = 'info';

	return $self->record(@params);
}

sub message {
	my ($self, @params) = @_;

	return if !$self->is_message;

	if (!ref $params[0] || ref $params[0] ne 'HASH') {
		unshift @params, {};
	}

	$params[0]{-level} = 'message';

	return $self->record(@params);
}

sub debug {
	my ($self, @params) = @_;

	return if !$self->is_debug;

	if (!ref $params[0] || ref $params[0] ne 'HASH') {
		unshift @params, {};
	}

	$params[0]{-level} = 'debug';

	return $self->record(@params);
}

sub warn {
	my ($self, @params) = @_;

	return if !$self->is_warn;

	if (!ref $params[0] || ref $params[0] ne 'HASH') {
		unshift @params, {};
	}

	$params[0]{-level} = 'warn';

	return $self->record(@params);
}

sub error {
	my ($self, @params) = @_;

	return if !$self->is_error;

	if (!ref $params[0] || ref $params[0] ne 'HASH') {
		unshift @params, {};
	}

	$params[0]{-level} = 'error';

	my $ans = $self->record(@params);
	$self->flush;

	return $ans;
}

sub fatal {
	my ($self, @params) = @_;

	if (!ref $params[0] || ref $params[0] ne 'HASH') {
		unshift @params, {};
	}

	$params[0]{-level} = 'fatal';

	$self->record(@params);

	croak join ' ', @params[ 1 .. @params -1 ];

	return;
}

sub security {
	my ($self, @params) = @_;

	if (!ref $params[0] || ref $params[0] ne 'HASH') {
		unshift @params, {};
	}

	$params[0]{-level} = 'security';

	return $self->record(@params);
}

sub record {
	my ($self, $data, @message) = @_;
	my $dump = $self->{dump};

	# check that a session has been created
	$self->session($data->{-session_id}) if !$self->{session_id};

	my $level  = $data->{-level} || '(none)';
	delete $data->{-level};

	my $configs = $data->{-write_configs};
	delete $data->{-write_configs};

	my $param = {
		data => $data,
		vars => $self->{vars},
	};

	# add all the config variables to the variables to be logged
	if ($configs) {
		for my $var ( keys %{ $self->{vars_config} } ) {
			$param->{vars}{$var} = $self->{vars_config}{$var};
		}
	}

	# set up
	$param->{stack} = substr longmess, 0, 1_000;
	$param->{stack} =~ s/^\s+[^\n]*Log::Deep::[^\n]*\n//gxms;
	$param->{stack} =~ s/\A\s at [^\n]*\n\s+//gxms;
	$param->{stack} =~ s/\n[^\n]+\Z/\n.../xms;

	my @log = (
		strftime('%Y-%m-%d %H:%M:%S', localtime),
		$self->{session_id},
		$level,
		(join ' ', @message),
		$dump->Data($param)->Out(),
	);

	# make each part safe for outputting to one line
	for my $col (@log) {
		chomp $col;
		# quote all back slashes
		$col =~ s{\\}{\\\\}g;
		# quote all new lines
		$col =~ s/\n/\\n/g;
	}

	my $log = $self->log_handle();
	print {$log} join ',', @log;
	print {$log} "\n";

	$self->{log_session_count}++;

	return ;
}

sub log_handle {
	my $self = shift;

	if ( !$self->{handle} ) {
		$self->{log_dir}  ||= $ENV{TMP} || '/tmp';
		$self->{log_name} ||= (split m{/}, $0)[-1] || 'deep';
		$self->{date_fmt} ||= '%Y-%m-%d';
		$self->{log_date}   = strftime $self->{date_fmt}, localtime;

		my $file = $self->{file} || "$self->{log_dir}/$self->{log_name}_$self->{log_date}.log";

		# guarentee that there is a new line before we start writing
		my $missing = 0;
		if ( !$self->{reopening} && -s $file ) {
			open my $fh, '<', $file or die "Could not open the log file $file to check that it ends in a new line: $OS_ERROR\n";
			seek $fh, -20, SEEK_END;
			my $end = <$fh>;
			$missing = $end =~ /\n$/;
			close $fh;
		}

		open my $fh, '>>', $file or die "Could not open log file $file: $OS_ERROR\n";
		$self->{file}   = $file;
		$self->{handle} = $fh;

		if ($missing) {
			print {$fh} "\n";
		}
	}

	return $self->{handle};
}

sub session {
	my ($self, $session_id) = @_;

	if ( ! defined $session_id ) {
		return if defined $self->{log_session_count} && $self->{log_session_count} == 0;
	}

	# use the supplied session id or create a new session id
	$self->{session_id} = $session_id || int rand $self->{rand_max};

	$self->record({ -write_configs => 1 }, '"START"');

	$self->{log_session_count} = 0;

	return;
}

sub level {
	my ($self, @level) = @_;

	$self->{level} ||= { map { $_ => 0 } @LOG_LEVELS };

	# if not called with any parameters return the level hash
	return clone $self->{level} if !@level;

	# return log state if asked about that state
	return $self->{level}{$level[1]}     if $level[0] eq '-log';

	# Set a log state if requested
	return $self->{level}{$level[1]} = 1 if $level[0] eq '-set';

	# Unset a log state if requested
	return $self->{level}{$level[1]} = 0 if $level[0] eq '-unset';

	# if there is only one parameter that is a single digit set the all levels of that digit and higher
	if (@level == 1 && $level[0] =~ /^\d$/) {
		my $i = 0;
		for my $log_level (@LOG_LEVELS) {
			$self->{level}{$log_level} = $i++ >= $level[0] ? 1 : 0;
		}

		return clone $self->{level};
	}

	# if the is one parameter and it is a string turn on that level and highter
	if ( @level == 1 && any { $_ eq $level[0] } @LOG_LEVELS ) {

		# flag that we have found the starting level
		my $found = 0;

		for my $log_level (@LOG_LEVELS) {

			# flag that we have the start level
			$found = 1 if $log_level eq $level[0];

			# mark the current level appropriatly
			$self->{level}{$log_level} = $found ? 1 : 0;
		}

		return clone $self->{level};
	}

	# set all levels passed in as active levels.
	for my $level (@level) {
		$self->{level}{$level} = 1;
	}

	return clone $self->{level};
}

sub enable {
	my ($self, @levels) = @_;

	for my $level (@levels) {
		$self->{level}{$level} = 1;
	}
	return;
}

sub disable {
	my ($self, @levels) = @_;

	for my $level (@levels) {
		$self->{level}{$level} = 0;
	}

	return;
}

sub is_info     { return $_[0]->{level}{info}     }
sub is_message  { return $_[0]->{level}{message}  }
sub is_debug    { return $_[0]->{level}{debug}    }
sub is_warn     { return $_[0]->{level}{warn}     }
sub is_error    { return $_[0]->{level}{error}    }
sub is_fatal    { return $_[0]->{level}{fatal}    }
sub is_security { return 1                        }

sub file {
	my ($self) = @_;

	return $self->{file};
}

sub catch_warnings {
	my ($self, $action) = @_;

	if ( $action == 1 && !$self->{old_warn_handle} ) {
		# save old handle
		$self->{old_warn_handle} = $SIG{__WARN__};

		# install a redirect of all warnings to $self->warn
		$SIG{__WARN__} = sub {
			my $data = {};
			if ( ref $_[0] ) {
				# record the error reference for better display
				# using the error in the message just stringifys it
				$data->{ERROR_OBJ} = $_[0];
			}
			$self->warn( $data, $_[0] );
		}
	}
	elsif ( $action == 0 && $self->{old_warn_handle} ) {
		$SIG{__WARN__} = $self->{old_warn_handle};
		delete $self->{old_warn_handle};
	}

	return $self->{old_warn_handle} && 1;
}

sub flush {
	my ($self) = @_;

	return if ! exists $self->{handle};

	close $self->{handle};
	delete $self->{handle};
	$self->{reopening} = 1;

	return;
}

sub DESTROY {
	my ($self) = @_;

	if ($self->{handle}) {
		close $self->{handle};
	}

	return;
}

1;

__END__

=head1 NAME

Log::Deep - Deep Logging of information about a script state

=head1 VERSION

This documentation refers to Log::Deep version 0.3.5.


=head1 SYNOPSIS

   use Log::Deep;

   # create or append a log file with the current users name in the current
   # directory (if possible) else in the tmp directory. The session id will be
   # randomly generated.
   my $log = Log::Deep->new();

   $log->debug({-data => $object}, 'Message text');

=head1 DESCRIPTION

C<Log::Deep> creates a object for detailed logging of the state of the running
script.

=head2 Plugins

One of the aims of C<Log::Deep> is to be able to record deeper information
about the state of a running script. For example a CGI script (using CGI.pm)
has a CGI query object which stores its parameters and cookies, using the
CGI plugin this extra information is logged in the data section of the log
file.

Some plugins add data only when the a logging session starts, others will
add data every time a log message is written.

=head2 The Log File

C<Log::Deep> log file format looks something like

 iso-timestamp;session id;level;message;caller;data

All values are url encoded so that one log line will always represent one log
message, the line should be reasonably human readable except for the data
section which is a dump of all the deep details logged. A script C<deeper> is
provided with C<Log::Deeper> that allows for easier reading/searching of
C<Log::Deep> log files.

=head1 SUBROUTINES/METHODS

=head3 C<new ( %args )>

Arg: B<-level> - array ref | string - If an array ref turns on all levels
specified, if a string turns on that level and higher

Arg: B<-file> - string - The name of the log file to write to

Arg: B<-log_dir> - string - The name of the directory that the log file is
written to.

Arg: B<-name> - string - The name of the file in -log_dir

Arg: B<-date_fmt> - string - The date format to use for appending to log
file -names

Arg: B<-style> -  -

Arg: B<-rand_max> -  -

Arg: B<-session_id> - string - A specific session id to use.

Return: Log::Deep - A new Log::Deep object

Description: This creates a new log object.

=head3 C<info ( $var )>

Param: C<$> - type -

Return:  -

Description:

=head3 C<message ( $var )>

Param: C<$> - type -

Return:  -

Description:

=head3 C<debug ( $var )>

Param: C<$> - type -

Return:  -

Description:

=head3 C<warn ( $var )>

Param: C<$> - type -

Return:  -

Description:

=head3 C<error ( $var )>

Param: C<$> - type -

Return:  -

Description:

=head3 C<fatal ( $var )>

Param: C<$> - type -

Return:  -

Description:

=head3 C<security ( $var )>

Param: C<$> - type -

Return:  -

Description:

=head3 C<record ( $var )>

Param: C<$> - type -

Return:  -

Description:

=head3 C<log_handle ( $var )>

Param: C<$> - type -

Return:  -

Description:

=head3 C<session ( $var )>

Param: C<$> - type -

Return:  -

Description:

=head3 C<level ( $var )>

Param: C<$> - type -

Return:  -

Description:

=head3 C<enable (@levels)>

Param: C<@levels> - strings - The names of levels to enable

Description: Enables the supplied levels

=head3 C<disable (@levels)>

Param: C<@levels> - strings - The names of levels to disable

Description: Disables the supplied levels

=head3 C<is_info  ()>

Return: bool - True if the info log level is enabled

Description:

=head3 C<is_message  ()>

Return: bool - True if the message log level is enabled

Description:

=head3 C<is_debug ()>

Return: bool - True if the debug log level is enabled

Description:

=head3 C<is_warn  ()>

Return: bool - True if the warn log level is enabled

Description:

=head3 C<is_error ()>

Return: bool - True if the error log level is enabled

Description:

=head3 C<is_fatal ()>

Return: bool - True if the fatal log level is enabled

Description:

=head3 C<is_security ()>

Return: bool - True if the security log level is enabled

Description:

=head3 C<file ( $var )>

Return: string - The file name of the currently being written to log file

Description: Gets the file name of the current log file

=head3 C<catch_warnings ( $action )>

Param: C<$action> - 1 | 0 | undef - Set catch warnings (1), unset catch warnings (0) or report state (undef)

Return: bool - True if currently catching warnings, false if not

Description: Turns on/off catching warnings and/or returns the current warn catching state.

=head3 C<flush ()>

Description: Calls IO::Handle's flush on the log file handle

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
