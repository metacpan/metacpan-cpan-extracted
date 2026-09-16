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

package Fugu::Curl;
our $VERSION = '0.5.1';

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);

use File::Basename qw(basename dirname);
use Fugu::Process;

# Fugu::Curl - download one URL to one file, through curl, wget, or
# the ftp(1) of OpenBSD.
#
# Core Perl fetches no HTTPS URL. HTTP::Tiny is core, but its TLS
# needs IO::Socket::SSL, which is not. Every host holds one of three
# commands instead, and each command carries the TLS stack of the
# host. The module picks the first command that the host has, in the
# order curl, wget, ftp. It runs the command through
# Fugu::Process->run, with an argument list and never a shell.
#
# The three commands need three flag sets for the same four demands:
# follow a redirect, fail on an HTTP status of 400 or above, write to
# a named file, and stop after a time limit. The module holds one
# classification over the three dialects, so every caller reads one
# status set.
#
# A failed fetch leaves no file. The command writes to a temporary
# name in the destination directory, and the module renames that file
# on success. A reader of the destination therefore sees the old file
# or the new file, and never a partial one.
#
# The module gives the child no environment of its own, so
# http_proxy, https_proxy, ftp_proxy, and no_proxy reach the command.
# A host behind a proxy reaches a release through them.
#
# Every recoverable failure returns undef, and error holds the
# reason. The module never logs: the caller decides what to report.

# The commands, in the order of the search. curl comes first: it
# reports the HTTP status directly, and it fails on an HTTP error.
use constant COMMANDS => qw(curl wget ftp);

# The whole-fetch bound, in seconds. A release asset on a slow link
# needs minutes, and a stalled connection must not hold a bootstrap
# forever.
use constant DEFAULT_TIMEOUT => 600;

# The seconds that the process bound holds above the command flag.
# The command flag therefore fires first, and the process bound
# catches a command that ignores its own flag.
use constant PROCESS_MARGIN => 30;

# The exit code of a curl(1) timeout. The other exit codes of curl
# tell little: a 404 through a redirect exits 56, and the manual
# names 22.
use constant CURL_TIMEOUT_EXIT => 28;

# The pattern that reads the HTTP status out of the report of each
# command. curl writes the status alone on standard output, through
# --write-out. wget and ftp name the status in their diagnostic on
# standard error. The first digit runs from 1 to 9, because curl
# writes 000 for a transfer that reached no response at all.
my %STATUS_PATTERN = (
	curl => qr/\A([1-9]\d\d)\z/,
	wget => qr/\bERROR\s+([1-9]\d\d)\b/,
	ftp  => qr/\bError retrieving file:\s*([1-9]\d\d)\b/,
);

# Fugu::Curl->new(%args):
#	Build a downloader. The method resolves the command once, and
#	it runs no process.
#
#	%args:
#		command => $command # Optional: a plain name, or a path
#		timeout => $seconds # Optional: the whole-fetch bound
#
#	The method resolves the command through
#	Fugu::Process->find_command, and the module holds no resolver
#	of its own. Without command the method walks $ENV{PATH} over
#	the search list: curl, then wget, then ftp. The default
#	timeout is DEFAULT_TIMEOUT.
#
#	The method must not die for an absent command. It sets error
#	instead, and is_available then returns 0.
sub new ( $class, %args )
{
	my $self = bless {
		command       => undef,
		command_error => undef,
		dialect       => undef,
		timeout       => $args{timeout} // DEFAULT_TIMEOUT,
		status        => undef,
		code          => undef,
		error         => undef,
	}, $class;

	my $command = Fugu::Process->find_command( $args{command}, COMMANDS );
	my $dialect = defined $command ? _dialect($command) : undef;

	if ( defined $dialect ) {
		$self->{command} = $command;
		$self->{dialect} = $dialect;
	}
	elsif ( defined $command ) {

		# The file runs, but its name names no dialect, and
		# the module holds a flag set for each dialect only.
		$self->{command_error} = "not a known downloader: $command";
	}
	else {
		my $named = $args{command} // join ', ', COMMANDS;
		$self->{command_error} = "no executable command: $named";
	}

	$self->{error} = $self->{command_error};

	return $self;
}

# $self->is_available:
#	Report if the object resolved a command that it can drive.
#	The method returns 1 or 0. It runs no process, and it never
#	dies.
sub is_available ($self)
{
	return defined $self->{command} ? 1 : 0;
}

# $self->command:
#	The resolved command path, or undef. An operator who installed
#	no downloader needs this answer in a diagnostic.
sub command ($self)
{
	return $self->{command};
}

# $self->status:
#	The status of the most recent fetch: ok, http, network,
#	timeout, or absent. The method returns undef before the first
#	fetch.
sub status ($self)
{
	return $self->{status};
}

# $self->code:
#	The HTTP status of the most recent fetch, where the command
#	reported one, and undef otherwise. A caller that probes for an
#	optional file reads 404 as the normal answer.
sub code ($self)
{
	return $self->{code};
}

# $self->error:
#	The reason of the most recent failure, or undef after a
#	success.
sub error ($self)
{
	return $self->{error};
}

# $self->fetch($url, $path):
#	Download the URL to the path. The method returns 1 on
#	success, and undef on every failure. After the call, status
#	holds the outcome, code holds the HTTP status where the
#	command reported one, and error holds the reason of a
#	failure.
#
#	The command writes to a temporary name in the directory of
#	$path, so the rename that publishes the file stays inside one
#	filesystem. A failure removes that temporary file.
sub fetch ( $self, $url, $path )
{
	$self->{status} = undef;
	$self->{code}   = undef;
	$self->{error}  = undef;

	return $self->_fail( 'absent', $url, $self->{command_error} )
	    unless defined $self->{command};

	my $tmp    = _temp_name($path);
	my $result = Fugu::Process->run(
		cmd     => $self->arguments( $url, $tmp ),
		timeout => $self->{timeout} + PROCESS_MARGIN,
	);

	$self->_classify( $result, $url );
	unless ( $self->{status} eq 'ok' ) {
		unlink $tmp;
		return;
	}

	unless ( rename $tmp, $path ) {

		# The bytes arrived, and the destination did not take
		# them. The status set holds no name for a local
		# failure, so it takes the network status, and the
		# reason names the rename.
		my $reason = "cannot rename $tmp to $path: $!";
		unlink $tmp;
		return $self->_fail( 'network', $url, $reason );
	}

	return 1;
}

# $self->arguments($url, $tmp):
#	The argument list that fetch runs for the resolved command,
#	as an array reference, or undef when no command resolved. The
#	method runs no process.
#
#	Each list holds the four demands of a fetch in the dialect of
#	its command: follow a redirect, fail on an HTTP status of 400
#	or above, write to $tmp, and stop after the timeout. wget and
#	the ftp of OpenBSD follow a redirect and fail on an HTTP
#	error by themselves, so their lists name neither.
#
#	No list holds a flag that turns the TLS check off. Each
#	command verifies the certificate of the peer by default.
sub arguments ( $self, $url, $tmp )
{
	my $dialect = $self->{dialect};
	return unless defined $dialect;

	my $command = $self->{command};
	my $timeout = $self->{timeout};

	# --write-out prints the HTTP status on standard output, and
	# --fail keeps that report. The body goes to $tmp, so the two
	# streams never mix.
	return [
		$command,       '--fail',      '--location',   '--silent',
		'--show-error', '--max-time',  $timeout,       '--output',
		$tmp,           '--write-out', '%{http_code}', $url,
	    ]
	    if $dialect eq 'curl';

	# --no-verbose drops the progress meter and keeps the error
	# line. --tries=1 holds the retry policy out of the module.
	return [
		$command,                 '--no-verbose',
		'--tries=1',              "--timeout=$timeout",
		"--output-document=$tmp", $url,
	    ]
	    if $dialect eq 'wget';

	# The ftp(1) of OpenBSD. -V drops the progress meter, and -w
	# bounds the connection.
	return [ $command, '-V', '-M', '-w', $timeout, '-o', $tmp, $url ];
}

# $self->_classify($result, $url):
#	Read one Fugu::Process result into the status, the code and
#	the error of the object. Three commands report a failure in
#	three ways, and this method is the one place that maps them
#	onto one status set.
sub _classify ( $self, $result, $url )
{
	# A run that never reached the child means that the command
	# never ran. That is an install problem, and not a transfer
	# failure.
	return $self->_fail( 'absent', $url, $result->{error} )
	    if defined $result->{error};

	my $code = _http_code( $self->{dialect}, $result );
	$self->{code} = $code;

	my $diagnostic = _last_line( $result->{stderr} );

	# The HTTP status leads. A command that exits zero on a status
	# of 400 or above still fails here, so the module fails
	# closed.
	if ( defined $code && $code >= 400 ) {
		my $reason = "HTTP $code";
		$reason .= ": $diagnostic" if length $diagnostic;
		return $self->_fail( 'http', $url, $reason );
	}

	if ( $result->{success} ) {
		$self->{status} = 'ok';
		return;
	}

	# The process bound fired, or curl reported a timeout of its
	# own. wget and the ftp of OpenBSD report no timeout of their
	# own, so a stall there takes the network status.
	if (
		$result->{timed_out}
		|| (       $self->{dialect} eq 'curl'
			&& $result->{exit_code} == CURL_TIMEOUT_EXIT ) )
	{
		return $self->_fail( 'timeout', $url,
			"timeout after $self->{timeout} seconds" );
	}

	$diagnostic = "exit code $result->{exit_code}"
	    unless length $diagnostic;

	return $self->_fail( 'network', $url, $diagnostic );
}

# $self->_fail($status, $url, $reason):
#	Hold the status and the reason of a failed fetch, and return
#	undef. Every message names the command, the URL and the
#	reason, in that order, so one line of a log holds the whole
#	answer.
sub _fail ( $self, $status, $url, $reason )
{
	my $name = $self->{dialect} // 'downloader';

	$self->{status} = $status;
	$self->{error}  = "$name: $url: $reason";

	return;
}

# _dialect($path):
#	The dialect of a resolved command: its base name, when that
#	name is one of the search list, and undef otherwise. The
#	module holds one flag set for each dialect, so a command
#	under another name has no flag set here. A stub under the
#	name of a command therefore drives the dialect of that
#	command, which a test needs on a host that has one of the
#	three.
sub _dialect ($path)
{
	my $name = basename($path);

	for my $known (COMMANDS) {
		return $known if $name eq $known;
	}

	return;
}

# _http_code($dialect, $result):
#	The HTTP status that the command reported, or undef. curl
#	reports it on standard output, and the other two name it in
#	their diagnostic on standard error.
sub _http_code ( $dialect, $result )
{
	my $text = $dialect eq 'curl' ? $result->{stdout} : $result->{stderr};
	return unless defined $text;

	$text =~ s/\A\s+//;
	$text =~ s/\s+\z//;

	my ($code) = $text =~ $STATUS_PATTERN{$dialect};

	return $code;
}

# _last_line($text):
#	The last line of a diagnostic that holds something, or the
#	empty string. curl writes one line. wget names the URL first
#	and the reason second, so the last line carries the reason
#	for every command.
sub _last_line ($text)
{
	my @lines;
	for my $line ( split /\n/, $text // '' ) {
		$line =~ s/\A\s+//;
		$line =~ s/\s+\z//;
		push @lines, $line if length $line;
	}

	return @lines ? $lines[-1] : '';
}

# _temp_name($path):
#	A sibling name for the file under download. The rename that
#	publishes it must stay inside one filesystem, so the name
#	lives in the directory of the destination. The name starts
#	with a dot, so a directory listing of a cache shows the
#	published files only.
sub _temp_name ($path)
{
	my $dir  = dirname($path);
	my $base = basename($path);

	for my $temp ( map { "$dir/.$base.$$.$_" } 1 .. 10 ) {
		return $temp unless -e $temp;
	}

	return "$dir/.$base.$$";
}

1;
