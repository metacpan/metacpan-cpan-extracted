#!/usr/bin/perl
package LaBrea::NetIO;
use strict;
#use diagnostics;
use vars qw($VERSION @ISA @EXPORT_OK );

$VERSION = do { my @r = (q$Revision: 0.01 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

use Socket;
use AutoLoader 'AUTOLOAD';
require Exporter;
@ISA = qw(Exporter);

@EXPORT_OK = (@Socket::EXPORT, @Socket::EXPORT_OK, qw(
	TARPIT_PORT
	open_listen_sock
	open_tcp
	alarm_wrap
	daemon_handler
	read_daemon
	fetch
	reap_kids
	set_so_linger
));

# autoload declarations

sub open_listen_sock;
sub open_tcp;
sub alarm_wrap;
sub daemon_handler;
sub fetch;
sub read_daemon;
sub reap_kids;
sub set_so_linger;
sub TARPIT_PORT { 8686; };
#
sub _fetch;
sub _want_daemon;
sub DESTROY {};

1;
__END__

=head1 NAME

  LaBrea::Tarpit::NetIO

=head1 SYNOPSIS

  use LaBrea::Tarpit::NetIO qw (
	TARPIT_PORT
	open_listen_sock
	open_tcp
	alarm_wrap
	daemon_handler
	read_daemon
	fetch
	reap_kids
	set_so_linger
    [plus any Socket.pm variable]
  );

  $error=open_listen_sock(HANDLE,address,port);
  $error=open_tcp(*S,$host,$port);
  *rv = alarm_wrap($timeout,$subref,@args);
  $subref=daemon_handler(*HANDLE,$target);
  read_daemon($subref,\@response);
  $err=fetch($target,\@response,$command);
  $alive = reap_kids(\%kids);
  $rv = set_so_linger(*HANDLE,$seconds);

=head1 DESCRIPTION

B<NetIO> contains TCP client and server modules used by Tarpit modules.

B<NetIO> has available for EXPORT, any variable from the standard Socket.pm
module.

=over 4

=item $error=open_listen_sock(HANDLE,address,port);

Opens a server listening socket on HANDLE

  input:	HANDLE,
		address,  name or ip
			defaults to all 
			interfaces if false 
		port	  defaults to 8686

  returns:	false on success
		or error message

=cut

sub open_listen_sock {
  my ($S,$host,$port) = @_;
# default connection is to ANY interface
  my $iaddr = INADDR_ANY;
  return 'interface address not found'
	if $host && ! ($iaddr = inet_aton($host));
  my $proto = getprotobyname('tcp');
  $port = TARPIT_PORT unless $port && $port !~ /[\D]/;

  return 'failed to create socket'
	unless socket($S,PF_INET,SOCK_STREAM,$proto);

  unless (setsockopt($S,SOL_SOCKET,SO_REUSEADDR,1)) {
    close $S;
    return 'failed to set socket options';
  }

  unless (bind($S,sockaddr_in($port,$iaddr))) {
    close $S;
    return 'failed to bind socket';
  }
  unless (listen($S,SOMAXCONN)) {
    close $S;
    return "failed to set listen queue";
  }
  $_ = select $S;
  $| = 1;
  select $_;
  return undef;
}

=item $error=open_tcp(*S,$host,$port);

Open a tcp connection on port to host.

  input:	*S,hostname, port
  returns:	false on success
		error message on failure

=cut

sub open_tcp {
  my ($S,$host,$port) = @_;
  my $iaddr;
  return 'port is not numeric'
	if !$port || $port =~ /\D/;
  return 'hostname not found'
	unless ($iaddr = inet_aton($host));
  my $proto = getprotobyname('tcp');
  return 'unable to open socket'
	unless socket($S, PF_INET, SOCK_STREAM, $proto );
  my $paddr = sockaddr_in($port, $iaddr);
  unless (connect($S, $paddr)) {
    close $S;
    return 'could not connect to host';
  }
  $host = select $S;	# temp save old selection
  $| = 1;
  select $host;		# restore selection
  return undef;
}

=item $rv = alarm_wrap($timeout,$subref,@args);

Provides an alarm wrapper for subroutines that may time out or B<die>.

  input:	timeout,
		$subref,
		arguments for $subref

  returns:	$subref return value(s)
		  on error
		undef or () on error
	$@ is set with error value
	which will contain the string
	'alarm_wrap timeout' if
	the fault was timeout only

	timeout is ignored if false

=cut

sub alarm_wrap {
  my ($timeout,$subref,@args) = @_;
  local $SIG{ALRM} = sub { die 'alarm_wrap timeout' };
  my @rv;
  alarm $timeout if $timeout;
  eval { @rv = &$subref(@args) };
  alarm 0;
  @rv = () if $@;
  return (wantarray) ? @rv : "@rv";
}

=item $subref=daemon_handler(*HANDLE,$target);

Opens a handle *HANDLE pointing to the Tarpit daemon, pipe or file
and returns a CODEREF to a subroutine that will read full
lines of data from the HANDLE. Do not try to read the handle directly.

  input:   *HANDLE
	   file name/path
	    or
	   hash	->{d_host} [optional]
	  	->{d_port} [optional]

If B<target> is a HASH and d_host and/or d_port are not specified,
they default to localhost:8686

  returns: subref or undef on open fail

  usage:  $present = daemon_handler(*H,$t);
	  while ( $data = &$present ) {
	    do something with $data;
	  }
	  close H;

=cut

sub daemon_handler {
  my ($S,$target) = @_;
  if ( &_want_daemon(\$target) ) {
    my $d_port = $target->{d_port} || TARPIT_PORT;
    my $d_host = $target->{d_host} || 'localhost';
    return undef if open_tcp($S,$d_host,$d_port);
    return sub { readline($S) };
  } else {
    return undef unless open($S,$target);
    return sub { return scalar <$S> };
  }
  return undef;
}

# input:	pointer to target
# returns:	true if daemon
#		false if file
#		target is modified in place
#		to point to file if HASH->{file}
#
sub _want_daemon {
  my ($tgp) = @_;
  return undef unless $tgp;
  return undef unless ref $$tgp eq 'HASH';
  if ( exists ${$tgp}->{file} ) {
    $$tgp = ${$tgp}->{file};		# replace with file name
    return undef;
  }
  1;
}

=item read_daemon($subref,\@response);

B<read_daemon> retrieves the response text from a 
file or daemon and places the lines in array.

  input:	$subref to execute
		pointer to @response

  returns:	number of lines
		fills @response

  Note:	use 'alarm_wrap' with this routine

=cut

sub read_daemon {
  my ($subref,$ary) = @_;
  while ($_ = &$subref) {
    push @$ary, $_;		# recover report from daemon
  }
  $ary = @$ary;			# return number of lines
}

=item $error=fetch($target,\@response,$command);

B<fetch> a response from B<target> using B<args>. Essentially a combination
of B<daemon_handler> and B<read_daemon> wrapped with B<alarm_wrap>.
Retrieves data from the host or file specified by B<target>. The B<args>
argument is ignored if B<target> is a file.

  input:  target, # hash->{host} [optional]
		  # hash->{port} [optional]
		  # hash->{d_timeout} [optional]
	  \@response,	# result lines
	  command,		# what to tell host

  returns:	error if fail
		false on success

=cut

sub fetch {
  my ($target,$ary,$command) = @_;
  local *DAEMON;
  my $subref = daemon_handler(*DAEMON,$target);
  return "failed to open target" unless $subref;
  my $timeout = (&_want_daemon(\$target) && $target->{d_timeout})
	? $target->{d_timeout}
	: 180;
  alarm_wrap($timeout,\&_fetch,*DAEMON,$target,$subref,$ary,$command);
  close DAEMON;
  return $@;
}

sub _fetch {
  my ($DAEMON,$target,$subref,$ary,$command) = @_;
  print $DAEMON $command,"\n"
	if $command && &_want_daemon(\$target);
  read_daemon($subref,$ary);
}

=item $alive = reap_kids(\%kids);

Non-blocking reaper for PID's in (keys %kids). Deletes zombie children from
%kids and returns the number of kids remaining.

  input:	\%kids	# hash of child PID's
  returns:	number of kids remaining

=cut

sub reap_kids {
  my ($kp) = @_;
  return 0 unless (@_ = keys %$kp);
  require POSIX;
  $_ = &POSIX::WNOHANG;
  foreach my $pid (@_) {
    delete $kp->{$pid} if waitpid($pid,$_);
  }
  return scalar keys %$kp;
}

=item $rv = set_so_linger(*HANDLE,$seconds);

  Set SO_LINGER on top level socket

  input:	*HANDLE, seconds
  returns:	true = success, false = fail

=back

=cut

sub set_so_linger {
  my ($FH,$sec) = @_;
  setsockopt($FH,SOL_SOCKET,SO_LINGER,pack("ll",1,$sec));
}

=head1 EXPORT_OK

	TARPIT_PORT
	open_listen_sock
	open_tcp
	alarm_wrap
	daemon_handler
	read_daemon
	fetch
	reap_kids
	set_so_linger
    [plus any Socket.pm variable]

=head1 COPYRIGHT

Copyright 2002, Michael Robinton & BizSystems
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or 
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of 
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the  
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

=head1 AUTHOR

Michael Robinton, michael@bizsystems.com

=head1 SEE ALSO

perl(1), Socket(3), LaBrea::Tarpit(3), LaBrea::Tarpit::Get(3), LaBrea::Tarpit::Report(3),
LaBrea::Tarpit::Util(3), LaBrea::Tarpit::DShield(3), LaBrea::Tarpit::Codes(3)

=cut

1;
