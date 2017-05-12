=pod

=begin classdoc


Abstract base logger class for component classes.
Provides an interface to the Event and Web Logger components which
responds to the current LogLevel of the component.
If the EventLogger component is not defined, then messages
are logged to STDERR. If the WebLogger component is not defined,
the messages are silently discarded.
<p>
Copyright&copy 2006-2008, Dean Arnold, Presicient Corp., USA<br>
All rights reserved.
<p>
Licensed under the Academic Free License version 3.0, as specified at
<a href='http://www.opensource.org/licenses/afl-3.0.php'>OpenSource.org</a>.

@author D. Arnold
@since 2006-08-21
@self	$self



=end classdoc

=cut
package HTTP::Daemon::Threaded::Logable;

use strict;
use warnings;

our $VERSION = '0.91';
=pod

=begin classdoc

Log an error message. Prefix the message with the
error tag and the type of the object reporting the error

@param $msg	error message text

@return		undef


=end classdoc

=cut
sub logError {
	my ($self, $msg) = @_;

	$self->{EventLogger}->log(join('', '[ERROR]: [', ref $self, '] ', $msg, "\n")),
	return undef
		if $self->{EventLogger};

	print STDERR  join('', '[ERROR]: [', ref $self, '] ', $msg), "\n";
	return undef;
}
=pod

=begin classdoc

Log a warning message. Prefix the message with the
warning tag and the type of the object reporting the error.
Warnings are only logged when the object's loglevel > 1

@param $msg	warning message text

@return		this object


=end classdoc

=cut
sub logWarning {
	my ($self, $msg) = @_;

	return $self
		unless ($self->{LogLevel} > 1);

	$self->{EventLogger}->log(join('', '[WARNING]: [', ref $self, '] ', $msg, "\n")),
	return $self
		if $self->{EventLogger};

	print STDERR  join('', '[WARNING]: [', ref $self, '] ', $msg), "\n";
	return $self;
}
=pod

=begin classdoc

Log an informational message. Prefix the message with the
information tag and the type of the object reporting the error.
Informational logs are only applied when the object's loglevel > 2,
or greater than the specified minimum loglevel

@param $msg	information message text
@param $level	optional minimum log level at which to log the text

@return		$self


=end classdoc

=cut
sub logInfo {
	my ($self, $msg, $level) = @_;

	$level = 2 unless defined($level);

	return $self
		unless ($self->{LogLevel} > $level);

	$self->{EventLogger}->log(join('', 'Info: [', ref $self, '] ', $msg, "\n")),
	return $self
		if $self->{EventLogger};

	print STDERR  join('', 'Info: [', ref $self, '] ', $msg), "\n";
	return $self;
}
=pod

=begin classdoc

Log detail message timing traces. Only logs when the
diagnostic message timing is enabled. No prefixes
are required.

@param $msg	the message timing text

@return		the object


=end classdoc

=cut
sub logTiming {
	print STDERR $_[1], "\n"
		if $_[0]->{Stats}{Debug}{Timing} || $_[0]->{_diag_time};
	return $_[0];
}

sub _formatted_log_time {
#
# format: [DD/Mmm/YYYY:HH:MM:SS -UUUU]
#	for now we use gmtime, since we don't have a handy
#	UTC delta method
#
	my $dt = gmtime();
	my @t = split(/\s+/, $dt);
	return "[$t[2]/$t[1]/$t[4]:$t[3] +0000]";
}

=pod

=begin classdoc

Collect web request log info. The HTTP request line, user authorization, referer,
and user agent are collected for later logging purposes. The collected information
is stored in this Logable object for later use when the response is eventually
sent back to the client. Note that this step is required
in order to avoid altering the standard HTTP::Daemon::ClientConn send_XXX()
interfaces overridden by HTTP::Daemon::Threaded::Socket to provide automatic web logging
capability. Only performed if a WebLogger is configured.

@param $request	an HTTP::Request object

@return this Logable object


=end classdoc

=cut
sub scanForLogging {
	my ($self, $request) = @_;

	return undef unless $self->{WebLogger};

	my $basic = '"' . join(' ', $request->method(), $request->uri(), $request->protocol()) . '"';
	my ($userid, $pass) = $request->authorization_basic();
	$userid = '-'
		unless $userid;

	my $refer = $request->referer || '-';
	$refer = '"' . $refer . '"'
		unless ($refer eq '-');

	my $useragent = $request->user_agent || '-';
	$useragent = '"' . $useragent . '"'
		unless ($useragent eq '-');

	$self->{_log_fragments} = [ "- $userid", $basic, "$refer $useragent" ];
	return $self;
}

=pod

=begin classdoc

Log a web request. The previously stored HTTP request log fragments
are combined with the client IP address, response timestamp, response status, and
response size. The output format is the Apache Combined Log format.

@param $addr	client IP address
@param $status response HTTP status code
@param $size	response size in bytes

@return this object
@see <a href='http://httpd.apache.org/docs/1.3/logs.html#common'>Apache Combined Log format</a>


=end classdoc

=cut
sub logRequest {
	my ($self, $addr, $status, $size) = @_;

	return $self unless $self->{WebLogger};
#
#	fields are (separated by a single space):
#	client IP address,
#	clientid (always '-'),
#	HTTP Authent userid (if any, otherwise, '-'),
#	[end-of-request timestamp as (Day/Month/Year:HH:MM:SS UTC offset)]
#	"basic request header (including method)"
#	response status code
#	resp size ("-" if no resp)
#	"Referer"
#	"UserAgent"
#
	my $msg = join(' ',
		$addr,
		$self->{_log_fragments}[0],
		_formatted_log_time(),
		$self->{_log_fragments}[1],
		$status,
		$size || '-',
		$self->{_log_fragments}[2]);

	$self->{WebLogger}->log($msg),
	return $self;
}

=pod

=begin classdoc

Updates the current log level

@param $level		new log level

@return		new log level


=end classdoc

=cut
sub setLogLevel { $_[0]->{LogLevel} = $_[1]; }

=pod

=begin classdoc

Returns the current log level

@return		log level


=end classdoc

=cut
sub getLogLevel { return $_[0]->{LogLevel}; }

1;
