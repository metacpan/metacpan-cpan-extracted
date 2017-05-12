=pod

=begin classdoc

Interface specification for an apartment threaded Logger component. Opens the logfile.
Accepts log messages, prefixes them with
timestamps, and writes them to the logfile. Also inspects the size and
lifetime of the current logfile at regular intervals; when either size or
lifetime exceeds the defined maximums (or at the direction of an external
control command), closes and renames the current logfile, and then opens
a new logfile.
<p>
Classes which use a Logger object should inherit the HTTP::Daemon::Threaded::Logable
class. While this class provides a default implementation, applications should
implement their own subclasses, and create instances to be passed to HTTP::Daemon::Threaded
as either the EventLogger and/or WebLogger parameters.
<p>
Copyright&copy 2006-2008, Dean Arnold, Presicient Corp., USA<br>
All rights reserved.
<p>
Licensed under the Academic Free License version 3.0, as specified at
<a href='http://www.opensource.org/licenses/afl-3.0.php'>OpenSource.org</a>.

@author D. Arnold
@since 2005-08-21
@self	$self



=end classdoc

=cut
package HTTP::Daemon::Threaded::Logger;

use Thread::Apartment::Server;
use Time::Local;

use base qw(Thread::Apartment::Server);

use strict;
use warnings;

our $VERSION = '0.91';

=pod

=begin classdoc

Constructor. Opens the logfile. If the logfile is too old or big,
it is truncated (i.e., closed, and renamed with the current timestamp
as its suffix, and a new file is created). An initial startup log
message is written.

@param AptTimeout		maximum Thread::Apartment proxy method call timeout
@param Path			pathname of logfile
@param MaxSize		maximum size of logfile, in megabytes
@param Lifetime		maximum lifetime of logfile, in hours

@return		HTTP::Daemon::Threaded::Logger object


=end classdoc

=cut
sub new {
	my ($class, %args) = @_;
#
#	make sure we can open the logfile
#
	my $self = { %args };
	bless $self, $class;
	$self->set_client(delete $self->{AptTAC})
		if $self->{AptTAC};

	my $logfd;
	$@ = "Can't open logfile: $!",
	return undef
		unless open($logfd, ">>$self->{Path}");

	my $old_fh = select($logfd);
	$| = 1;
	select($old_fh);
	$self->{_fd} = $logfd;
#
#	get current logfile size and last modify time
#	if bigger than maxsize, or older than lifetime, truncate it
#
	my @logstats = stat $logfd;

	$self->{_logsize} = $logstats[7];
	$self->{_logtime} = $logstats[9];
	$self->truncate()
		if (($args{MaxSize} && ($self->{_logsize} > $args{MaxSize})) ||
			($args{Lifetime} && ((time() - $self->{_logtime}) > $args{Lifetime})));

	$self->log("**************************************");
	$self->log('Logger: HTTP::Daemon::Threaded started.');

	return $self;
}
=pod

=begin classdoc

Overrides Thread::Apartment::Server::get_simplex_methods()

@return		hashref of simplex method names


=end classdoc

=cut
sub get_simplex_methods {
	return {
		'log' => 1,
		'close' => 1,
		'truncate' => 1,
		'handleExpiration' => 1,
		'updateLifetime' => 1,
		'updateMaxSize' => 1
	};
}

=pod

=begin classdoc

Append a log message to the logfile. The current timestamp
is prepended to the message before it is logged.

@simplex
@param $msg	log message text

@return		none


=end classdoc

=cut
sub log {
	my ($self, $msg) = @_;

	my $fd = $self->{_fd};
	return undef
		unless $fd;
	$msg = scalar localtime() . ": $msg\n";
	$self->{_logsize} += length($msg);
	print $fd $msg;
	return $self;
}

=pod

=begin classdoc

Close the logfile.

@simplex
@return		none


=end classdoc

=cut
sub close {
	my $self = shift;
	my $fd = delete $self->{_fd};
	close($fd)
		if $fd;

	return $self;
}

=pod

=begin classdoc

Truncate the logfile. Close the current file, rename it
with the current timestamp appended to its name, and create
a new logfile. Writes an introductory message to the log.

@simplex
@param $newpath	optional new logfile path

@return		none


=end classdoc

=cut
sub truncate {
	my ($self, $newpath) = @_;
#
#	close existing file
#	rename it with timestamp
#	open new file
#	reset size/time
#
	$newpath = $self->{Path}
		unless $newpath;

	my $fd = delete $self->{_fd};
	CORE::close($fd)
		if $fd;

	my @ts = split(/\s+/, scalar localtime());
	$ts[3]=~tr/:/_/;
	my $sfx = join('', '.', $ts[4], $ts[1], $ts[2], '_', $ts[3]);
	print STDERR "HTTP::Daemon::Threaded::Logger::truncate: Can't rename logfile: $!" and
	return undef
		unless rename $self->{Path}, $self->{Path} . $sfx;

	$self->{_logsize} = 0;
	$self->{_logtime} = time();

	print STDERR "HTTP::Daemon::Threaded::Logger::truncate: Can't open logfile: $!" and
	return undef
		unless open($fd, ">$newpath");

	my $old_fh = select($fd);
	$| = 1;
	select($old_fh);
	$self->{_fd} = $fd;

	$self->log("**************************************");
	$self->log('Logger: Logfile truncated.');
}
=pod

=begin classdoc

Update logfile lifetime. Called from WebClient.

@simplex
@param $lifetime	lifetime in hours.

@return		none


=end classdoc

=cut
sub updateLifetime {
	$_[0]->{Lifetime} = $_[1];
}
=pod

=begin classdoc

Update logfile maximum size. Called from WebClient.

@simplex
@param $maxsize	Maximum size in megabytes.

@return		none


=end classdoc

=cut
sub updateMaxSize {
	$_[0]->{MaxSize} = $_[1];
}
=pod

=begin classdoc

Update logfile name. Called from WebClient.
Truncates the existing logfile.

@simplex
@param $path	new logfile name

@return		none


=end classdoc

=cut
sub updatePath {
	my ($self, $newpath) = @_;

	$self->truncate($newpath);
	$self->{Path} = $newpath;
}

1;
