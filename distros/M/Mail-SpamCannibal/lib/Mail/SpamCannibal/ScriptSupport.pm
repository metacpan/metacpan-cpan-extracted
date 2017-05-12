#!/usr/bin/perl
package Mail::SpamCannibal::ScriptSupport;

use strict;
#use diagnostics;
BEGIN {
  use vars qw($VERSION @ISA @EXPORT_OK $_scode $rblkbegin $rblkend);
  use IO::Socket::INET;

  $_scode = inet_aton('127.0.0.0');
}

$VERSION = do { my @r = (q$Revision: 0.59 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

use AutoLoader 'AUTOLOAD';

use File::SafeDO;
use IPTables::IPv4::DBTarpit::Tools;

use NetAddr::IP::Lite;
use Net::DNS::ToolKit qw(
	newhead
	gethead
	get16
	ttlAlpha2Num
	get_ns
);

use Net::DNS::ToolKit::Utilities 0.05 qw(
	rlook_send
	rlook_rcv
);

use Net::DNS::Codes qw(:all);

use Mail::SpamCannibal::ParseMessage qw(
	limitread
	dispose_of
	skiphead
	headers
	rfheaders
	get_MTAs
	firstremote
	array2string
	string2array
	trimmsg
);
use Mail::SpamCannibal::GoodPrivacy qw(
	decrypt
	is_pgp
);
use Mail::SpamCannibal::BDBclient qw(
	dataquery
);

use Mail::SpamCannibal::PidUtil qw(
	is_running
);

use Net::DNSBL::Utilities qw(
	list2hash
	write_stats
	bystat
	statinit
	cntinit
	A1271
	A1272
	A1273
	A1274
	A1275
	A1276
	A1277
	list_countries
);
*list2NetAddr = \&Net::DNSBL::Utilities::list2NetAddr;
*matchNetAddr = \&Net::DNSBL::Utilities::matchNetAddr;
*DO = \&File::SafeDO::DO;
*doINCLUDE = \&File::SafeDO::doINCLUDE;

require Net::DNS::ToolKit::Utilities;	# these subroutines have been moved to:
*id		= \&Net::DNS::ToolKit::Utilities::id;
*question	= \&Net::DNS::ToolKit::Utilities::question;
*revIP		= \&Net::DNS::ToolKit::Utilities::revIP;
*query		= \&Net::DNS::ToolKit::Utilities::query;
*dns_udpsend	= \&Net::DNS::ToolKit::Utilities::dns_udpsend;
*dns_udpresp	= \&Net::DNS::ToolKit::Utilities::dns_udpresp;
*dns_ans	= \&Net::DNS::ToolKit::Utilities::dns_ans;
*dns_ns		= \&Net::DNS::ToolKit::Utilities::dns_ns;
*dns_ptr	= \&Net::DNS::ToolKit::Utilities::dns_ptr;
*rlook_send	= \&Net::DNS::ToolKit::Utilities::rlook_send;
*rlook_rcv	= \&Net::DNS::ToolKit::Utilities::rlook_rcv;

use constant SerialEntry => $_scode;

*TarpitEntry = \&A1272;
*DNSBL_Entry = \&A1273;

require Exporter;
@ISA = qw(Exporter);

@EXPORT_OK = qw(
	DO
	doINCLUDE
	SerialEntry
	TarpitEntry
	DNSBL_Entry
	id
	question
	revIP   
	query   
	dns_udpsend
	dns_udpresp
	dns_ans 
	dns_ns
	dns_ptr
	rlook_send
	rlook_rcv
	zone_def
	valid127
	validIP
	zap_one
	zap_pair
	job_died
	dbjob_chk
	dbjob_kill
	dbjob_recover
	unpack_contrib
	lookupIP
	list2NetAddr
	matchNetAddr
	BLcheck
	BLpreen
	checkclct
	dumpIPs
	mailcheck
	abuse_host
	is_GENERIC
	block4zonedump
);

# autoload declarations

sub DESTROY {};

=head1 NAME

Mail::SpamCannibal::ScriptSupport - A collection of script helpers

=head1 SYNOPSIS

  use Mail::SpamCannibal::ScriptSupport qw(
	DO
	doINCLUDE
	SerialEntry
	TarpitEntry
	DNSBL_Entry
	id
	question
	revIP
	query
	dns_udpsend
	dns_udpresp
	dns_ans
	dns_ns
	dns_ptr
	rlook_send
	rlook_rcv
	zone_def
	valid127
	validIP
	zap_one
	zap_pair
	job_died
	dbjob_chk
	dbjob_kill
	dbjob_recover
	unpack_contrib
	lookupIP
	list2NetAddr
	matchNetAddr
	BLcheck
	checkclct
	dumpIPs
	BLpreen
	mailcheck
	abuse_host
	is_GENERIC
	block4zonedump
  );

=head1 FUNCTIONS

  $rv = DO($file,$nowarnings);
  $rv = doINCLUDE($file,$nowarnings);
  $packedIPaddr = SerialEntry()
  $packedIPaddr = TarpitEntry();
  $packedIPaddr = DNSBL_Entry();
  $unique = id($seed);
  $querybuf = question($name,$type);
  $rev = revIP($ip);
  $response = query(\$buffer,$timeout);
  $socket = dns_udpsend(\$buffer,$timeout);
  $response = dns_udpresp($socket,$timeout);
  ($aptr,$tptr,$auth_zone) = dns_ans(\$buffer);
  $nsptr = dns_ns(\$buffer);
  $hostname = dns_ptr(\$buffer);
  @hosts = dns_ptr(\$buffer);
  $socket = rlook_send($IP,$timeout);
  $hostname = rlook_rcv($socket,$timeout);
  ($expire,$error,$dnresp,$timeout)=zone_def($zone,\%dnsbl);
  $dotquad = valid127($dotquad);
  $dotquad = validIP($dotquad);
  $rv = job_died(\%jobstatus,$directory);
  $rv = dbjob_chk(\%default_config);
  dbjob_kill(\%default_config,$graceperiod);
  dbjob_recover(\%default_config);
  ($respip,$err,$blrsp,$exp,$zon)=unpack_contrib($record);
  ($which,$text)=lookupIP(\%config,$dotquadIP,$sockpath,$is_network);
  $rv=list2NetAddr(\@inlist,\@NAobject);
  $rv = matchNetAddr($ip,\@NAobject);
  $rv = BLcheck(\%DNSBL,\%default);
  $hashref = checkclct($DNSBL);
  $rv = dumpIPs($DNSBL, $allipsHASHptr);
  $rv = BLpreen(\%DNSBL,\%default);
  @err=mailcheck($fh,\%MAILFILTER,\%DNSBL,\%default,\@NAignor,\$spamsource)
  $rv=zap_one($tool,$netaddr,$db,$verbose,$comment);
  zap_pair($tool,$netaddr,$pri,$sec,$debug,$verbose,$comment);
  $rv = is_GENERIC($conf->{GENERIC},@hostnames);
  block4zonedump($environment);

=head1 METHODS

  $object = new Mail::Spamcannibal::ScriptSupport;
  $rv = $object->dns2rblz($line);
  $firstline = $object->rbldns_combined($type);
  $textline = $object->rbldns_compress($textline);
  $lastline = $object->rbldnst_done();
  $lastline = $object->rbldns_done();
  $last_combined = rbldns_address();

=head1 DESCRIPTION

B<Mail::SpamCannibal::ScriptSupport> provides a collection of support utilities 
for sc_BLcheck, sc_BLpreen, sc_mailfilter, sc_admin, sc_session, and
cannibal.cgi.

=over 4

=item * $rv = DO($file,$nowarnings);

Imported from File::SafeDO for legacy applications.

This is a fancy 'do file'. It first checks that the file exists and is
readable, then does a 'do file' to pull the variables and subroutines into
the current name space.

  input:	file/path/name
  returns:	last value in file
	    or	undef on error
	    prints warning

=item * $rv = doINCLUDE($file,$nowarnings);

Imported from File::SafeDO for legacy applications.

Similar to above but supports INCLUDE keys.

See: L<File::SafeDO>

=item * $packedIPaddr = SerialEntry();

Returns the packed internet address equivalent to inet_aton('127.0.0.0').
Make sure and use the parens at the end of the function.

=item * $packedIPaddr = TarpitEntry();

Returns the packed internet address equivalent to inet_aton('127.0.0.2').
Make sure and use the parens at the end of the function.

=item * $packedIPaddr = DNSBL_Entry();

Returns the packed internet address equivalent to inet_aton('127.0.0.3').
Make sure and use the parens at the end of the function.

=cut

# moved here from autoload section because of 8 character naming limitation
#
sub rbldns_combined {
  my($self,$type) = @_;
  return undef unless $type eq 'ip4set' or $type eq 'ip4tset';
  return '$DATASET '. $type .' @
';
}

my $_suppress_warnings = sub {	# during debug
  DNSBL_Entry();
  TarpitEntry();
  dns_udpresp();
  dns_udpsend();
  DO();
  do_INCLUDE();
  dns_ns();
};

1;
__END__

############################################
############################################

=item * ($expire,$error,$dnresp,$timeout)=zone_def($zone,\%dnsbl);

Parse the zone information and return either the default values or the
overides from the config file.

  Defaults:
	$expire	= '7d' 	# in seconds
	$error	= 'Blacklisted by: $zone'
	$dnresp	= inet_aton('127.0.0.3')
	$timeout  undef

NOTE: if the respone code found in the config file is not in the 127./8
block or is less than 127.0.0.3, $dnresp will be set to the default value.

=cut

sub zone_def {
  my ($zone,$zp) = @_;
  my $expire = $zp->{"$zone"}->{expire} || '7d';
  $expire = ttlAlpha2Num($expire);

  my $error = $zp->{"$zone"}->{error} || 'Blacklisted by: '.$zone;

  my $dnresp = inet_aton(valid127($zp->{"$zone"}->{response}));

  my $timeout = $zp->{"$zone"}->{timeout};

  return($expire,$error,$dnresp,$timeout);
}

=item * $dotquad = valid127($dotquad);

This function checks an IP address in dot quad notation to see if it is in
the range 127.0.0.3 to 127.255.255.255. It returns 127.0.0.3 if the IP
address is outside that range.

  input:	dot quad ip address
  returns:	input or 127.0.0.3

=cut

sub valid127 {
  my ($IP) = @_;
  return '127.0.0.3' unless $IP;
  $IP =~ s/\s//g;
  return '127.0.0.3' unless inet_aton($IP);

  unless ($rblkbegin) {	# fill object cache if empty
    $rblkbegin	= NetAddr::IP::Lite->new('127.0.0.3')->numeric();
    $rblkend	= NetAddr::IP::Lite->new('127.255.255.255')->numeric();
  }

  my $rcode = NetAddr::IP::Lite->new($IP)->numeric();
  return '127.0.0.3' if $rcode < $rblkbegin || $rcode > $rblkend;
  return $IP;
}

=item * $dotquad = validIP($dotquad);

This function inspects an IP address and returns it if is valid.

  input:	dot quad address
  returns:	dot quad address or undef

=cut

sub validIP {
  my ($IP) = @_;
  return undef unless $IP;
  $IP =~ s/\s//g;
  return undef unless $IP =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/;
  eval {return inet_ntoa(inet_aton($IP))};
}

=item * $rv=zap_one($tool,$netaddr,$db,$verbose,$comment);

Helper function to remove a record from one database. It conditionally
removes the record from $db. No removal is performed if $debug is
true, it is just "commented". Action or proposed action is commented if
$debug or $verbose is true.
$comment is appended to the standard "remove" message if $comment exists.

  input:	$tool,	  # ref to Tools
		$netaddr, # IP to remove
		$db,	  # database name
		$debug,	  # mode
		$verbose, # report intensity
		$comment,

  output:	1 on removal, 0 if no record removed

=cut

sub zap_one {
  my($tool,$netaddr,$db,$debug,$verbose,$comment) = @_;
  $comment = ($comment) ? ', '.$comment : '';
  if ($debug) {
    print "would remove$comment"
	if $tool->get($db,$netaddr);
  }
  else {
    $_ = $_ = $tool->remove($db,$netaddr);
    if (defined $_ && !$_) {	# if record was really removed
      $tool->sync($db);
      print "remove$comment"
	if $verbose;
      return 1;
    }
  }
  return 0;
}

=item * zap_pair($tool,$netaddr,$pri,$sec,$debug,$verbose,$comment);

Helper function for B<BLpreen>. It conditionally removes the records for
$netaddr from databases $pri and $sec. No removal is performed if $debug is
true, it is just "commented". Action or proposed action is commented if $debug or $verbose is true.
$comment is appended to the standard "remove" message if $comment exists.

  input:	$tool,	  # ref to Tools
		$netaddr, # IP to remove
		$pri,	  # database name
		$sec,	  # database name
		$debug,	  # mode
		$verbose, # report intensity
		$comment,

  output:	false on success, or
		an error message

=cut

# tack on ", comment" if DEBUG or VERBOSE and comment

sub zap_pair {
  my($tool,$key,$pri,$sec,$debug,$verbose,$comment) = @_;
  $comment = ($comment) ? ', '.$comment : '';
  if ($debug) {
    print "would remove${comment}";
    return;
  } elsif ($verbose) {
    print "remove${comment}";
  }
  unless ($tool->remove($pri,$key)) {
    $tool->sync($pri);
  }
  unless ($tool->remove($sec,$key)) {
    $tool->sync($sec);
  }
}

=item & $rv = job_died(\%jobstatus,$directory);

This function checks for pid files in the $directory. The absolute
pid file path is inserted into %jobstatus with a value of it's pid.
Tasks that are not running return a pid value of zero (0).

  input:	pointer to job status hash,
		pid file directory
  returns:	true if a task is not running
		else false

=cut

sub job_died {
  my($jsp, $dir) = @_;	# get job status pointer
  opendir(PIDS,$dir) || die "could not open DB $dir directory\n";
  my @pidfile = grep(/\.pid$/,readdir(PIDS));
  closedir PIDS;
  my $dead = 0;
  my $running;
  foreach(@pidfile) {
    unless ($running = is_running($dir .'/'. $_)) { # check for normal exit that has now removed it's pid file
      next unless -e $dir .'/'. $_;		    # ignore bogus entry
      $dead = 1;
    }
    $jsp->{$dir .'/'. $_} = $running;
  }
  return $dead;
}

=item * $rv = dbjob_chk(\%default_config);

This function checks if data base tasks have exited abnormally. If an abnormal exit
is detected, the file B<blockedBYwatcher> containing the watcher pid is created in the environment
directory and the function return false, otherwise it returns true.

  input:	pointer to db configuration,
  returns:	true if all known tasks are running
		or exited normally, else returns false

=cut

sub dbjob_chk {
  my($default) = @_;
  my %jobstatus;
  return 1 unless job_died(\%jobstatus,$default->{dbhome});

  open(BLOCKED,'>'. $default->{dbhome} .'/blockedBYwatcher');
  print BLOCKED $$,"\n";
  close BLOCKED;
  return 0;
}

=item * dbjob_kill(\%default_config,$graceperiod);

This function kills all db tasks that have registered PID files in the environment
directory. These jobs are shutdown, first with a SIG TERM and if they do not
respond withing the grace period, a SIG KILL.

  input:	pointer to db configuration,
		task shutdown grace period
  returns:	nothing

=cut

sub dbjob_kill {
  my($default,$gracep) = @_;
  $gracep = 3 unless $gracep > 2;
  my $signal = 15;			# kill signal is polite to begin with
  my %jobstatus;
  while ($gracep > 0) {
    %jobstatus = ();
    job_died(\%jobstatus,$default->{dbhome});	# get pid files of remaining jobs
    my %tmp = reverse %jobstatus;
    if ($tmp{$$}) {
      delete $jobstatus{$tmp{$$}};		# remove ME
    }
    last unless keys %jobstatus;
    foreach(keys %jobstatus) {
      next if $jobstatus{$_} == $$;	# skip me
      if ($jobstatus{$_}) {		# job running when checked
	kill $signal, $jobstatus{$_};
	no warnings;
	waitpid($jobstatus{$_},0);	# reap if the user was sloppy
      } else {
	unlink $_;		# remove pid files for dead jobs
      }
    }
    $gracep--;
    unless ($gracep > 2) {
      $signal = 9;		# on last try, kill forceably
    }
    sleep 1;
  }
}

=item * dbjob_recover(\%default_config);

This function destroys and reinstantiates the database environment. The file
B<blockedBYwatcher> is removed from the environment directory if it is
present. 

All DB tasks should be terminated prior to calling this function. 

DO NOT call this job for a DB environment that has not been initialized.

 usage: if(dbjob_chk(\%default_config) {
	  dbjob_kill(\%default_config,$graceperiod);
	  dbjob_recover(\%default_config);
	... restart db jobs
	}

  input:	pointer to db configuration,
  returns:	nothing

=cut

sub dbjob_recover {
  my($default) = @_;
# all jobs should be dead
# get the UID and GID for environment files
  die "directory $default->{dbhome} does not exist\n"
	unless -e $default->{dbhome} && -d $default->{dbhome};
  my $test = $default->{dbhome};
  if (exists $default->{dbfile} && 
	$default->{dbfile}->[0] &&
	-e $test .'/'. $default->{dbfile}->[0]) {
    $test .= '/'. $default->{dbfile}->[0];
  }
  elsif (exists $default->{txtfile} &&
	$default->{txtfile}->[0] &&
	-e $test .'/'. $default->{txtfile}->[0]) {
    $test .= '/'. $default->{txtfile}->[0];
  }
  my($mode,$uid,$gid) = (stat($test))[2,4,5];
  $mode &= 0777;
    
  my %local_default = %$default;
  $local_default{recover} = 1;
# recover the environment
  my $tool = new IPTables::IPv4::DBTarpit::Tools(%local_default);
  $tool->closedb;

# restore permissions
  opendir(ENVF,$default->{dbhome}) || die "could not open DB $default->{dbhome} directory\n";
  my @env = grep(/^__/,readdir(ENVF));
  closedir ENVF;
  foreach(@env) {
    chmod $mode, $default->{dbhome} .'/'. $_;
    chown $uid, $gid, $default->{dbhome} .'/'. $_;
  }

# it's now ok to restart jobs
  unlink $default->{dbhome} .'/blockedBYwatcher';	# remove the job block
}

=item * ($respip,$err,$blrsp,$exp,$zon)=unpack_contrib($record);

Unpack a 'blcontrib' record.

  input:	record from 'blcontrib' database
  output:	netaddr - our response code,
		our error message,
		netaddr - remote response code,
		expire
		dnsbl zone

This undoes pack("a4 x A* x a4 x N x A*",@_);

=cut

# pack("a4 x A* x a4 x N x A*",$dnresp,$error,$netA,$expire,$zon);

sub unpack_contrib {
  my ($ip,$rest) = unpack("a4 x a*",shift);
  my ($err,$rst2) = split(/\0/,$rest,2);
# using A* here instead of a*, strips everything after 'zon'
  my ($rsp,$exp,$zon) = unpack("a4 x N x A*",$rst2);
  return ($ip,$err,$rsp,$exp,$zon);
}

=item * ($which,$text)=lookupIP(\%config,$dotquadIP,$sockpath,$is_network);

This function checks the SpamCannibal databases for the
presence of an IP address and returns a text string describing why the IP address is in the
SpamCannibal data base or a descriptive not found message.

  input: (localhost)
		\%database config,
		dotquad IP address,
		/path/to/fifo,
		0,
	 (or remote host)
		\%database config,
		dotquad IP address,
		hostname:port,
		timeout seconds 

  returns:	which database,
		text string

	which = 0 for evidence
		1 for blcontrib

NOTE: the database config hash is the same as returned by Mail::SpamCannibal::SiteConfig

Text error return messages: message, meaning

invalid IP address, says it all
not found in system database, not in tarpit db
remote data record missing, found in contrib no text
no remote data record found, says it all

=cut

sub lookupIP {
  my($CONFIG,$dotquad,$sockpath,$timeout) = @_;
  $dotquad =~ s/\s//g;
  my $IP = inet_aton($dotquad);
  return (0,'invalid IP address')
	unless $IP;

  @_ = dataquery(0,$IP,$CONFIG->{SPMCNBL_DB_TARPIT},$sockpath,$timeout);
  return (0,$@) unless @_;

  my($key,$val) = @_;
  return (0,'not in '. $CONFIG->{SPMCNBL_DB_TARPIT} .' database') 
	if !$key || $key eq INADDR_NONE;

  @_ = dataquery(0,$IP,$CONFIG->{SPMCNBL_DB_EVIDENCE},$sockpath,$timeout);
  return (0,$@) unless @_;

  ($key,$val) = @_;
  if(!$key || $key eq INADDR_NONE || ! $val) {		# if not in 'evidence'
    @_ = dataquery(0,$IP,$CONFIG->{SPMCNBL_DB_CONTRIB},$sockpath,$timeout);
    return (1,$@) unless @_;
    ($key,$val) = @_;
    if ($key && $key ne INADDR_NONE && $val) { 		# if in contrib
      my($respip,$err,$blrsp,$exp,$zon)=unpack_contrib($val);
      $val = $err || 'remote data record missing';
    }
    else {						# else not in 'contrib'
      $val = 'no data record found';
    }
    return (1,$val);
  }
  else {
    return(0,$val);
  }
}

=item * $rv=list2NetAddr(\@inlist,\@NAobject);

Imported from Net::DNSBL::Utilities for legacy applications

Build of NetAddr object structure from a list of IPv4 addresses or address
ranges. This object is passed to B<matchNetAddr> to check if a given IP
address is contained in the list.

  input:	array reference pointer
		to a list of addresses

  i.e.		11.22.33.44
		11.22.33.0/24
		11.22.33.0/255.255.255.0
		11.22.33.20-11.22.33.46
		11.22.33.20 - 11.22.33.46

  output:	Number of objects created
		or undef on error

The NAobject array is filled with NetAddr::IP::Lite object references.

=item * $rv = matchNetAddr($ip,\@NAobject);

Imported from Net::DNSBL::Utilities for legacy applications

Check if an IP address appears in a list of NetAddr objects.

  input:	dot quad IP address,
		reference to NetAddr objects
  output:	true if match else false

=item * $rv = BLcheck(\%DNSBL,\%default);

This function checks the each IP address found in the 'archive' database
{SPMCNBL_DB_ARCHIVE} against the list of DNSBLs found in the
"sc_addspam.conf" configuration file. IP addresses which match the
acceptance criteria are added to the 'tarpit' database {SPMCNBL_DB_TARPIT}
and a corresponding entry is made in the 'blcontrib' database {SPMCNBL_DB_CONTRIB}
giving the reason for the addition.

  input:	config file hash ref,
		db config hash ref
  output:	false on success, or
		an error message

See: config/sc_BlackList.conf.sample for a detailed description of each
element in the configuration file. See: scripts/sc_BLcheck.pl for usage and
configuration information for the db config hash reference.

This routine will return if it catches a SIGTERM. The longest it will wait
is the timeout for a DNS query.

=cut

sub BLcheck {
  my($DNSBL,$default) = @_;
  my %count;
# extract vars
  my $DEBUG	= $default->{DEBUG} || 0;
  my $VERBOSE	= $default->{VERBOSE} || 0;
  my $tarpit	= $default->{dbfile}->[0];
  my $archive	= $default->{dbfile}->[1];
  my $contrib	= $default->{txtfile}->[0];
  my $evidence  = $default->{txtfile}->[1];

  my @NAignor;
  list2NetAddr($DNSBL->{IGNORE},\@NAignor)
	or return('missing IGNORE array in config file');

  my @NAblock;
  list2NetAddr($DNSBL->{BLOCK},\@NAblock);

  my $run = 1;
  local $SIG{TERM} = sub { $run = 0 };	# graceful exit;
	
  (my $tool = new IPTables::IPv4::DBTarpit::Tools(%$default))
	or return('could not open database environment, check your installation');

  my $numberoftries = 6;

  cntinit($DNSBL,\%count);

  my $allips = checkclct($DNSBL);		# set allips hash if we are collecting IP addresses

  my $generic = 0;
  if (exists $DNSBL->{GENERIC} && 'HASH' eq ref $DNSBL->{GENERIC}) {
    $generic = 1;
    $count{genericPTR} = 0;
  }

  my %deadDNSBL;
  foreach(keys %count) {
    next unless $_ =~ /\./;			# only real domains
    $deadDNSBL{$_} = $count{$_};
  }
  list2hash($DNSBL->{BBC},\%count);

  my($BBC,$cc2name) = _bbc($DNSBL);

# set up statistics file for DNSBL's if configured
  my $statinit = statinit($DNSBL->{STATS},\%count);
  my $stats = '';
  $stats = $DNSBL->{STATS} if $statinit;

  my $cursor = 1;		# carefull!! bdb starts with a cursor of 1, not zero
  my $key;
  Record:
  while ($run && ($key = $tool->getrecno($archive,$cursor))) {
# get each entry in the archive
    my $IP = inet_ntoa($key);
    if ($allips) {				# conditionally collect IP addresses
      if (exists $allips->{"$IP"}) {
	++$allips->{"$IP"};
      } else {
	$allips->{"$IP"} = 1;
      }
      print "Checking $IP " if $VERBOSE;
    }
    if (matchNetAddr($IP,\@NAignor)) {		# skip if ignored
      print "ignored " if $VERBOSE;
      $count{WhiteList} += 1;			# bump white list count
      next Record;
    }
    if ($tool->get($tarpit,$key)) {		# skip if it's already in tarpit
      print "in $tarpit " if $VERBOSE;
      next Record;
    }
    my $dnsblIP = revIP($IP);			# get the reversed IP address

    if (matchNetAddr($IP,\@NAblock)) {		# block if listed in reject list
      print 'BLOCK net-range ' if $VERBOSE;
      my $reason = 'blocked';
      my $error = $DNSBL->{REJECT} || 'in my bad address list';
      my $expire = 2592000;			# 30 day expiration
      my $zone = 'BlackList';
      my $ipA = '127.0.0.5';
      my $netA = A1275;
      my $dnresp = $netA;
      _addTPentry($tool,$reason,$error,$IP,$expire,\%count,$zone,$ipA,$dnresp,$tarpit,$netA,$key,$contrib,$DEBUG,$VERBOSE);
      next Record;
    }

    my $cc;
    if ($BBC && 
	($cc = $BBC->country_code_by_addr($IP)) &&
	grep($cc eq $_,@{$DNSBL->{BBC}})
	) { # block if Country not allowed
      my $reason = "$cc ($cc2name->{$cc}) rejected";
      print "blocked - $reason " if $VERBOSE;
      my $error = $DNSBL->{REJECT} || 'in my bad country list';
      my $expire = 2592000;			# 30 day expiration
      my $zone = $cc;
      my $ipA = '127.0.0.6';
      my $netA = A1276;
      my $dnresp = $netA;
      _addTPentry($tool,$reason,$error,$IP,$expire,\%count,$zone,$ipA,$dnresp,$tarpit,$netA,$key,$contrib,$DEBUG,$VERBOSE);
      next Record;
    }

# check in each available DNSBL until exhausted or entry is found
    my $zapped = 0;
   CheckZone:
    foreach my $zone (sort {$count{"$b"} <=> $count{"$a"}} keys %deadDNSBL) {
      last Record unless $run;			# SIGTERM ?
      next CheckZone if $deadDNSBL{"$zone"} > $numberoftries;
      my ($expire,$error,$dnresp,$timeout) = zone_def($zone,$DNSBL);
      print $zone,' ' if $VERBOSE;

      if ($zone eq 'in-addr.arpa') {
	my $qbuf = question($dnsblIP.'.in-addr.arpa',T_PTR());
	my $response = query(\$qbuf,$timeout);
	$deadDNSBL{"$zone"} = 0;		# unconditional
	next CheckZone
		if $response && scalar get16(\$response,6);	# check for good response and any ANSWER
# block for any response failure
	$dnresp = A1274;			# unconditional
	my $reason = ($response) ? 'no reverse DNS' : 'reverse DNS timeout';
	print "blocked - $reason " if $VERBOSE;
	my $ipA = '127.0.0.4';
	my $netA = $dnresp;
	_addTPentry($tool,$reason,$error,$IP,$expire,\%count,$zone,$ipA,$dnresp,$tarpit,$netA,$key,$contrib,$DEBUG,$VERBOSE);
	next Record;
      }
      my $qbuf = question($dnsblIP.'.'.$zone,T_ANY());
      my $response = query(\$qbuf,$timeout);
      if ($response && (@_ = dns_ans(\$response))) {
	$deadDNSBL{"$zone"} = 0;		# reset retry count
      } else {
	$deadDNSBL{"$zone"} += 1 if $@;		# increment retry count
	next CheckZone;
      }
# found an entry
      my ($aptr,$tptr) = @_;
# check the A records for acceptable codes until one is found
      my $netA;
      foreach $netA (@$aptr) {
	my $reason;
	my $ipA = inet_ntoa($netA);
	if (exists $DNSBL->{"$zone"}->{acceptany}) {
	  $reason = $DNSBL->{"$zone"}->{acceptany};
	  _CheckTxt(\$reason,$tptr);
	  _addTPentry($tool,$reason,$error,$IP,$expire,\%count,$zone,$ipA,$dnresp,$tarpit,$netA,$key,$contrib,$DEBUG,$VERBOSE);
	  $zapped = 1;
	  last CheckZone;
	} else {
	  foreach(keys %{$DNSBL->{"$zone"}->{accept}}) {
	    next unless ($_ eq $ipA);
  # found one, enter it in the tarpit
  # $netA contains the accepted code
  # find or create the TXT entry
	    $reason = $DNSBL->{"$zone"}->{accept}->{"$_"};
	    _CheckTxt(\$reason,$tptr);
	    _addTPentry($tool,$reason,$error,$IP,$expire,\%count,$zone,$ipA,$dnresp,$tarpit,$netA,$key,$contrib,$DEBUG,$VERBOSE);
	    $zapped = 1;
	    last CheckZone;
	  }
	}
      }
    } # CheckZone
    unless ($zapped) {
      if ($generic) {
	if ($DNSBL->{GENERIC}->{error}) {	# this entry should be made in 'blcontrib'
	  my ($expire,$error,$dnresp,$timeout) = zone_def('GENERIC',$DNSBL);
	  my $ipA = '127.0.0.7';
	  my $netA = A1277;
	  $dnresp = $netA;
	  my $reason = 'generic PTR reject';
	  my $zone = 'genericPTR';
# $IP and $key must be reconstituted by Xcidr routines
	  @_ = ($tool,$reason,$error,$IP,$expire,\%count,$zone,$ipA,$dnresp,$tarpit,$netA,$key,$contrib,$DEBUG,$VERBOSE);
	  $zapped = Xcidr24($tool,$tarpit,$evidence,$IP,$DNSBL->{GENERIC},\@_);
	} elsif (($zapped = Xcidr24($tool,$tarpit,$evidence,$IP,$DNSBL->{GENERIC})) > 0 ) {
	  $count{genericPTR} += 1;
	}
	if ($zapped > 0) {
	  $zapped = 1;
	} else {
	  $count{Passed} += 1;
	}
      } else {
        $count{Passed} += 1;
      }
    }
  } continue {
    print "\n" if $VERBOSE;
    if ($DEBUG) {
      $cursor++;
    } else {
# this will force renumbering of the cursor
      unless ($tool->remove($archive,$key)) {
	$tool->sync($archive);
      }
    }
  }

  if ($VERBOSE) {
    foreach(sort {
		bystat(\%count);
	} keys %count) {
      print $count{"$_"}, "\t$_\n";
    }
  }

  write_stats($stats,\%count,$statinit);
  $tool->closedb;
  if ($allips) {			# if tracking IP addresses, dump them to file
    my $rv = dumpIPs($DNSBL,$allips);
#    print STDERR "rv=$rv\n";
  }
  return '';
}

# return pointer to Geo::IP object and pointer to array of CC => names
#
# input:	$DNSBL
# returns:	BBC, \%cc2names

sub _bbc {
  my($DNSBL) = @_;
  return () unless ($DNSBL->{BBC} && ref $DNSBL->{BBC} eq 'ARRAY' && @{$DNSBL->{BBC}});
  require Geo::IP::PurePerl;
  my $BBC = new Geo::IP::PurePerl;
  my $cp = {};
  my($countries,$code3s,$names) = list_countries;
  no warnings;
  @{$cp}{@$countries} = @$names;
  my $caller = caller;
  bless $cp, $caller;
  return ($BBC,$cp);
}

# add a tarpit entry
#
# returns:	nothing
#
# $tool		pointer to db object
# $reason	something like 'rejected, China'
# $error	something like 'in my bad country list' or 'see: http://whatsit.com?ip='
# $IP		lookup 12.34.56.78
# $expire	time in seconds, typically 30 days or less
# $cp		\%count		statistics
# $zone		BBC, BLOCK, some.rbl.com
# $ipA		response from remote DNS in text
# $dnresp	our packed netaddr response
# $tarpit	DB pointer
# $netA		response from remote DNS - netaddr [inet_aton($ipA)]
# $key		netaddr $IP - address of interest  [inet_aton($IP)]
# $contrib	DB pointer

sub _addTPentry {
  my($tool,$reason,$error,$IP,$expire,$cp,$zone,$ipA,$dnresp,$tarpit,$netA,$key,$contrib,$DEBUG,$VERBOSE) = @_;
	  if ($reason =~ m|http://.+\..+| or $reason =~ /www\..+\..+/) {
	    $error = $reason;
	  } else {
	    $error .= $IP		# append IP address if ends in http query string
		if $error =~ /\?.+=$/ || $error =~ /\?$/;
	    $error = $reason .', '. $error
		if $reason;
	  }

	  $expire += time;		# absolute expiration time
	  $cp->{"$zone"} += 1 if exists $cp->{"$zone"};

# create a text record of the form:
# response_code."\0".error_message."\0".dnsbl_code."\0".expire."\0".zone."\0".host

	  if ($VERBOSE > 1) {
	    $_ =  qq|
zone => $zone response => $ipA
  record |. $IP .qq| => |. inet_ntoa($dnresp) . qq| $error
  timeout |. scalar localtime($expire) .q|

|;
	    print $_;

	  }
	  elsif ($VERBOSE) {
	    if ($DEBUG) {
	      print "would add to $tarpit";
	    } else {
	      print "added to $tarpit";
	    }
	  }

	  unless ($DEBUG) {
	    $_ = pack("a4 x A* x a4 x N x A*",$dnresp,$error,$netA,$expire,$zone);
	    unless ($tool->put($contrib,$key,$_)) {
	      $tool->sync($contrib);
	      unless (	$tool->touch($tarpit,$key) ||		# add the tarpit entry
			$tool->touch($tarpit,SerialEntry())) {	# and update the serial number
		$tool->sync($tarpit);
	      }
	    }
	  }
}

=item * $hashref = checkclct($DNSBL);

Return undef or a hashref for collecting IP's.

  input:	config file hash ref
  output:	IP collection hash ref

Used by BLcheck

=cut

sub checkclct {
  my $DNSBL = shift;
  return undef unless exists $DNSBL->{ALLIPS};
  my $allips;
  if ($DNSBL->{ALLIPS} && -e $DNSBL->{ALLIPS}) {
    $allips = doINCLUDE($DNSBL->{ALLIPS});
  }
  $allips = {} unless $allips;
  my $caller = caller;
  return $allips;
}

=item * $rv = dumpIPs($DNSBL, $allipsHASHptr);

Dump the %allips hash in a Data::Dumper compatible format
to the file pointed to by 'ALLIPS' in config.

  input:	config pointer,
		pointer to ALLIPS hash
  returns:	false on success or error message

Used by BLcheck

=cut

sub dumpIPs {
  my($DNSBL,$allips) = @_;
  return 'allips does not exist or is not a HASH'
	unless $allips && ref $allips eq 'HASH';
  return 'no output file specified'
	unless exists $DNSBL->{ALLIPS};
  local *IPS;
  my $file = $DNSBL->{ALLIPS} .'.tmp';
  return "could not open $file for write"
	unless $DNSBL->{ALLIPS} &&
	open(IPS,'>'. $file);
  my $count = @_ = sort keys %$allips;
  $_ = q|#
# last updated |. (scalar localtime()) . q|
# |. $count .q| IP addresses
#
my $allips = {
|;
  print IPS $_;
  foreach(@_) {
    print IPS "\t'$_'\t=> ", $allips->{"$_"}, ",\n";
  }
  print IPS '};
';
  close IPS;
  rename $file, $DNSBL->{ALLIPS};	# atomic move
  return undef;
}


=item * $rv = BLpreen(\%DNSBL,\%default);

This function validates each IP address found in the 'blcontrib' database
{SPMCNBL_DB_CONTRIB} for presence of its original dnsbl zone entry in the
configuration file and that the remote dnsbl still has an acceptable 'A'
record. IP addresses which fail either of these criteria or for which the
remote dnsbl does not respond for the 'expire' interval (see
sc_addspam.conf) are removed from the 'tarpit' database {SPMCNBL_DB_TARPIT}
as well as the 'blcontrib' database {SPMCNBL_DB_CONTRIB}. 'contrib' items 
found in the 'evidence' are unconditionally discarded instead of being checked.

  input:	config file hash ref,
		db config hash ref
  output:	false on success, or
		an error message

See: config/sc_BlackList.conf.sample for a detailed description of each
element in the configuration file. See: scripts/sc_BLpreen.pl for usage and
configuration information for the db config hash reference.

This routine will return if it catches a SIGTERM. The longest it will wait is
the timeout interval for a DNS query.

=cut

# check for text records and update reason as required
#
# input:	\$reason, $tptr
# returns:	nothing
#

sub _CheckTxt {
  my($rptr,$tptr) = @_;
CheckTxt:
  while(1) {
    last CheckTxt unless @$tptr;
    if (grep($_ =~ /spam/i,@$tptr)) {
      foreach (@$tptr) {
	next unless $_ =~ /spam/i;
	$$rptr = $_;
	last CheckTxt;
      }
    } elsif (grep($_ =~ /smtp/i,@$tptr)) {
      foreach (@$tptr) {
	next unless $_ =~ /smtp/i;
	$$rptr = $_;
	last CheckTxt;
      }
    } else {
      $$rptr = $tptr->[0];
    }
    last CheckTxt;
  }
}

sub BLpreen {
  my($DNSBL,$default) = @_;

# extract vars
  my $DEBUG	= $default->{DEBUG} || 0;
  my $VERBOSE	= $default->{VERBOSE} || 0;
  my $tarpit	= $default->{dbfile}->[0];
  my $contrib	= $default->{txtfile}->[0];
  my $evidence	= $default->{txtfile}->[1];

  my $localnet = new NetAddr::IP::Lite('127.0.0.0','255.0.0.0');
  my @NAignor;
  list2NetAddr($DNSBL->{IGNORE},\@NAignor)
	or return('missing IGNORE array in config file');

  my @NAblock;
  list2NetAddr($DNSBL->{BLOCK},\@NAblock);

  my($BBC,$cc2name) = _bbc($DNSBL);

  my $run = 1;
  local $SIG{TERM} = sub { $run = 0 };  # graceful exit;

  (my $tool = new IPTables::IPv4::DBTarpit::Tools(%$default))
	or return('could not open database environment, check your installation');

  my $now = time;					# time of this preen
  my $last_preen = $tool->get($tarpit,A1272());		# last preen time
  my $no_preen = 0;
  if ($last_preen) {
    $no_preen = ($now - $last_preen) * 5;		# the number of preen intervals to check before ignoring item
    $no_preen = 86400					# minimum one day
	unless $no_preen > 86400;
    $no_preen = 0					# force preen
	if exists $DNSBL->{FORCE_PREEN} &&		# if configured that way
		  $DNSBL->{FORCE_PREEN};
  }

  my($regexptr,$iptr) = _chkgenhash($DNSBL->{GENERIC});	# get generic stuff if present


  $tool->{SS_BLpreen_cache} = {		# cache for write back operations
	limit	=>	100,		# size of cache
	cache	=>	{},		# value cache
  };

  my $numberoftries = 6;		# number of DNSBL attempts before marking as failed

  my %deadDNSBL;
  foreach(keys %$DNSBL) {
    $deadDNSBL{"$_"} = ($_ =~ /.+\..+/)	# skip non-dnsbl entries
	? 1
	: $numberoftries + 1	# big... to force skip
  }

  list2hash($DNSBL->{BBC},\%deadDNSBL,1);	# set countries to count of one
  $deadDNSBL{BLOCK} = 1;
  $deadDNSBL{BBC} = 1;

  my $cursor = 1;		# carefull!! bdb starts with a cursor of 1, not zero

  $now = time;
  my ($key,$validate,$zapped);
  Record:
  while ($run && (@_ = $tool->getrecno($contrib,$cursor))) {
    $zapped = 0;
    $validate = 0;
# get each entry in the contrib database
    my($key,$data) = @_;
    my $IP = inet_ntoa($key);
    print "$IP " if $VERBOSE;
    if (new NetAddr::IP::Lite($IP)->within($localnet)) {	# ignore 127.x.x.x addresses
      print 'skipping...' if $VERBOSE;
      next Record;
    }
    my $last_access;					# last tarpit access time
    unless ($last_access = $tool->get($tarpit,$key)) {	# remove if not in tarpit
      zap_pair($tool,$key,$tarpit,$contrib,$DEBUG,$VERBOSE,"not in $tarpit");
      $zapped = 1;
      next Record;
    }
    my $age = $now - $last_access;
    if ($no_preen && 
	$age > $no_preen				# if this is an old tarpit record
    ) {
      if (($age % 2592000) < 86400) {			# check old records at least once every 30 days
	print 'check old record every 30 days' if $VERBOSE;
      } else {
	print 'skip old record' if $VERBOSE;
	next Record;				# skip it until it checks in
      }
    }
    if (matchNetAddr($IP,\@NAignor)) {		# remove if in ignore database
      zap_pair($tool,$key,$tarpit,$contrib,$DEBUG,$VERBOSE,'ignore');
      $zapped = 2;
      next Record;
    }
    if ($tool->get($evidence,$key)) {		# if it's in the evidence file, zap it here
      zap_one($tool,$key,$contrib,$DEBUG,$VERBOSE,"is in $evidence");
      $zapped = 3;
      next Record;
    }
    my $dnsblIP = revIP($IP);			# get the reversed IP address
    my($orsp,$err,$trsp,$exp,$zon)=unpack_contrib($data);
    print $zon, ' ' if $VERBOSE;
    $zon = 'genericPTR' if $zon eq 'ONLY_COUNT_ONE';
    my $zn = $zon eq 'genericPTR' ? 'GENERIC' : $zon;

    if (! ($orsp eq A1276 && $zon =~ /^[A-Z0-9]{2}$/) &&	# not a country
	! exists $DNSBL->{"$zn"}				# zone has been removed from config
	) {		

#    unless (exists $DNSBL->{"$zon"}) {			# zone has been removed from config
      zap_pair($tool,$key,$tarpit,$contrib,$DEBUG,$VERBOSE,'zone not in config');
      $zapped = 4;
      next Record
    }
    if (exists $deadDNSBL{"$zon"} && $deadDNSBL{"$zon"} > $numberoftries) {
      if ($exp < $now) {
	zap_pair($tool,$key,$tarpit,$contrib,$DEBUG,$VERBOSE,'expired (4)');
	$zapped = 5;
      }
      next Record;
    }
# get current zone info from config file
    my ($expire,$error,$dnresp,$timeout);
    if ($zon =~ /.+\..+/ ) {
      ($expire,$error,$dnresp,$timeout) = zone_def($zon,$DNSBL);
    } elsif ($zon eq 'genericPTR') {
      ($expire,$error,$dnresp,$timeout) = zone_def('GENERIC',$DNSBL);
    }

# BLOCKED?
    if ($zon eq 'BLOCK') {			# check unconditional block
      if (matchNetAddr($IP,\@NAblock)) {
	$validate = 1;
	my $reason = 'blocked';
	my $error = $DNSBL->{REJECT} || 'in my bad address list';
	my $expire = 2592000;			# 30 day expiration
	my $ipA = '127.0.0.5';
	my $netA = A1275;
	my $dnresp = $netA;
	_updateTpentry($tool,$reason,$error,$IP,$expire,$ipA,$dnresp,$netA,$zon,$contrib,$key,$tarpit,$DEBUG,$VERBOSE);
      } else {
	$zapped = 'no longer BLOCKed';
      }
    }

# Country Code is two characters and response of 127.0.0.6
    elsif ($orsp eq A1276 && $zon =~ /^[A-Z0-9]{2}$/) {	# check Country Code Block
      if ($BBC &&
	  $zon eq $BBC->country_code_by_addr($IP) &&
	  grep($zon eq $_,@{$DNSBL->{BBC}})) {
	$validate = 1;
       	my $reason = "$zon ($cc2name->{$zon}) rejected";
	my $error = $DNSBL->{REJECT} || 'in my bad country list';
	my $expire = 2592000;			# 30 day expiration
	my $ipA = '127.0.0.6';
	my $netA = A1276;
	my $dnresp = $netA;
	_updateTpentry($tool,$reason,$error,$IP,$expire,$ipA,$dnresp,$netA,$zon,$contrib,$key,$tarpit,$DEBUG,$VERBOSE);
      } else {
	$zapped = "unblocked $zon ($cc2name->{$zon})";
      }
    }

# Reverse DNS
    elsif ($zon eq 'in-addr.arpa') {
      my $qbuf = question($dnsblIP.'.in-addr.arpa',T_PTR());
      my $response = query(\$qbuf,$timeout);
      $deadDNSBL{"$zon"} = 0;		# unconditional
      if ($response && scalar get16(\$response,6)) {	# good response and any ANSWER
	$zapped = 'reverse DNS OK';
      } else {
# block for any response failure
	$validate = 1;
	$dnresp = A1274;			# unconditional
	my $reason = ($response) ? 'no reverse DNS' : 'reverse DNS timeout';
	my $ipA = '127.0.0.4';
	my $netA = $dnresp;
	_updateTpentry($tool,$reason,$error,$IP,$expire,$ipA,$dnresp,$netA,$zon,$contrib,$key,$tarpit,$DEBUG,$VERBOSE);
      }
    }
# GENERIC PTR record
    elsif ($zon eq 'genericPTR') {
      unless ($regexptr) {
	$zapped = 'generic zone removed';
	zap_pair($tool,$key,$tarpit,$contrib,$DEBUG,$VERBOSE,'GENERIC removed');
	next Record;
      }
      my $qbuf = question($dnsblIP.'.in-addr.arpa',T_PTR());
      my $response = query(\$qbuf,$timeout);
      if ($response) {				# possible to remove if response
	my @hosts = dns_ptr(\$response);
	my $flag = 0;
	foreach my $name (@hosts) {
	  if ($iptr && grep($name =~ /$_/i,@$iptr)) {			# skip if regexp is to be ignored
	    $flag = 1;
	    last;
	  }
          if ($name && ! grep($name =~ /$_/i, @$regexptr)) {
	    $flag = 1;
	    last;
	  }
	}
	if ($flag) {
	  $zapped = 'GENERIC cleared';
	  zap_pair($tool,$key,$tarpit,$contrib,$DEBUG,$VERBOSE,'GENERIC cleared');
	  next Record;
	}
      }
      $validate = 1;
      $dnresp = A1277;
      my $ipA = '127.0.0.4';
      my $netA = $dnresp;
      my $reason = 'generic PTR reject';
      _updateTpentry($tool,$reason,$error,$IP,$expire,$ipA,$dnresp,$netA,$zon,$contrib,$key,$tarpit,$DEBUG,$VERBOSE);
    }
# Regular DNSBL
    else {					# check DNSBL zone

      $zapped = 'unacceptable A record';	# trial value, cleared if validated below
      my $qbuf = question($dnsblIP.'.'.$zon,T_ANY);
      my $response = query(\$qbuf,$timeout);
      my ($aptr,$tptr,$auth_zone) = dns_ans(\$response);

      if ($@) {				# catastrophic failure
        $deadDNSBL{"$zon"} += 1;		# bump the retry count
        if ($exp < $now) {		# and zap record if expired
	  zap_pair($tool,$key,$tarpit,$contrib,$DEBUG,$VERBOSE,'expired (5)');
	  $zapped = 6;
        }
        next Record;
      }
      if ($response) {			# process exclusions
        $deadDNSBL{"$zon"} = 0 		# reset retry count
	  if $aptr && (@$aptr || $auth_zone eq $zon);

# if no A records and the zone is authoriatitive or 
# it answers and no SOA is present i.e. the zone exists -- like spamcop
        if (!($aptr && @$aptr) && (! $auth_zone || $auth_zone eq $zon)) {
	  zap_pair($tool,$key,$tarpit,$contrib,$DEBUG,$VERBOSE,'cleared');
	  $zapped = 7;
	  next Record;
        }
      } else {		# no response
        if ($exp < $now) {
	  zap_pair($tool,$key,$tarpit,$contrib,$DEBUG,$VERBOSE,'expired (7)');
	  $zapped = 8;
        }
        next Record;
      }
# found an entry
      next Record unless @$aptr;			# skip if no 'A' records
# check the A records for acceptable codes until one is found
      my $netA;
    CheckZone:
      foreach $netA (@$aptr) {
        my $ipA = inet_ntoa($netA);
	my $reason;
	if (exists $DNSBL->{"$zon"}->{acceptany}) {
	  $reason = $DNSBL->{"$zon"}->{acceptany};
	  $validate = 1;
	  _CheckTxt(\$reason,$tptr);
	  last CheckZone
	    if _updateTpentry($tool,$reason,$error,$IP,$expire,$ipA,$dnresp,$netA,$zon,$contrib,$key,$tarpit,$DEBUG,$VERBOSE);
        } else {
	  foreach(keys %{$DNSBL->{"$zon"}->{accept}}) {
	    next unless ($_ eq $ipA);
  # found one, enter it in the tarpit
  # $netA contains the accepted code
  # find or create the TXT entry
	    $validate = 1;
	    $reason = $DNSBL->{"$zon"}->{accept}->{"$_"};
	    _CheckTxt(\$reason,$tptr);
	    last CheckZone
	      if _updateTpentry($tool,$reason,$error,$IP,$expire,$ipA,$dnresp,$netA,$zon,$contrib,$key,$tarpit,$DEBUG,$VERBOSE);
	  }
        }
      } # end CheckZone
    }
    if ($validate) {
      $zapped = 0;
    } else {
      zap_pair($tool,$key,$tarpit,$contrib,$DEBUG,$VERBOSE,$zapped);
    }
  } continue {
    print "\n" if $VERBOSE;
    if ($DEBUG) {
      $cursor++;
    } elsif ( ! $zapped) {
      $cursor++;
    }
  }
  _flush_BLp_cache($tool,$tarpit,$contrib);	# flush any remaining cached values
  $tool->touch($tarpit,A1272(),$now);		# update last preen time
  $tool->closedb;
  return '';
}

# update a tarpit entry time tag
#
# returns:	true if last CheckZone required, else false
#
# $tool		pointer to db object
# $reason	something like 'rejected, China'
# $error	something like 'in my bad country list' or 'see: http://whatsit.com?ip='
# $IP		lookup 12.34.56.78
# $expire	time in seconds, typically 30 days or less
# $ipA		response from remote DNS in text
# $dnresp	our packed netaddr response
# $netA		response from remote DNS - netaddr [inet_aton($ipA)]
# $zon		BBC, BLOCK, some.rbl.com
# $contrib	DB pointer
# $key		netaddr $IP - address of interest  [inet_aton($IP)]
# $tarpit	DB pointer
#
# if $tool carries the SS_BLpreen_cache key, use caching for updates
# otherwise, write the values directly to the database
#
sub _updateTpentry {
  my($tool,$reason,$error,$IP,$expire,$ipA,$dnresp,$netA,$zon,$contrib,$key,$tarpit,$DEBUG,$VERBOSE) = @_;
	if ($reason =~ m|http://.+\..+| or $reason =~ /www\..+\..+/) {
	  $error = $reason;
	} else {
	  $error .= $IP		# append IP address if ends in http query string
		if $error =~ /\?.+=$/;
	  $error = $reason .', '. $error
		if $reason;
	}

	$expire += time;		# absolute expiration time
# create a text record of the form:
# response_code."\0".error_message."\0".dnsbl_code."\0".expire."\0".zone."\0".host

	if ($VERBOSE > 1) {
	  $_ =  qq|
zone response => $ipA
  record |. $IP .qq| => |. inet_ntoa($dnresp) . qq| $error
  timeout |. scalar localtime($expire) .q|

|;
	  print $_;

	}
	elsif ($VERBOSE) {
	  if ($DEBUG) {
	    print "would validate ";
	  } else {
	    print "validated ";
	  }
	}

	my $cz = 0;
	unless ($DEBUG) {
	  $_ = pack("a4 x A* x a4 x N x A*",$dnresp,$error,$netA,$expire,$zon);
	  if (exists $tool->{SS_BLpreen_cache}) {
	    $tool->{SS_BLpreen_cache}->{cache}->{$key} = $_;
	    unless (keys %{$tool->{SS_BLpreen_cache}->{cache}} < $tool->{SS_BLpreen_cache}->{limit}) {
	      _flush_BLp_cache($tool,$tarpit,$contrib);
	    }
	  }
	  else {
	    unless ($tool->put($contrib,$key,$_)) {
	      $tool->sync($contrib);
	      unless ($tool->touch($tarpit,SerialEntry())) {	# and update the serial number
	        $tool->sync($tarpit);
	      }
	    }
	  }


	  $cz = 1;	# last CheckZone;
	}
	return $cz;
}

sub _flush_BLp_cache {
  my($tool,$tarpit,$contrib) = @_;
  return unless (@_ = sort keys %{$tool->{SS_BLpreen_cache}->{cache}});
  my $nosync;
  foreach(@_) {
    last if ($nosync = $tool->put($contrib,$_,$tool->{SS_BLpreen_cache}->{cache}->{$_}));	# exit loop if failure
  }
  %{$tool->{SS_BLpreen_cache}->{cache}} = ();		# destroy old cache
  unless ($nosync) {
    $tool->sync($contrib);				# flush contrib db to file
    unless ($tool->touch($tarpit,SerialEntry())) {	# and update the serial number
      $tool->sync($tarpit);
    }
  }
}

=item * @err=mailcheck($fh,\%MAILFILTER,\%DNSBL,\%default,\@NAignor,\$spamrcd)

This function extracts the sending mail server address, headers, and message
content from an "email message" that may [optionally] be PGP encoded. If an
IP address is successfully recovered, it is added to the 'tarpit' database
{SPMCNBL_DB_TARPIT} and the headers and message are added to the 'evidence'
database {SPMCNBL_DB_EVIDENCE}. See: config/sc_mailfilter.conf.sample for
configuration and details on optional settings.

  input:	file handle,
		config hash ptr,
		dnsbl config hash ptr,
		default config hash ptr,
		net object ptr,
		[optional] spam info array pointer 
  output:	empty array on success,
		(verbosity, err msg) on failure
	where verbosity is false on success,
	1,2,3, etc.... on failure

  my %default = (
	dbhome  => $environment,
	dbfile  => [$tarpit],
	txtfile => [$evidence],
	DEBUG   => $DEBUG,
	LIMIT   => $CHAR_SAVE_LIMIT, # characters
	PGPLIM	=> $CHAR_READ_LIMIT,
  );

  [optional] spam info array pointer
  $spamip = ['spam source name or ip','spam headers + message']
  This array will be filled by mail check if it is present

=cut

sub mailcheck {
  my($fh,$MAILFILTER,$DNSBL,$default,$NAignor,$spamip) = @_;

  my $tarpit	= $default->{dbfile}->[0];
  my $archive	= $default->{dbfile}->[1];
  my $evidence	= $default->{txtfile}->[0];

# if optional bad guy pointer is present, clear it first
  if ($spamip && ref $spamip eq 'ARRAY') {
    @$spamip = ();
  } else {
    $spamip = undef;
  }
  my $spamsav;

# read up to 10,000 characters
  my $savlim	= $default->{LIMIT} || 10000;	# internal default is 1000
  my $readlim	= $default->{PGPLIM} || 5 * $savlim;
  my @lines;
  return (1,'no lines read')
	unless limitread($fh,\@lines,$readlim);

# close incomming connection
  dispose_of($fh);

  return(3,"startup blocked by DB watcher process")
	if -e $default->{dbhome} .'/'. 'blockedBYwatcher';

# skip the headers from local client
  my @discard;
  return (1,'no message found')
	unless skiphead(\@lines,\@discard);

# return if 'magic' header required and not found
  if (exists $MAILFILTER->{REQHEAD}) {
    my @headkeys;
    if (ref $MAILFILTER->{REQHEAD} && ref $MAILFILTER->{REQHEAD} eq 'ARRAY') {
      @headkeys = @{$MAILFILTER->{REQHEAD}};
    } elsif ($MAILFILTER->{REQHEAD}) {
      push @headkeys, $MAILFILTER->{REQHEAD}
    }
    my $match = 0;
    if (@headkeys) {		# check for matching header if header required
      my $match = 0;
    MATCH:
      foreach my $header (@headkeys) {
	if (grep($_ =~ /^$header/i,@discard)) {
	  $match = 1;
	  last MATCH;
	}
      }
      unless ($match) {
	@_ = (@discard, @lines);
	my $err = "Subject: matching header not found\n\n". array2string(\@_);
	return(2,$err);
      }
    }
  }

# find "to:" so that we can determine if MAXMSG should be ignored
  my $to;
  foreach(@discard) {
    if ($_ =~ /to:\s*[<]?(.+)@.+[>]?\s*/i) {
      $to = $1;
      delete $MAILFILTER->{MAXMSG}	# ignore MAXMSG if dest address ends in "x"
	if $to =~ /x$/i;
      last;
    }
  }

# decrypt if Good Privacy
  my $err;

  while ($MAILFILTER->{PGP} && ref $MAILFILTER->{PGP} eq 'HASH') {
    my ($beg,$end) = is_pgp(\@lines,\$err);
    last if $err;

    $MAILFILTER->{PGP}->{Data} = array2string(\@lines,$beg,$end);
    my $plaintext = decrypt($MAILFILTER->{PGP});
    $MAILFILTER->{PGP}->{Data} = '';
    unless ($plaintext) {			# could not decode
      $err = 'could not decode PGP';
      last;
    }
    unless (string2array($plaintext,\@lines)) {
      $err = 'no plaintext 2 lines';
      last;
    }
    last;
  }
  if ($err) {
    if ($MAILFILTER->{PGP}->{Exceptions}) {
      @_ = (@discard, @lines);
      $err = 'Subject: '. $err ."\n\n". array2string(\@_);
      return(2,$err);
    } else {
      return(1,$err);
    }
  }

#  undef @discard;

# save spam for later use
  $spamsav = array2string(\@lines);
 
# extract headers
  my @headers;
#  if ($MAILFILTER->{DIRTY}) {
#    return (1,'no dirty headers')
#	unless rfheaders(\@lines,\@headers);
#  } else {
#    return (1,'no headers')
#	unless headers(\@lines,\@headers);
#  }

  my $hr;			# header result
  if ($MAILFILTER->{DIRTY}) {
    $hr = rfheaders(\@lines,\@headers)
	? 0
	: 'Subject: no dirty headers';
  } else {
    $hr = headers(\@lines,\@headers)
	? 0
	: 'Subject: no headers';
  }
  if ($hr) {
    push @discard, @lines;
    return (1,$hr ."\n\n". array2string(\@discard));
  }

# extract MTA's
  my @mtas;
  return (1,'no MTAs found')
	unless get_MTAs(\@headers,\@mtas);

# extract bad guy address
  my $noprivate = ($MAILFILTER->{NOPRIVATE})
	? 1 : 0;
  my $spamsource = $$spamsp = firstremote(\@mtas,$MAILFILTER->{MXhosts},$noprivate);
  return (1,'no spam source found')
	unless $spamsource;

# punt if this address should be ignored
  return (1,'spam source ignored')
	if matchNetAddr($spamsource,$NAignor);

# trim message length if required
  my $end = trimmsg($MAILFILTER,\@lines);

# stringify headers and message
  my $spam;
  return (1,'no evidence found')
	unless ($spam = array2string(\@lines,0,$end));	# punt if no message

  $spam = substr($spam,0,$savlim)
	if length($spam) > $savlim;
# tarpit this host address
  my @err;
  if ($default->{DEBUG}) {
    return (2,"Subject: $spamsource would add to $tarpit\n\n$spam");
  } else {
    (my $tool = new IPTables::IPv4::DBTarpit::Tools(%$default))
	or return(1,'could not open database environment, check your installation');
    my $netaddr = inet_aton($spamsource);  
    if ($archive && 
	! $tool->get($archive,$netaddr)) {
      $tool->closedb;
      return (2,"Subject: $spamsource not in 'archive'\n\n$evidence");
    }
    unless ($tool->put($evidence,$netaddr,$spam)) {
      $tool->sync($evidence);
      unless ($tool->touch($tarpit,$netaddr) ||	# add the tarpit entry
	  $tool->touch($tarpit,SerialEntry())) {	# and update the serial number
	$tool->sync($tarpit);
      }
    }
    if (exists $MAILFILTER->{XCIDR24}) {
      my $count = Xcidr24($tool,$tarpit,$evidence,$spamsource,$MAILFILTER->{XCIDR24},undef,1); # should have updated evidence above
      @err = ($count < 0) 
	? (3,'could not open socket for rdns lookup')
	: ();
    }
    $tool->closedb;
  }
  if ($spamip) {	# if reporting desired
    @$spamip = ($spamsource,$spamsav);
  }
  return @err;
}

#=item * $cnt=Xcidr24($tool,$tarpit,$evidence,$ipaddr,$confptr,\@_addTarry);
#
#Called from 'mailcheck' and 'BLcheck'
#
#Test each record in the /24 represented by $ipaddr for missing PTR or
#a match to any item in the regex array
#
# If the pointer record is missing, the text:
#	no reverse DNS, MX host should have rDNS - RFC1912 2.1
# will mark the record
#
#For a match to the forbidden regexp, $string will mark the record
#
#See the configuration files sc_mailcheck.conf and sc_mailfilter.conf
#for further details on the configuration parameters
#
#  input:	database tool pointer,
#		tarpit db name,
#		evidence db name,
#		dot quad IP address
#		ptr to config array
#	(see sc_mailcheck.conf XCIDR24
#	 and sc_BLcheck.conf GENERIC)
#		undef for mail check or _addTpentry array ptr
#					for BLcheck
#		evidence just entered T/F (from mailcheck)
#
#  returns:	number of records entered in DB
#		negative = error
#		'could not open socket for rdns lookup'
#
#=cut

# pattern for ip address's of the form n+?n+?n+?n+ or 12 n's
# as in 1.2.3.4 => 001002003004
#
#my $ipattern = '\d+[a-zA-Z_\-\.]\d+[a-zA-Z_\-\.]\d+[a-zA-Z_\-\.]\d+|\d{12}';

# returns:	false	=> does not match regexp
#		true	=> string to insert in DB
sub _xcidrev {
  my($sock,$get,$put,$sadr,$name,$str,$regexptr,$iptr) = @_;
  my($buffer,$response);
  my $bp = \$buffer;
  my $offset = newhead($bp,
	id(),
	BITS_QUERY | RD,
	1,0,0,0,
  );
  $offset = $put->Question($bp,$offset,$name,T_PTR,C_IN);
  my $retry = 1;
  while ($retry-- > 0) {
    eval {
	local $SIG{ALRM} = sub {die "timeout"};
	alarm 10;			# 10 second timeout
	my $wrote = syswrite $sock, $buffer, $offset;
	my $urcv;
	die "failed to get UDP message" unless
		defined ($urcv = sysread($sock, $response, NS_PACKETSZ));
	alarm 0;
    };
    last unless $@;
  }
  if ($@) {
    return '';			# ignore DNS that does not answer... bad connection, to aggressive
  } else {
    $bp = \$response;
    my ($newoff,$id,$qr,$opcode,$aa,$tc,$rd,$ra,$mbz,$ad,$cd,$rcode,
	$qdcount,$ancount,$nscount,$arcount)
	= gethead($bp);
#print RcodeTxt->{$rcode},"\n";
    if ($rcode == NXDOMAIN || $rcode == SERVFAIL) {
      return 'no reverse DNS, MX host should have rDNS - RFC1912 2.1';
    }
    next if ($rcode != NOERROR);
    my($type,$class,$ttl,$rdlength,@rdata);
    foreach(0..$qdcount -1) {
      ($newoff,$name,$type,$class) = $get->Question($bp,$newoff);	# waste question
    }
    my @names;
    foreach(0..$ancount -1) {
      ($newoff, $name,$type,$class,$ttl,$rdlength,@rdata) = $get->next($bp,$newoff);
#print "$rdata[0]\n";
      return '' if $iptr && grep($rdata[0] =~ /$_/i,@$iptr);		# skip regexp if an ignored name
      return '' if $rdata[0] && ! grep($rdata[0] =~ /$_/i, @$regexptr);
    }
    return $str;
  }
}

sub Xcidr24 {
  my($tool,$tarpit,$evidence,$addr,$gptr,$aTptr,$mc_evidence) = @_;
  my($regexptr,$iptr,$string,$agressive) = _chkgenhash($gptr);
  return 0 unless $regexptr;
  return 0 unless $addr =~ /((\d+)\.(\d+)\.(\d+)\.)(\d+)/;
  $agressive = $aTptr ? 0 : $gptr->{aggressive};
  my $primarystring = 'policy violation, unacceptable generic PTR record';

  my $cidr = $1;
  my $primary = $5;
  my $revip = "${4}.${3}.${2}.in-addr.arpa";
  my $name = "${primary}.$revip";
  my $saddr = inet_aton($addr);
  my($get,$put,$parse) = new Net::DNS::ToolKit::RR;

  my $prior = defined $tool->get($evidence,$saddr);	# prior evidence
  unless ($mc_evidence) {
    return 0 if $prior;
  }

  my $sock = IO::Socket::INET->new(
	PeerAddr	=> inet_ntoa(scalar get_ns()),
	PeerPort	=> 53,
	Proto		=> 'udp',
	Type		=> IO::Socket::INET::SOCK_DGRAM,
  ) or return -3;

  my($rv,%results);

  if (!$prior && ($rv = _xcidrev($sock,$get,$put,$saddr,$name,$primarystring,$regexptr,$iptr,$aTptr))) {
    $results{$saddr} = $rv;
  }

  if ($string && ($rv || $agressive)) {
    $string .= $addr;
    foreach (0..255) {
      my $target = "${cidr}$_";
      next if $_ eq $primary;
      $saddr = inet_aton($target);
      next if defined $tool->get($evidence,$saddr);	# skip on DB error or pre-existing spam record
      $name = "${_}.$revip";
      if ($rv = _xcidrev($sock,$get,$put,$saddr,$name,$string,$regexptr,$iptr)) {
        $results{$saddr} = $rv;
      }
    }
  }
  close $sock;

  if ($rv = scalar keys %results) {
    if ($aTptr) {	# results to 'blcontrib'
      my($unused,$reason,$error,$IP,$expire,$cp,$zone,$ipA,$dnresp,$tarpit,$netA,$key,$contrib,$DEBUG,$VERBOSE) = @$aTptr;
      foreach $key (sort keys %results) {
	$IP = inet_ntoa($key);
	next if defined $tool->get($contrib,$key);	# skip if already in DB for some other reason
	_addTPentry($tool,$reason,$error,$IP,$expire,$cp,$zone,$ipA,$dnresp,$tarpit,$netA,$key,$contrib,$DEBUG,$VERBOSE);
	$zone = 'ONLY_COUNT_ONE';			# disable further counts after the first one so only primary addition is counted
      }
      return $rv;
    }			# results to evidence
    foreach $saddr (sort keys %results) {
      unless ($tool->put($evidence,$saddr,$results{$saddr})) {
	$tool->sync($evidence);
	unless ($tool->touch($tarpit,$saddr)) {
	  $tool->sync($tarpit);
	}
      }
    }
    unless ($tool->touch($tarpit,SerialEntry())) {
      $tool->sync($tarpit);
    }
  }
  return $rv;
}

=item * @err=abuse_host($fh,\%MAILFILTER,,\%localvars,\@NAignor)

This function extracts  the abuse host name and IP address from
the headers passed in as "message text"

  input:	file handle,
		config hash ptr,
		dnsbl config hash ptr,
		$localvars->{dbhome => path to environment},
		net object ptr,

  output:	empty array on success,
		(verbosity, err msg) on failure
	where verbosity is false on success,
	1,2,3, etc.... on failure

		fills %$localvars{
			SPAM	=> read buffer so far,
			shost	=> spam host,
			to	=> abuse host
			hostIP	=> ip address
			ab2	=> [for debug]
		};

=cut

sub abuse_host {
  my($fh,$MAILFILTER,$DNSBL,$lv,$NAignor) = @_;

# read up to 10000 characters
  my $readlim	= 10000;
  my @lines;
  my $buf;
  return (1,'invalid filehandle)
	unless defined fileno($fh);
  return (1,no lines read')
	unless limitread($fh,\@lines,$readlim);

# close incomming connection
  dispose_of($fh);

  return(3,"startup blocked by DB watcher process")
	if -e $lv->{dbhome} .'/'. 'blockedBYwatcher';

# skip the headers from local client
  my @discard;
  return (1,'no message found')
	unless skiphead(\@lines,\@discard);

# extract incoming message headers
  my @headers;
  if ($MAILFILTER->{DIRTY}) {
    return (1,'no dirty input headers')
	unless rfheaders(\@discard,\@headers);
  } else {
    return (1,'no headers')
	unless headers(\@discard,\@headers);
  }


# find to so that we can determine the length of the domain to capture
  my $to;
  foreach(@headers) {
    if ($_ =~ /to:\s*[<]?(.+)@.+[>]?\s*/i) {
      $to = $1;
      last;
    }
  }

  return (1,'no To: found')
	unless $to;

# extract the spam headers
  if ($MAILFILTER->{DIRTY}) {
    return (1,'no dirty headers')
	unless rfheaders(\@lines,\@headers);
  } else {
    return (1,'no headers')
	unless headers(\@lines,\@headers);
  }

# extract MTA's
  my @mtas;
  return (1,'no MTAs found')
	unless get_MTAs(\@headers,\@mtas);

# extract bad guy address
  my $noprivate = ($MAILFILTER->{NOPRIVATE})
	? 1 : 0;
  my $spamsource = firstremote(\@mtas,$MAILFILTER->{MXhosts},$noprivate);
  return (1,'no spam source found')
	unless $spamsource;

  $lv->{hostIP} = $spamsource;

# punt if this address should be ignored
  return (1,'spam source ignored')
	if matchNetAddr($spamsource,$NAignor);

# get host name
  my $name = rlook_rcv(rlook_send($spamsource));

  return (1,'hostname not found')
	unless $name;

  $lv->{shost} = $name;		# spam host name

  my $min = 2;			# minimum domain depth
  my $num = ($to =~ /\d$/ && $& > $min)
        ? $& : $min;
  @_ = split(/\./,$name);
  my $target = pop @_;
  while (--$num > 0) {
    last unless $_ = pop @_;
    $target = $_ .'.'. $target;
  }
  $lv->{to} = $target;		# abuse host target
  $lv->{ab2} = $to;		# my rcpt address

# stringify headers and message
  return (1,'no evidence found')
	unless ($lv->{SPAM} = array2string(\@lines));	# punt if no message

  return ();
}

=item * $rv = is_GENERIC($conf->{GENERIC},@hostnames)

Check if a list of hostnames are all generic

  input:	hash pointer to 'GENERIC',
		hostname list
  returns:	true is generic
		false is not

=cut

sub is_GENERIC {
  my($gp,@hostname) = @_;
  my($regexptr,$iptr) =  _chkgenhash($gp);
  return 0 unless $regexptr;					# not configured
  foreach my $name (@hostname) {
    return 0 if $iptr && grep($name =~ /$_/i,@$iptr);		# skip if regexp is to be ignored
    return 0 if $name && ! grep($name =~ /$_/i, @$regexptr);
  }
  return 1;
}

# input:	generic hash pointer
# return:	(regexptr,iptr,msgstring,agressive)
#
sub _chkgenhash {
  my $gptr = shift;
  my($iptr,$regexptr);
  return () unless ref $gptr eq 'HASH' &&
  	$gptr->{regexp} &&
	'ARRAY' eq ref ($regexptr = $gptr->{regexp}) &&
	@$regexptr > 0;
  unless ($gptr->{ignore} &&
	'ARRAY' eq ref ($iptr = $gptr->{ignore}) &&
	@$iptr > 0) {
    $iptr = undef;
  }
  my $agressive = $gptr->{agressive} || '';
  my $string = $gptr->{message} || '';
  $string = '' unless length($string) > 3;
  return ($regexptr,$iptr,$string,$agressive);
}

=item * block4zonedump($environment);

Checks to see if a dnsbl zonedump is in progress and blocks until the zonedump is complete

  input:	$environment pointer
  returns:	nothing

=cut

sub block4zonedump {
  my $env = shift;
  local *D;
# fail silently if directory is not valid or pid file is not present
  return unless -e $env && -d $env;
  my $doublecheck = 2;			# check twice
WAIT:
  while ($doublecheck-- > 0) {		# wait here while job lives
    opendir(D,$env) or return;		# return if $env can not be opened
    my @dfiles = grep(/^dnsbls/,readdir(D));
    closedir D;
    my $restart = 0;			# no restart
    foreach (@dfiles) {
      next unless $_ =~ /dnsbls\.\d+\.pid/;
      $restart = 1;			# restart timer if zonedump found
      if (kill 0, $1) {		# if job is running
	$doublecheck = 1;	# always double check a running job
	sleep 60;		# wait a minute
	next WAIT;
      }
      unlink $env .'/'. $_;	# clean up dead pid files
    }
    if ($restart) {
      sleep 10;			# allow time for a restart
    }
  }
}

=item * $object = new Mail::Spamcannibal::ScriptSupport;

Returns a reference to a Mail::Spamcannibal::ScriptSupport object

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = {};
  bless $self, $class;
  return $self;
}

=item * $rv = $object->dns2rblz($line);

Converts DNS bind file lines created by B<dnsbls> to the B<rbldns> format.

  input:	DNS bind file line
  returns:	rbldns file line or ''

Note:
  if the DNS file was dumped in standard format, the returned
  rbldns lines will be in the standard format also. If the DNS
  file was created in promiscious mode, the rbldns lines will
  be in the enhanced format provided by:

	djbdns-1.05 rbldns patch

  found at:

	http://www.jms1.net/djbdns/rbldns-patch.html

=cut

sub dns2rblz {
  my($self,$in) = @_;
  my $out = '';
  while (1) {
    if ($self->{soa}) {			# hunting for SOA termination
      if ($in !~ /\)/) {		# if not closing bracket
	$in =~ /[^#]+/;			# accumulate numeric records without comments
	$self->{soa} .= $& || '';
	$self->{soa} .= ' ';
      }
      else {
	$in =~ /[^#)]/;			# add trailing record
	$self->{soa} .= $& || '';
	$self->{soa} =~ s/[\r\n\(]+/ /g;# convert CRLF's and '(' to space
	$self->{soa} =~ s/\s+/ /g;	# multiple spaces to single space
	while ($self->{soa} =~ / $/) { chop $self->{soa} };
	$self->{soa} =~ /\d+$/;		# extract ttl
	$self->{ttl} = $& unless $self->{ttl};
	$self->{soa} =~ s/SOA/SOA $self->{ttl}/i;
	$out = "\n#\$". $self->{soa};
	$self->{soa} = '';		# clear flag
      }
    } 
    elsif ($in =~ /^\$ORIGIN\s+(.+)/) {
      $self->{origin} = $1;
      $self->{origin} =~ s/[\.]?$self->{base}//i	# strip base (w/wout leading dot if origin is 'base')
	if $self->{base};
    }
    elsif ($in =~ /^(\$TTL\s+(\d+))/) {
      $out = "\n#$1" if $2 > 0;
      $self->{ttl} = $2;
    }
    elsif ($in =~ /^([0-9.]+).+A\s+([0-9.]+)/) {	# numeric A record
      my $rip = $1 .'.'. $self->{origin};
      @_ = reverse split(/\./,$rip);
      $self->{IP} = join('.',@_);
      $out = "\n". $self->{IP};				# print the record
      $out .= ":$2" unless $2 eq $self->{defresp};	# add answer if not default
      $self->{answer} = $2;
    }
    elsif ($in =~ /^\s.+TXT\s+["]([^"\r\n]+)/) {	# TXT record
      $_ = $1;
      (my $txt = $_) =~ s/$self->{IP}/\$/;
      unless ($txt eq $self->{txt}) {
	$out = ':'. $self->{defresp}			# add answer if not already present
		if $self->{answer} eq $self->{defresp};
	$out .= ':'. $_;				# add text
      }
    }
    elsif ($in =~ /rbldnsDEF:([\d.]+):([^\r\n]+)/) {
      $out = ":$1:$2";
      $self->{defresp} = $1;
      $self->{txt} = $2;
    }
    elsif ($in =~ /^([a-zA-Z][^\s]+).+(SOA[^#)]+)/) {
      $self->{base} = $1;			# set zone base
      $self->{soa} = $2;			# save soa comments and arm collection of multiple lines
      next if $in =~ /\)/;			# closing bracket
    }
    elsif ($in =~ /^\s.+NS\s+(.+)/) {	# NS record
      if ($self->{ns}) {
	$self->{ns} .= ' '. $1;
      } else {
	$self->{ns} = "#\$NS ". ($self->{ttl} || 0) .' '. $1;
      }
    }
    elsif ($in =~ /^\s.+A\s+(.+)/) {	# NS A record
      if ($self->{nsa}) {
	$self->{nsa} .= "\n";
      } else {
	$self->{nsa} = '';
      }
      $self->{nsa} .= '@ '. ($self->{ttl} || 0) .' A '. $1;
    }
# ignore anything else
    last;
  }
  return $out;
}

=item * $textline = $object->rbldns_compress($textline);

Compress B<ip4tset> rbldnsd data file lines produced by B<dns2rblz> above to
B<ip4set> data format.

  input:	ip4tset line
  returns:	ip4set line

=cut

sub rbldns_compress {
  my($rbl,$line) = @_;
  return '' unless $line =~ /\S/;
  $line =~ s/\n//g;
  if ($line =~ /^:/) {
    delete $rbl->{start};
    $line .= "\n";
  }
  elsif ($line !~ /^(\d+\.\d+\.\d+\.)(\d+)(.*)/) {
    $line =~ s/\n//g;
    $line .= "\n";
  }
  elsif (! exists $rbl->{start}) {
    $rbl->{start} = $1;
    $rbl->{first} = $2;
    $rbl->{last} = $2;
    $line = $1 . $2 .($3 || '');
  }
  elsif ($rbl->{start} ne $1) {
    if ($rbl->{first} == $rbl->{last}) {
      $line = "\n". $1 . $2 .($3 || '');
    }
    else {
      $line = '-'. $rbl->{last} ."\n". $1 . $2 .($3 || '');
    }
    $rbl->{start} = $1;
    $rbl->{first} = $2;
    $rbl->{last} = $2;
  }
  elsif ($rbl->{last} + 1 == $2) {
    $rbl->{last} = $2;
    $line = '';
  }
  else {
    $line = '-'. $rbl->{last} ."\n" . $1 . $2 .($3 || '');
    $rbl->{first} = $2;   
    $rbl->{last} = $2;
  }
  return $line;
}

=item * $firstline = $object->rbldns_combined($type);

Write the first line of an B<rbldns> combined dataset of type 
B<ip4set | ip4tset>.

  input:	type, one of ip4set or ip4tset
  returns:	dataset statement for ip4set
	    or	undef on error

=item * $last_combined = rbldns_address();

Write the generic format address record(s) for the name server
within this address. This should be the last record after the ip4set is
generated using a starting header generated by B<rbldns_combined> (above).

  input:	none
  returns:	dataset statement + address

=cut

sub rbldns_address {
  my $self = shift;
  if ($self->{nsa}) {
    return'$DATASET generic @
'. $self->{nsa} ."\n";
  }
  return '';
}

=item * $lastline = $object->rbldns_done();

Complete the last line of an ip4set dataset conversion.

  input:	none
  returns:	remainder of last line
		in the ip4set data file

=cut

sub _add_nsrecord {
  my($self,$line) = @_;
  if ($self->{ns}) {
    $line .= $self->{ns} ."\n";
  }
  return $line;
}

sub rbldns_done {
  my $rbl = shift;
  my $rv;
  if ($rbl->{first} == $rbl->{last}) {
    $rv = "\n";
  } else {
    $rv = '-'. $rbl->{last} ."\n";
  }
  return _add_nsrecord($rbl,$rv);
}

=item * $lastline = $object->rbldnst_done();

Complete the last line of an ip4tset dataset conversion.

  input:	none
  returns:	remainder of last line
		in the ip4tset data file

=cut

sub rbldnst_done {
  return _add_nsrecord($_[0],"\n");
}

=pod

=back

=cut

=head1 DEPENDENCIES

	NetAddr::IP::Lite
	Net::DNS::Codes
	Net::DNS::ToolKit
	Net::DNS::ToolKit::RR
	Mail::SpamCannibal::GoodPrivacy
	Mail::SpamCannibal::BDBclient

=head1 EXPORT

	none by default

=head1 EXPORT_OK

	DO
	doINCLUDE
	SerialEntry
	TarpitEntry
	DNSBL_Entry
	id
	question
	revIP   
	query   
	dns_ans 
	zone_def
	valid127
	validIP
	zap_one
	zap_pair
	job_died
	dbjob_chk
	dbjob_kill
	dbjob_recover
	unpack_contrib
	lookupIP
	list2NetAddr
	matchNetAddr
	BLcheck
	checkclct
	dumpIPs
	BLpreen
	mailcheck
	abuse_host
	is_GENERIC
	block4zonedump

=head1 COPYRIGHT

Copyright 2003 - 2010, Michael Robinton <michael@bizsystems.com>

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

Michael Robinton <michael@bizsystems.com>

=head1 SEE ALSO

L<IPTables::IPv4::DBTarpit>,
L<Net::DNS::Codes>, L<Net::DNS::ToolKit>, L<Net::DNS::ToolKit::RR>,
L<Mail::SpamCannibal::DNSBLserver>, L<Mail::SpamCannibal::BDBaccess>

=cut

1;
