#!/usr/bin/perl
package Mail::SMTP::Honeypot;

# Notes to curious readers:
#
# This module was cobbled together in a couple of days out of another
# project that is neatly partitioned into pieces that have a good
# organization. Everything from there was pretty much dumped in this one
# file. Sorry 'bout that ;-)
#
# I was a lot more interested in having it work quickly than making it neat.
#
#	Michael
#
use strict;
#use diagnostics;
#use lib qw(blib lib);

use Data::Dumper;
use Net::DNS::Codes qw(
	T_PTR
	C_IN
	BITS_QUERY
	RD
	NS_PACKETSZ
	HFIXEDSZ
	QUERY
	NOERROR
	NXDOMAIN
	SERVFAIL
);
use Net::NBsocket qw(
	open_udpNB
	open_listenNB
	accept_NB
	inet_aton
	inet_ntoa
	sockaddr_in
	set_so_linger
);
use Net::DNS::ToolKit qw(
	gethead
	newhead
	get_ns
);
#use Net::DNS::ToolKit::Debug qw(
#	print_head
#	print_buf
#);
use Net::DNS::ToolKit::RR;
use POSIX qw(
	EINTR
	EWOULDBLOCK
);
use Proc::PidUtil qw(
	if_run_exit
	is_running
	get_script_name
	make_pidfile
	zap_pidfile
);
use Sys::Hostname::FQDN qw(
	fqdn
);
use Unix::Syslog qw(
	:macros
	openlog
	syslog
);
use vars qw($VERSION @EXPORT @ISA);
require Exporter;

@ISA = qw(Exporter);

$VERSION = do { my @r = (q$Revision: 0.11 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

@EXPORT = qw(
	run_honeypot
);


# private file scoped variables

my($me,$threads,$dns,$dnshost,$dnsport,$dnsaddr,$deny,$hostname,$laddr,
   $port,$delay,$config,$syslog,$verbose,$DNStimeout,$maxthreads,$maxcmds,
   $LOG,$DNSfileno,$disconnect,%Commands,$unique,$log_facility,%subref
);
my $CRLF	= "\r\n";

my @IDarray        = ('a'..'z','A'..'Z',(0..9));

=head1 NAME

Mail::SMTP::Honeypot -- Dummy mail server

=head1 SYNOPSIS

  use Mail::SMTP::Honeypot;

  run_honeypot($config)

=head1 DESCRIPTION

B<Mail::SMTP::Honeypot> is a perl module that appears to provide all the
functionality of a standard SMTP server except that when the targeted
command state is detected (default DATA), it terminates the connection with
a temporary failure and the response:

    421 Service not available, closing transmission channel

The purpose of this module is to provide a spam sink on a tertiary MX host.
The module daemon is run on an MX host with a very high priority number
specified in it's DNS record. i.e.

  some_mail_domain.com	IN MX 9999 lastmx.servicedomain.com.

Since many spammers target this mail server in the hope that its
configuration and/or security is not as strong or well maintained as the
primary mail host for a domain. In the off chance that a real message is
sent to the server, the TEMPORARY failure code will simply make the sending
host retry later -- probably with the lower priority numbered host.
Meanwhile, the server target by the spam source has its resources consumed
by B<honeypot>.

Honeypot does not spawn children and holds only a small reference to each
thread that it holds to a client, thus consuming minimal resources. It can
produce logs useful in analyzing the spam traffic to your site. Using it
with a detach in CONN mode is adequate for triggering a companion spam
program such as Mail::SpamCannibal while consuming minimum host resources.
At our site, we simply run B<honeypot> on the same host as our secondary MX
but on a different IP address.

Honeypot provides various levels of connection and transaction logging that
can be set in the configuration.

A delay may be inserted between the receipt of each command and the response
from the server daemon to slow down the sending client.

=head1 CONFIGURATION

Edit the B<rc.honeypot.pl> file to change or set the following:

  my $config = {

  # specify the directory for the pid file for this daemon
  # [required]
  #
	piddir		=> '/var/run',

  # deny at command state, one of:
  #	CONN EHLO HELO MAIL RCPT DATA
  # defaults to DATA if not specified
  # [optional]
  #	deny		=> 'DATA',


  # specify the local domain name, defaults to local hostname.
  # this is probably not what you want if you use virtual IP's
  # and have a real mail client on the same host. so...
  # specify the host 'answerback name' here.
  # [optional]
  #
  #	hostname	=> 'my.host.name.com',

  # specify the IP address to bind the listening port
  # defaults to ALL interfaces (INADDR_ANY)
  # [optional]
  #
  #	ip_address	=> '1.2.3.4',

  # listen port -- default 25
  # this is useful for debugging purposes
  # [optional]
  #
  #	port		=> 25,

  ## NOTE: 	see Concurrent Daemon Operation in the
  ##		documentation for setup where another
  ##		mail daemon is running on the same host.
  
  # specify the response delay after connect or upon
  # receipt of an smtp command from the client
  #
  # NOTE:	if a response is not received
  #		from the client in this time
  #		period, the smptdeny daemon will
  #		issue a 421 response and disconnect
  # [optional] default 10 seconds
  #
  #	delay		=> 10,

  # syslog facility, one of:
  #	LOG_KERN LOG_USER LOG_MAIL LOG_DAEMON
  #	LOG_AUTH LOG_SYSLOG LOG_LPR LOG_NEWS
  #	LOG_UUCP LOG_CRON LOG_AUTHPRIV LOG_FTP
  #	LOG_LOCAL0 LOG_LOCAL1 LOG_LOCAL2 LOG_LOCAL3
  #	LOG_LOCAL4 LOG_LOCAL5 LOG_LOCAL6 LOG_LOCAL7
  #
  # You should not need to change this
  #
  #	log_facility	=> 'LOG_MAIL',

  # syslog log level or (none), one of:
  #	STDERR LOG_EMERG LOG_ALERT LOG_CRIT LOG_ERR
  #	LOG_WARNING LOG_NOTICE LOG_INFO LOG_DEBUG
  #
  # NOTE: 	the command line -d flag overrides
  #		this and sets the level to STDERR
  # [optional]
  #
	syslog		=> 'LOG_WARNING',

  # log verbosity
  #	0 connect only
  #	1 + To: & From:
  #	2 + bad commands
  #	3 + trace execution
  #	4 + deep trace with sub names
  # [optional]
  #
	verbose		=> 0,

  # DNS host, if you do not have a resolver
  # on your host or for debugging
  # default: as returned by your resolver for local dns
  # [optional]
  #	dnshost		=> 'use.default',

  # DNS port, useful for debugging
  # [optional] default 53
  #
  #	dnsport		=> 53,

  # timeout for DNS PTR queries
  # [optional] default: use 'delay' above
  #
  #	DNStimeout	=> 10,

  # maximum number of connected clients
  # [optional] default 100
  #
  #	maxthreads	=> 100,

  # maximum number of commands per client
  # [optional] default 100
  #
  #	maxcmds		=> 100,

  # disconnect the remote after this much time
  # [optional] default 300 seconds
  #
  #	disconnect	=> 300,

  };

=head1 OPERATION

Launch the daemon with the command:

	rc.honeypot.pl [-d] [start | stop | restart]

The '-d' flag, this overides the config settings and
reports logging to STDERR

On some systems it may be necessary to wrap a shell script around
rc.honeypot.pl if the path for perl is not in scope during boot.

  #!/bin/sh
  #
  # shell script 'rc.honeypot'
  #
  /path/to/rc.honeypot.pl $*

A sample shell script is included in the distribution as B<rc.honeypot>

NOTE: suggest you test your configuration as follows...

  Set:	verbose	=> 3,
	delay	=> 5,

  ./rc.honeypot -d start

Connect to the daemon from a host not on the same subnet and watch the
output from daemon to verify proper operation.

Correct the configuration values and ENJOY!

=head2 Standalone Operation

For operation on a host where B<Mail::SMTP::Honeypot> is the only SMTP
daemon, the default configuration will work for most installations.

=head2 Concurrent Daemon Operation

To operate B<Mail::SMTP::Honeypot> concurrently with another mail daemon on
the same host you must do the following:

=item B<1)> add a virtual IP address for the daemon to answer.
The IP address in the rc.honeypot.pl config section should be left 
commented out so that the daemon will bind to INADDR_ANY.

In your startup sequence, execute the following: (example for Linux)

  #/bin/sh
  #
  # Edit for your setup.
  NETMASK="255.255.255.0"	# REPLACE with YOUR netmask!
  NETWORK="5.6.7.0"		# REPLACE with YOUR network address!
  BROADCAST="5.6.7.255"		# REPLACE with YOUR broadcast address
  # assign a virtual IP address
  IPADDR="5.6.7.8"

  # assign ethernet device
  DEVICE="eth0"			# REPLACE with your external device
  LUN="0"

  # Note:	the "real" IP address has no LUN
  #		virtual IP's are assigned LUN's starting with '0'
  #
  # i.e.	host IP = 5.6.7.1	eth0
  # virtIP	5.6.7.8		LUN 0	eth0:0
  # virtIP	5.6.7.9		LUN 1	eth0:1

  IFACE=${DEVICE}:${LUN}
  /sbin/ifconfig ${IFACE} ${IPADDR} broadcast ${BROADCAST} netmask ${NETMASK}
  /sbin/route add ${IPADDR} dev ${IFACE}
  echo Configuring $IFACE as $IPADDR

=item B<2)> run the honeypot daemon on an unused port.

Select a high port number that will not interfere with normail operation of
the host SMTP daemon or other services on the host.

  i.e.	in the config section of rc.honeypot.pl

	port	=> 10025,

=item B<3)> add packet filter rules to redirect queries.

This example is for IPTABLES on Linux. Similar rules would apply for other
filter packages.

  # allowed chain for TCP connections
  iptables -N allowed
  iptables -A allowed -p tcp --syn -j ACCEPT
  iptables -A allowed -p tcp -m state --state ESTABLISHED,RELATED -j ACCEPT
  iptables -A allowed -p tcp -j DROP

  # drop all external packets target on honeypot daemon
  iptables -t nat -A PREROUTING -p tcp -s 0/0 --dport 10025 -j DROP
  iptables -t nat -A PREROUTING -p tcp -d 5.6.7.8 --dport 25 -j REDIRECT --to-port 10025
  # alternate DNAT statement
  # iptables -t nat -a PREROUTING -p tcp -d 5.6.7.8 --dport 25 -j DNAT --to 5.6.7.8:10025

  ## if you are running SpamCannibal, add this rule to capture IP's of connecting hosts
  ## iptables -A INPUT -p tcp -i eth0 --dport 10025 -j QUEUE

  # allow the internal port to connect
  iptables -A INPUT -p tcp -s 0/0 --dport 10025 -j allowed

=head1 EXPORTS

Only one function is exported by Honeypot.pm. This function is called in the
rc.honeypot.pl.sample script to launch the B<honeypot> daemon.

=over 4

=item * run_honeypot($config); # with @ARGV

Launch the honeypot daemon.

  input:	config hash
  returns:	nothing (exits)

=back

=cut

sub run_honeypot  {
  die "arg 1 of run_honeypot must be a hash\n"
	unless ref $_[0] eq 'HASH';
  my $pidfile = &check_run;	# check for another running daemon
  &check_config;		# verify that config array is correct and populated
  clean_child();  		# double fork a child
  make_pidfile($pidfile,$$)
	or die "could not make pidfile '$pidfile' for $$\n";
  init_all();
  syslog_config();
  goto &daemon;
}

sub usage {	# tested by hand
  $me = $0 unless $me;
  print STDERR $_[0],"\n" if $_[0];
  print STDERR qq|
Syntax:	$me start
	$me stop
	$me restart
	$me status

	-d switch may be added to
	   redirect logging to STDERR

|;
  exit 1;
}

sub kill_job {
  my($pidfile) = @_;
  my $pid = is_running($pidfile);
  if ($pid) {
    kill 15, $pid;
    $pid = 0;
    sleep 1;
  } else {
    print STDERR "$me: not running\n";
  }
}

# return true on good number
sub vld_num {		# t => vld_num.t
  my $num = shift;
  return $num =~ /\d/ && $num !~ /[\D\s]/;
}

sub bad_config {
  my($msg) = @_;
  print STDERR 'config: ',$msg,"\n";
  exit 1;
}

#=item * $sub_name = who();
#
#Returns the name of the calling subroutine without the package name.
#
#=cut

sub who {
  (caller(1))[3] =~ /[^:]+$/;
  return $& . ': ';
}

# returns $pidfile if successful or exits
#
sub check_run {
  my($c) = @_;
  unless ($c->{piddir} && -d $c->{piddir} && -w $c->{piddir}) {
    print STDERR "pid directory not specified or not writable\n";
    exit 0;
  }
  $me = get_script_name();
  $0 = $me;
  
  usage('missing command argument(s)') if
	(grep($_ eq '-d',@ARGV) && @ARGV < 2) ||
	@ARGV < 1;
  my $pidfile = $c->{piddir} .'/'. $me . '.pid';
  foreach(@ARGV) {
    if ($_ eq 'start') {
      if_run_exit($c->{piddir},"already running\n");
      last;
    }
    elsif ($_ eq 'stop') {
      kill_job($pidfile);
      exit 0;
    }
    elsif ($_ eq 'restart') {
      kill_job($pidfile);
      last;
    }
    elsif ($_ eq 'status') {
      my $pid = is_running($pidfile);
      if ($pid) {
	print STDERR "$pid $me is running\n";
      } else {
	print STDERR "$me not running\n";
      }
      last;
    }
    elsif ($_ eq '-d') {
      $c->{syslog} = 'STDERR';
    }
    else {
      usage("unknown command argument '$_'\n");
    }
  }

  return $pidfile;
}

### validate and set configuration defaults
#
sub check_config {
# ip-address
  my($c) = @_;;
  if ($c->{ip_address}) {
    bad_config("bad IP address '$c->{ip_address}'")
	unless $laddr = inet_aton($c->{ip_address});
  } else {
    $laddr = Socket::INADDR_ANY;
  }
# port number
  if ($port = $c->{port}) {
    bad_config("bad port number '$port'")
	unless vld_num($port);
  } else {
    $port		= 25;
  }
# delay
  if ($delay = $c->{delay}) {
    bad_config("invalid delay '$delay'")
	unless vld_num($delay);
  } else {
    $delay		= 10;
  }
# deny
  if ($deny = $c->{deny}) {
    $deny		= uc $deny;
    bad_config("invalid deny state '$deny'")
	unless $deny =~ /^(?:CONN|EHLO|HELO|MAIL|RCPT|DATA)$/;
    $deny = 'HELO|EHLO' if $deny =~ /HELO|EHLO/;
  } else {
    $deny		= 'DATA';
  }
# hostname
  $hostname		= $c->{hostname} || fqdn();
# syslog
  if ($log_facility = $c->{log_facility}) {
    $log_facility = uc $log_facility;
    bad_config("invalid log facility '$log_facility'")
	unless $log_facility =~ /^(?:LOG_KERN|LOG_USER|LOG_MAIL|LOG_DAEMON|LOG_AUTH|LOG_SYSLOG|LOG_LPR|LOG_NEWS|LOG_UUCP|LOG_CRON|LOG_AUTHPRIV|LOG_FTP|LOG_LOCAL0|LOG_LOCAL1|LOG_LOCAL2|LOG_LOCAL3|LOG_LOCAL4|LOG_LOCAL5|LOG_LOCAL6|LOG_LOCAL7)$/;
  } else {
    $log_facility = 'LOG_MAIL';
  }
  if ($syslog = $c->{syslog}) {
    $syslog = uc $syslog;
    bad_config("invalid log request '$syslog'")
	unless $syslog =~ /^(?:STDERR|LOG_EMERG|LOG_ALERT|LOG_CRIT|LOG_ERR|LOG_WARNING|LOG_NOTICE|LOG_INFO|LOG_DEBUG)$/;
  }
# verbose
  if ($verbose = $c->{verbose}) {
    bad_config("invalid verbosity '$verbose'")
	unless vld_num($verbose) && $verbose > 0;
########### DEEP TRACE CODE #############
    if ($verbose > 3) {
      foreach(sort keys %Mail::SMTP::Honeypot::) {
	my $subref = \&{"Mail::SMTP::Honeypot::$_"};
	$Mail::SMTP::Honeypot::{$_} =~ /[^:]+$/;
	$subref{$subref} = $&;
      }
    }
########### END DEEP TRACE CODE #############
  } else {
    $verbose = 0;
  }
# dns host
  if ($_ = $c->{dnshost}) {
    bad_config("invalid dns hostname '$dnshost'")
	unless ($dnshost = inet_aton($_));
  } else {
    $dnshost = get_ns();
  }
# dns port
  if ($dnsport = $c->{dnsport}) {
    bad_config("invalid dns port number '$dnsport'")
	unless vld_num($dnsport);
  } else {
    $dnsport = 53;
  }
  if ($dnshost) {
    $dnsaddr = sockaddr_in($dnsport,$dnshost);
  }
# DNStimeout
  if ($DNStimeout = $c->{DNStimeout}) {
    bad_config("invalid DNS timeout '$DNStimeout'")
	unless vld_num($DNStimeout) && $DNStimeout >= $delay;
  } else {
    $DNStimeout		= $delay;
  }
# maxthreads
  if ($maxthreads = $c->{maxthreads}) {
    bad_config("invalid maximum client count '$maxthreads'")
	unless vld_num($maxthreads);
  } else {
    $maxthreads		= 100;
  }
# maxcmds
  if ($maxcmds = $c->{maxcmds}) {
    bad_config("invalid maximum client count '$maxcmds'")
	unless vld_num($maxcmds);
  } else {
    $maxcmds		= 100;
  }
# disconnect
  if ($disconnect = $c->{disconnect}) {
    bad_config("invalid maximum client count '$disconnect'")
	unless vld_num($disconnect);
  } else {
    $disconnect		= 300;
  }
}

sub clean_child() {
  my $pid = fork;
  if ($pid) {
    waitpid($pid,0);
    exit 0;
  }

  chdir '/';			# allow root dismount
  open STDIN, '/dev/null' or die "Can't dup STDIN to /dev/null: $!";
  open STDOUT, '>/dev/null' or die "Can't dup STDOUT to /dev/null: $!";

  exit 0 if $pid = fork;	# double fork to release instantiating terminal
}

sub _trace {
  return (wantarray) ? (\$threads,\$dns) : \$threads;
}

sub init_all() {
  $unique = $$ -1;
  $threads	= {};				# thread hash
  die "could not open DNS socket\n"
	unless ($dns = open_udpNB());
  $DNSfileno = fileno($dns);
  $threads->{$DNSfileno} = {
	sock	=> $dns,
	alarm	=> 0,
#	name	=> '4.3.2.1.in-addr.arpa',
#	read	=> \&dns_rcv
  };
  $dns = {};					# dns transaction hash
}

sub my_dump {
  my %names;
  local *pref = __PACKAGE__ . '::';
  foreach(keys %{*pref}) {
    $names{'*'.$_} = \&{*pref->{$_}};
  }
  my @d = (
	$threads	=> 'threads',
	$dns		=> 'dns',
  );
  for ($_=0;$_<@d;$_+=2) {
    my $d = new Data::Dumper([$d[$_]],[$d[$_+1]]);
    $d->Seen(\%names);
    @_ = split(/\n/,$d->Dump);
    foreach(@_) {
      logit($_ ."\n");
    }
  }
}

sub daemon {
  unless ($syslog && $syslog eq 'STDERR') {
    open STDERR, '>/dev/null' or die "Can't dup STDERR to /dev/null: $!";
  }

# initialization complete, log start up message
  logit('Initiated...');

  my $run = 1;
  local $SIG{TERM} = sub {$run = 0};
  local $SIG{USR1} = \&my_dump;
  local $SIG{PIPE} = 'IGNORE';

  my $then = time;
  my $sock = open_listenNB($port,$laddr);
  die "could not open listen socket on port $port\n"
	unless $sock;
  my $fileno = fileno($sock);
  my $go_listen = $threads->{$fileno} = {
	sock	=> $sock,
	alarm	=> 0,
	read	=> \&newthread,
#	next	=> \&next thing to do
  };
  my($rin,$win,$rout,$wout,$delta,$nfound);
  while($run) {
    $win = $rin = '';
    $threads->{$DNSfileno}->{read} = \&dns_rcv;		# always armed
    foreach(grep(!/\D/,keys %$threads)) {		# each thread key
      vec($rin,$_,1) = 1 if $threads->{$_}->{read};	# set read selects
      vec($win,$_,1) = 1 if $threads->{$_}->{write};	# set write selects
    }
    $go_listen->{read} = \&newthread;			# re-arm listner if it was busy
    $nfound = select($rout=$rin,$wout=$win,undef,1);	# tick each second

    if ($nfound > 0) {
      do_thread($wout,'write') if $wout;
      do_thread($rout,'read') if $rout;
    }
    elsif ($delta = ($_ = time) - $then) {		# timer = next second or more
      $then = $_;
      my @threads = keys %$threads;
      foreach(@threads) {				# each receive thread
        next unless exists $threads->{$_};
	my $tptr = $threads->{$_};
	if ($tptr->{alarm} &&
	  ($tptr->{alarm} + $delay) < $then) {
	  $tptr->{alarm} = time + $disconnect - $delay;
	  my($logtxt,$go);
	  if ($tptr->{tout}) {
	    $go = $tptr->{tout};
	    $logtxt = 'tout ';
	  } else {
	    $go = $tptr->{next};
	    $logtxt = 'next ';
	  }
	  if ($verbose > 3) {			# deep trace
	    $logtxt = &who ."delay ended for '$_' $logtxt => ".
		(exists $subref{$go}) ? $subref{$go} : 'sub ref not defined';
	    logit($logtxt);
	  }
	  elsif ($verbose > 2) {
	    logit(&who ."delay ended for '$_'\n");
	  }
	  $go->($_);
	  if (exists $threads->{$_} && ! $threads->{$_}->{tout}) {
	    $threads->{$_}->{tout} = \&terminate
	  }
	  last;
	}
      }
      foreach(keys %$dns) {				# each dns thread
	if ($dns->{$_}->{alarm} &&
	  ($dns->{$_}->{alarm} + $delay) < $then) {
	  logit(&who ."dns ended for id $_ for $dns->{$_}->{fileno}\n") unless $verbose < 3;
	  delete $dns->{$_};
	  last;						# only do one per check for efficiancy
	}
      }
    }
  }
  &close_all;
  logit('Exiting...');
  closelog();
  exit 0;
}

#
# execute a thread based on what the select routine returns
# sort used for testing only
#

sub do_thread {		# t => do_thread.t
  my($vec,$op,$sort) = @_;
  logit(&who . $op) unless $verbose < 3;			# trace each thread
  my @threads;		# use array in case we decide not to use 'goto' at return of this subr
  if ($sort) {
    @threads = sort {$a <=> $b} grep(!/\D/,keys %$threads);	# each numeric thread key
  } else {
    @threads = grep(!/\D/,keys %$threads);
  }
  foreach (@threads) {		# or if re-entering after read with a deleted thread                            
    next unless exists $threads->{$_} && $threads->{$_};	# skip killed threads
    next unless vec($vec,$_,1);					# skip inactive threads
    next unless $threads->{$_}->{$op};
    my $go = $threads->{$_}->{$op};
    $threads->{$_}->{$op} = undef;				# clear vector
    next unless ref $go;					# ignore blank vectors
    @_ = ($_);
    if ($verbose > 3) {						# deep trace
      my $exsub = (exists $subref{$go}) ? $subref{$go} : 'sub ref not found';
      logit(&who ."exec $op for '$_' => $exsub\n");
    }
    elsif ($verbose > 2) {
      logit(&who ."executing $op for '$_'\n") unless $verbose < 3;
    }
    goto $go;							# do it and return
  }
}

sub writesock {		# t => new_rw_sock.t
  my($fileno) = @_;
  my $tptr = $threads->{$fileno};
  my $bytes = length($tptr->{wargs}) - $tptr->{woff};
  $! = 9;
  my $wrote = syswrite(	$tptr->{sock},
			$tptr->{wargs},
			$bytes,
			$tptr->{woff},
  	) if fileno($tptr->{sock});			# closed filehandles return false
  my $logtxt = &who . $fileno .' ';
  if (defined $wrote) {
    $logtxt .= $wrote;
  }
  else {
    $logtxt .= 'sock error: '. $!;
  }
  logit($logtxt) unless $verbose < 3;
  if (defined $wrote) {
    $tptr->{woff} += $wrote;
    if ($tptr->{woff} == $bytes) {			# if complete
      my $go = $tptr->{next};
      unless ($verbose < 4) {				# deep trace
	my $exsub = (exists $subref{$go}) ? $subref{$go} : 'sub ref not found';
	logit(&who ."next => $exsub for '$fileno'\n");
      }
      goto $go;						# goto the next link
    }
  } elsif (sockerror($! || 9)) {			# default to bad file descriptor
    goto &removethread;					# remove thread if there was an error
  }
  $tptr->{write} = \&writesock;				# restore write pointer
}

sub _readsock {		# t => new_rw_sock.t
  my($fileno) = @_;
  my $tptr = $threads->{$fileno};
  my $bytes = sysread(	$tptr->{sock},
			$tptr->{rargs},
			2048,				# limit reads, data is mostly limited to 2048
			$tptr->{roff}
  ) if fileno($tptr->{sock});				# closed filehandles return false
  logit(&who . $fileno .' '. ((defined $bytes) ? $bytes : 'error '. $!))
		unless $verbose < 3;			# trace
  return($tptr,$bytes);
}
 
sub readsock {		# t => new_rw_sock.t
  my ($tptr,$bytes) = &_readsock;
  if (defined $bytes) {					# returns undef on error
    goto &removethread 
	unless $bytes;					# EOF
    $tptr->{alarm} = time;				# renew timeout
    $tptr->{roff} += $bytes;				# bytes read   
    my $go = $tptr->{next};
    unless ($verbose < 4) {				# deep trace
      my $exsub = (exists $subref{$go}) ? $subref{$go} : 'sub ref not found';
      logit(&who ."next => $exsub for '$_[0]'\n");
    }
    goto $go;
  } elsif (sockerror($! || 9)) {			# default to bad file descriptor
    goto &removethread;					# detected fatal condition
  }
# probably never get to here
  $tptr->{read} = \&readsock;				# restore read pointer
}

#
# input:        error code
# returns:      true if error, else false
#
sub sockerror {         # t => sockerror.t
  my($err) = @_;
  return ($err == EINTR ||                      # don't die for interrupts
          $err == EWOULDBLOCK)                  # or while waiting
        ? 0
        : ($err) ? 1 : 0;
}

# remove a thread, closing the socket
#
# input:        threads pointer, fileno
# returns:      nothing
#
sub removethread {      # t => removethread.t
  my($fileno) = @_;
  logit(&who . $fileno) unless $verbose < 3;
  my $sock = $threads->{$fileno}->{sock};
  delete $threads->{$fileno};
  close $sock if $sock;                                 # don't attempt close on non-existent sock
}

sub close_all {
  foreach(keys %$threads) {
    removethread($_);
  }
}

sub newthread {		# t => new_rw_sock.t
  my($listner) = @_;
  if ((keys %$threads) > $maxthreads) {
    logit(&who . "thread pool full\n") unless $verbose < 2;
    return;
  }
  $threads->{$listner}->{read} = \&newthread;           # restore vector
  my($sock,$netaddr) = accept_NB($threads->{$listner}->{sock});
  return unless $sock;
  my $ipaddr = inet_ntoa($netaddr);
  unless ($ipaddr) {
    close $sock;
    return;
  }
  set_so_linger($sock,30);                              # set linger to 30 seconds, just in case
  my $fileno = fileno($sock);
  $threads->{$fileno} = {
        alarm   => 1,
#	cmdcnt	=> 0,					# number of allowed commands
#	conlog	=> 0,					# connection logged
#	domain	=> '',					# claims to be this domain
	ipaddr	=> $ipaddr,				# dot quad
#	lastc	=> 'CONN',				# last connection state
	name	=> '',					# smtp host name
#	next	=> \&sub,				# next sub to exec
#	proto	=> 'SMTP',				# protocol
#	read	=> \&sub,				# read sub to exec
#	rargs	=> '',					# read string
#	roff	=> 0,					# length
        sock    => $sock,                               # socket
#	write	=> \&sub,				# write sub to exec
#	wargs	=> ''.					# string to write
#	woff	=> 0,					# offset into write string
  };
  if ($deny eq 'CONN') {
    $threads->{$fileno}->{next} = \&terminate;
  } else {
    dns_send($fileno,$ipaddr);			# initiate a PTR lookup
    @{$threads->{$fileno}}{qw(
	alarm
	cmdcnt
	cok
	domain
	lastc
	name
	next
	proto
	wargs
    )} = (
	time,					# alarm
	0,					# cmdcnt
	0,					# cok
	'',					# domain
	'CONN',					# lastc
	'',					# name
	\&connOK,				# next
	'SMTP',					# proto
	'220 '. $hostname .' service ready'. $CRLF,
    );
  }
}

sub connOK {
  my($fileno) = @_;
  my $tptr = $threads->{$fileno};
  $tptr->{cok} = 1;				# flag that says this is done
  logit('honeypot connect '. $tptr->{name} .'['. $tptr->{ipaddr} .']');
  $tptr->{woff} = 0; 
  $tptr->{next} = \&readSMTP;
  $tptr->{tout} = \&write_delay;
#  $tptr->{alarm} = use previous value
}

sub terminate {		# t => parseSMTP.t
  my($fileno) = @_;
  $threads->{$fileno}->{wargs} = '421 Service not available, closing transmission channel'. $CRLF;
  logit(&who ."sent terminate for '$fileno'\n") unless $verbose < 3;
  write_rearm($fileno,\&removethread,1);	# immediate terminate
}

# implementation from rfc 2821
#
# STATE:                allowed commands
#
# initial:      HELO, EHLO, NOOP, HELP, VRFY, RSET, and QUIT
#
# HELO/EHLO     MAIL, HELO, EHLO, NOOP, HELP, VRFY, RSET, and QUIT
#
# MAIL          RCPT, HELO, EHLO, NOOP, HELP, VRFY, RSET, and QUIT
#
# RCPT          RCPT, DATA, EHLO, NOOP, HELP, VRFY, RSET, and QUIT
#
# DATA          {data} .

%Commands = (
        EHLO    => \&_EHLO,
        HELO    => \&_HELO,
        MAIL    => \&_MAIL,
        RCPT    => \&_RCPT,
        DATA    => \&terminate,
        RSET    => \&_RSET,
        VRFY    => \&_VRFY,
        HELP    => \&_HELP,
        NOOP    => \&_NOOP,
        QUIT    => \&_QUIT,
        SEND    => \&notimp,
        SOML    => \&notimp,
        SAML    => \&notimp,
        EXPN    => \&notimp,
        TURN    => \&notimp,
);

sub parseSMTP {		# t => parseSMTP.t
  my($fileno) = @_;
  my $tptr = $threads->{$fileno};
  goto &terminate if ++$tptr->{cmdcnt} > $maxcmds;
  my $newc = '';
  my $smtp_args = '';
  if ($tptr->{rargs} =~ /^\s*([a-zA-Z]{4})\b/) {
    $newc = uc $1;
    $smtp_args = lc $';
  }
  my $lastc = $tptr->{lastc};
  $tptr->{wargs} = '';					# error text
  unless ($newc) {
    $tptr->{rargs} =~ s/[^[\w .-]//g;
    $tptr->{wargs} = '500 5.5.1 Command unrecognized "'. $tptr->{rargs} .'"';
  }
  elsif (! exists $Commands{$newc}) {
    $tptr->{wargs} = '500 5.5.1 Command unrecognized "'. $1 .'"';
  }
  elsif ($tptr->{roff} > 512) {				# rfc2821 4.5.3.1
    $tptr->{wargs} = '500 5.5.4 Command line too long';
  }
  elsif ($lastc =~ /(?:CONN|HELO|EHLO)/) {
    if ($newc eq 'RCPT') {
      $tptr->{wargs} = '503 5.0.0 Need MAIL before RCPT';
    }
    elsif ($newc eq 'DATA') {
      $tptr->{wargs} = '503 5.0.0 Need MAIL command';
    }
  }
  elsif ($lastc eq 'MAIL') {
    if ($newc eq 'MAIL') {
      $tptr->{wargs} = '503 5.5.0 Sender already specified';
    }
    elsif ($newc eq 'DATA') {
      $tptr->{wargs} = '503 5.0.0 Need RCPT before DATA';
    }
  }
  elsif ($lastc eq 'RCPT') {
    if ($newc eq 'MAIL') {
      $tptr->{wargs} = '503 5.5.0 Sender already specified';
    } 
  }

  if ($tptr->{wargs}) {							# if there is an error
    logit(&who ."$newc ". $tptr->{wargs}) unless $verbose < 2;		# more log info
    $tptr->{wargs} .= $CRLF;
    write_rearm($fileno,\&readSMTP);					# send error and return to this routine
  } elsif ($newc eq $deny) {
    $tptr->{alarm} = time;
    $tptr->{next} = \&terminate;
    logit(&who .'deny '. $newc . $smtp_args) unless $verbose < 3;
  } else {								# else
    logit(&who . $newc . $smtp_args) unless $verbose < 3;		# trace success
    $Commands{$newc}->($fileno,$smtp_args,$tptr);			# execute the command
  }
}

#
# input:	to or from,
#		string [to/from: garbage junk email@addy.sufx more junk]
# returns:	(error text on error)
#		(name,domain) on match
#	or 	(name,{defined+false}) if 'postmaster' by itself

sub xtract_to_from {	# t => parseSMTP.t
  my $match = lc shift;					# 'to' or 'from' or 'vrfy'
  my $string = lc shift;				# input string
  my $what = ($string =~ /[^\s:]+/)			# must have some characters
	? $& : '';
  $string = $' || '';					# remainder of string
  return ('501 5.5.2 Syntax error in parameters scanning "'. $what .'"'. $CRLF)
	unless $what eq $match && $string =~ /^:/;	# return error if 'to / from' does not match
							# or is not terminated with colon
  $string = $';						# snip off colon
  if ($string =~ /([\w\.-]+)@([\w\-]+\.[\w\.-]+)/) {	# if email addy found
    return ('500 5.5.4 User name too long'. $CRLF)
	if length($1) > 64;				# rfc2821 4.3.5.1
    return ('500 5.5.4 Domain name too long'. $CRLF)
	if length($2) > 255;
    return ($1,$2);
  }
  return ('postmaster','')
	if $string =~ /^\s*<?postmaster>?\s*$/ && $match =~/to|vrfy/;
  return ('','')
	if $string =~ /^\s*<\s*>/ && $match =~/from/;	# error message returned to ME

# figure what kind or error to report
  $string =~ s/^\s+//;					# waste leading spaces
  @_ = split(/\s+/,$string);
  return ('555 5.5.4 "'. $_[1] .'" parameter unrecognized'. $CRLF)
	if @_ > 1;					# error if there are unknown parameters
  return ('553 5.5.4 Domain name required for address "'. $_[0] .'"'. $CRLF)
	if $_[0];
  return ('501 5.0.0 Argument required'. $CRLF);
}

#
# SMTP commands
#
#	HELO & EHLO
#

sub _EHLO {		# t => commands.t
  push @_, 1;
  goto &_HELO;
}

sub _HELO {		# t => commands.t
  my($fileno,$smtp_args,$tptr,$is_EHLO) = @_;
  $tptr->{domain} = ($smtp_args =~ /[\w\.-]+/)
	? $& : 'nobody';
#      S: 250 hostname ready for {domain}
# (ehlo)  250 HELP
  my $wargs = $hostname . ' ready for '. $tptr->{domain} .' ('. $tptr->{name} .'['. $tptr->{ipaddr} .'])'. $CRLF;
  if ($is_EHLO) {
    $tptr->{wargs} = 
	'250-'. $wargs .
	'250 HELP'. $CRLF;
    $tptr->{lastc} = 'EHLO';
    $tptr->{proto} = 'ESMTP';
  } else {
  $tptr->{wargs} = 
	'250 '. $wargs;
    $tptr->{lastc} = 'HELO';
  }
  write_rearm($fileno,\&readSMTP);
}

#
#	MAIL
#
# no attempt is made to verify the sender envelope address since
# it is so easy to forge an address that will validate somewhere
#
sub _MAIL {		# t => commands.t
  my($fileno,$smtp_args,$tptr) = @_;
  my($name,$domain) = xtract_to_from('from',$smtp_args);
  unless (defined $domain) {
    $tptr->{wargs} = $name;		# 'name' contains the error message when 'domain' is undefined
  } else {
    $tptr->{lastc} = 'MAIL';
    $tptr->{wargs} = '250 2.1.0 OK'. $CRLF;
    $tptr->{from} = $name .'@'. $domain;
    $tptr->{msgid} = uniquemsgid();
    logit($tptr->{msgid}.': from=<'. $tptr->{from} .'>, relay='. $tptr->{domain}.' ('. $tptr->{name} .'['. $tptr->{ipaddr} .'])')
	unless $verbose < 1;
  }
  write_rearm($fileno,\&readSMTP);
}

#
#	RCPT && VRFY
#
sub _RCPT {		# t => commands.t
  push @_, 1;
  goto &_VRFY;
}

sub _VRFY {		# t => commands.t
  my($fileno,$smtp_args,$tptr,$is_rcpt) = @_;
  my($name,$domain);
  if ($is_rcpt) {
    ($name,$domain) = xtract_to_from('to',$smtp_args);
  } else {
    ($name,$domain) = xtract_to_from('vrfy','vrfy:'. $smtp_args);
  }
  if (defined $domain) {
    my $to = ($domain) ? $name .'@'. $domain : $name .'@'. $hostname;	# postmaster is by itself without attached domain
    $tptr->{lastc} = ($is_rcpt) ? 'RCPT' : 'VRFY';
    $tptr->{wargs} = '250 2.1.5 OK'. $CRLF;
    $is_rcpt = ($is_rcpt) ? 'rcpt' : 'vrfy';
    logit($tptr->{msgid}.': '. $is_rcpt .'=<'. $to .'>, relay='. $tptr->{domain}.' ('. $tptr->{name} .'['. $tptr->{ipaddr} .'])')
	unless $verbose < 1;
  }
  else {
    $tptr->{wargs} = $name;					# this is really the error string from xtract_to_from
  }
  write_rearm($fileno,\&readSMTP);
}

#
#	RSET
#
sub _RSET {		# t => commands.t
  my($fileno,$smtp_args,$tptr) = @_;
  $tptr->{wargs} = '250 2.0.0 OK'. $CRLF;
  goto &soft_reset;
}

#
#	HELP
#
sub _HELP {		# t => commands.t
  my($fileno,$smtp_args,$tptr) = @_;
  $tptr->{wargs} = 
'214-2.0.0     Commands supported are'. $CRLF .
'214-2.0.0    HELO EHLO MAIL RCPT DATA'. $CRLF .
'214 2.0.0    RSET VRFY HELP NOOP QUIT'. $CRLF;
  write_rearm($fileno,\&readSMTP);
}

#
#	NOOP
#
sub _NOOP {		# t => commands.t
  my($fileno,$smtp_args,$tptr) = @_;
  $tptr->{wargs} = '250 2.0.0 OK'. $CRLF;
  write_rearm($fileno,\&readSMTP);
}

#
#	QUIT
#
sub _QUIT {		# t => commands.t
  my($fileno,$smtp_args,$tptr) = @_;
  $threads->{$fileno}->{wargs} = '221 2.0.0 '. $hostname .' closing connection'. $CRLF;
  write_rearm($fileno,\&removethread);
}

#
#	DATA
#	this is where we disconnect
#
### REPLACED BY TERMINATE
#
#sub _DATA {
#  my($fileno) = @_;
#  my $tptr = $threads->{$fileno};
#  $tptr->{woff} = 0; 
#  $tptr->{next} = \&terminate;
#  $tptr->{tout} = 0;
#  $tptr->{alarm} = time;			# wait 'delay'
#}

#
#	notimp
#
sub notimp {		# t => parseSMTP.t
  my($fileno,$smtp_args,$tptr) = @_;
  $tptr->{wargs} = '502 5.5.1 Command not implemented'. $CRLF;
  write_rearm($fileno,\&readSMTP);
}

sub soft_reset {        # t => commands.t
  my($fileno) = @_;
  my $tptr = $threads->{$fileno};
  my $wargs = $tptr->{wargs};
  my $ipaddr = $tptr->{ipaddr};
  my $name = $tptr->{name} || '';
  $tptr = clear_bufs($fileno);
  $tptr->{lastc} = 'CONN';
  $tptr->{proto} = 'SMTP';
  $tptr->{wargs} = $wargs || '554 5.3.5 unknown mailer error'. $CRLF;
  $tptr->{ipaddr} = $ipaddr;
  $tptr->{name} = $name;
  logit(&who . $tptr->{wargs}) unless $verbose < 2;
  write_rearm($fileno,\&readSMTP);
}

sub readSMTP {
  my($fileno) = @_;
  my $tptr = $threads->{$fileno};
  $tptr->{alarm} = time;
  $tptr->{tout} = \&readRestore;
}

sub readRestore {
  my($fileno) = @_;
  my $tptr = $threads->{$fileno};
  $tptr->{read} = \&readsock;
  $tptr->{roff} = 0;
  $tptr->{next} = \&parseSMTP;
  $tptr->{alarm} = time + $disconnect - $delay;		# five minute timeout
  $tptr->{tout} = \&terminate;
}

# return buffers to the 'ehlo,helo' state
#
# input:        threads, fileno
# returns:      $threads->{$fileno}
#
sub clear_bufs {	# t => commands.t
  my($fileno) = @_;
  my($sock,$domain,$proto) = @{$threads->{$fileno}}{qw(
      sock  domain  proto)};
  delete $threads->{$fileno};				# clean all buffers in the thread
  my $lastc = ($domain)
        ? ($proto eq 'ESMTP') ? 'EHLO' : 'HELO'
        : 'CONN';
  my $tptr = $threads->{$fileno} = {};
  @{$tptr}{qw(
    sock  domain  proto  lastc)} =			# restore only those that are needed
  ($sock,$domain,$proto,$lastc);
  return $tptr;
}

sub write_rearm {	# t => parseSMTP.t
  my($fileno,$next,$immediate) = @_;
  my $tptr = $threads->{$fileno};
  $tptr->{woff} = 0;
  $tptr->{next} = $next;
  goto &write_delay
	if $immediate;
  $tptr->{tout} = \&write_delay;
  $tptr->{alarm} = time;				# wait 'delay'
}

sub write_delay {
  my($fileno) = @_;
  my $tptr = $threads->{$fileno};
  $tptr->{tout} = \&terminate;
  $tptr->{write} = \&writesock;
  $tptr->{alarm} = time;				# kill thread if we can't write
}

#=item * syslog_config();
#
#Configure Unix logging.
#
#  NOTE, logging must be initiated by the caller
#
#  input:	none
#  output:	none
#
#=cut

sub syslog_config {
  if ($syslog && $syslog ne 'STDERR') {
    openlog($me, LOG_PID(), eval "$log_facility");
    $LOG = eval "$syslog";				# save LOGlevel for everyone
  }
}

#=item * logit($msg);
#
#Log a message.
#
#  input:	message string
#  output:	none
#
#=cut

sub logit {
  my($msg) = @_;
  return unless $syslog;
  $msg .= "\n";
  $msg =~ s/[\r\n]+/\n/g;
  if ($syslog eq 'STDERR') {
    print STDERR $msg;
  }
  else {
    syslog($LOG,"%s",$msg);
  }
}

#=item * closelog();
#
#Close the syslog facility if it has been opened
#
#  input:	none
#  returns:	none
#
#=cut

sub closelog {
  local $^W = 0; # no warnings;
  &Unix::Syslog::closelog
	if $syslog && $syslog ne 'STDERR';
}

sub get_unique {	# t => uniquemsgid.t
  my($seed) = @_;
  $unique = $seed if $seed;
  $unique = 1 if ++$unique > 65535;
  return $unique;		# return an ascending number or the PID if just invoked
}

#=item * $msgid = uniquemsgid($seed);
#
#Uses 'time' as a seed (standard) unless specified. Returns an email-safe 
#alphanumeric string based on the time (or seed), the pid of the caller and a 
#random number. Guaranteed to be unique for multiple daemons with less than
#65k new reqests per second.
#
#  input:        [optional seed] or [default 'time']
#  returns:      string of the form: 'bbnPCFUDYctT'
#
#=cut

sub uniquemsgid {       # t => uniquemsgid.t
  my $t = shift || time;
  my $q = sprintf("%010u",($$ << 16) + get_unique());
  my @serial = ();
  foreach(0..5) { 
    my $x = $t % 62;
    my $y = $q % 62;
    unshift @serial,$IDarray[$x],$IDarray[$y];
    $t = int $t/62;
    $q = int $q/62;
  }
  return join('',@serial);
}

sub dns_send {		# tested by hand
  return unless $dnsaddr && $DNSfileno;	# skip if no DNS present
  my($fileno,$ipaddr) = @_;
  my $id = get_unique();
  logit(&who . $ipaddr ." $fileno id $id")
	unless $verbose < 3;
  my @ip = split(/\./,$ipaddr);
  @_ = reverse @ip;
  my $name =  join('.',@_,'in-addr.arpa');
  my $buffer;
  my $offset = newhead(\$buffer,
	$id,
	BITS_QUERY | RD,		# query, recursion desired
	1,0,0,0,			# one question
  );
  my ($get,$put,$parse) = new Net::DNS::ToolKit::RR;
  $offset = $put->Question(\$buffer,$offset,$name,T_PTR,C_IN);
  return unless $buffer;
  $dns->{$id} = {
	fileno	=> $fileno,
	alarm	=> time,
	name	=> $name,
  };
  $threads->{$fileno}->{id} = $id;	# mark original thread with this ID
# UDP may not block
  send(
	$threads->{$DNSfileno}->{sock},
	$buffer,0,
	$dnsaddr);
}

sub dns_rcv {		# tested by hand
  my($fileno) = @_;
  my $tptr = $threads->{$fileno};
  my $msg;
  my $sender = recv($tptr->{sock},$msg,NS_PACKETSZ,0);
  return undef unless $sender;					# no message received
  return undef if length($msg) < HFIXEDSZ;			# short message
  my ($off,$id,$qr,$opcode,$aa,$tc,$rd,$ra,$mbz,$ad,$cd,$rcode,
	$qdcount,$ancount,$nscount,$arcount)
	= gethead(\$msg);
  return undef unless
	$tc == 0 &&
	$qr == 1 &&
	$opcode == QUERY &&
	($rcode == NOERROR || $rcode == NXDOMAIN || $rcode == SERVFAIL) &&
	$qdcount == 1 &&
	exists $dns->{$id};
  my $pfno = $dns->{$id}->{fileno};				# originating thread pointer
  my $pname = $dns->{$id}->{name};
  delete $dns->{$id};						# remove dns query thread
  return undef
	unless exists $threads->{$pfno};
  return undef unless length($msg) > HFIXEDSZ;			# no message
  my ($get,$put,$parse) = new Net::DNS::ToolKit::RR;
  my($name,$t,$type,$class,$ttl,$rdl,@rdata);
  ($off,$name,$type,$class) = $get->Question(\$msg,$off);
  my $lname = lc $name;
  if (  $ancount &&
	$rcode == &NOERROR &&
	$lname eq $pname &&
	$type == T_PTR &&
	$class == C_IN
  ) {
    foreach(0..$ancount -1) {
      ($off,$name,$t,$class,$ttl,$rdl,@rdata) = $get->next(\$msg,$off);
      last if $t == T_PTR;
    }
  }
  ($name) = @rdata;
  if ($name) {
    $threads->{$pfno}->{name} = $name .' ';
    logit(&who ."$pfno rDNS $rdata[0]") unless $verbose < 3;
  } else {
    $threads->{$pfno}->{name} = '';
    logit(&who ."$pfno rDNS missing") unless $verbose < 3;
  }
  connOK($pfno) unless $threads->{$pfno}->{cok};		# log connection, continue
}

=head1 COPYRIGHT

Copyright 2004 - 2014, Michael Robinton <michael@bizsystems.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License (except as noted
otherwise in individuals sub modules)  published by
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

Michael Robinton <michael@bizsystems.com>

=head1 SEE ALSO

L<Mail::SpamCannibal> on CPAN or spamcannibal.org

=cut

1;
