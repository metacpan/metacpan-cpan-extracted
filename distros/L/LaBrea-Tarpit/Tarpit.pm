#!/usr/bin/perl
package LaBrea::Tarpit;
#
# 2-5-05, michael@bizsystems.com
#
BEGIN { $SIG{'__WARN__'} = sub { warn $_[0] if $DOWARN }}
$__PACKAGE__::DOWARN = 1;
use strict;
#use diagnostics;
use vars qw($VERSION @ISA @EXPORT_OK);

$VERSION = do { my @r = (q$Revision: 1.36 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

use Fcntl qw(:DEFAULT :flock);
use AutoLoader 'AUTOLOAD';
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(
	recurse_hash2txt
	daemon
	bandwidth
	midnight
	timezone
	tz2_sec
	their_date
	restore_tarpit
	log2_mem
	process_log
	cull_threads
	write_cache_file
	prep_report
	find_old_threads
	array2_tarpit
);

use constant defaults => {	# seconds
	'cull'		=> 600, # drop threads older than this
	'min_age'	=> 15,	# don't cull for at least
	'auto_cull'	=> 900,	# cull at least every
	's_timeout'	=> 0.1,	# select timeout
	'sock_timeout'	=> 180,	# give up on socket response
};
use constant mon => {
	qw(jan 0 feb 1 mar 2 apr 3 may 4 jun 5 jul 6 aug 7 sep 8 oct 9 nov 10 dec 11)
};

=head1 NAME

  LaBrea::Tarpit - Utilities and web displays for 
  Tom Liston's LaBrea scanner/worm disruptor

  See: http://sourceforge.net/projects/labrea/

=head1 SYNOPSIS

  use LaBrea::Tarpit qw( [exportable functions] );
  or
  require LaBrea::Tarpit;

  daemon(%hash or \%hash);

  $bandwidth = bandwidth(\%tarpit);

  $midnight = midnight($epoch_time,$tz);

  $timezone = timezone($now);

  $sec = $tz2_sec($tz);

  $time_string = their_date($gmtime,$tz);

  $rv = restore_tarpit(\%tarpit,path2cache_file);

  $rv = log2_mem(\%tarpit,log_line,is_daemon,port_intvls,DShield);

  $rv = process_log(\%tarpit,path2log_file,is_daemon,port_intvls);

  $rv = cull_threads(\%tarpit,timeout,scanners,port_intvls,DShield);

  $rv = write_cache_file(\%tarpit,path2cache_file,umask,flag);

        prep_report(\%tarpit,\%hash);

  $rv = find_old_threads(\%tarpit,\%report,$age);

=head1 INSTALL

=over 4

=item * Package

	Untar the package

	perl Makefile.PL
	make
	make test
	make install

	To use examples/daemon.pl, configure
	the array at the beginning of the script
	and set the locations for the cache files.
	...typically /var/tmp/labrea.cache
	and /var/tmp/DShield.cache

=item * Report/examples/html_report.plx

=item * Report/examples/paged_report.plx

B<html_report> and B<paged_report> will run as a cgi scripts 
by simply renaming them B<xxx_report.cgi>. It is highly recommend that 
you  enable the file caching to minimize load on your system.

Read the comments in the file itself for configuration. 
The defaults should work fine, but you must create the 
temporary directory used for file caching AND it must
be writable by the web server.

B<html_report> and B<paged_report> are configured to provide B<other_site> 
reporting. You must set up the cron job maintain the
B<site_stats> file for reporting. B<See webscan.pl> below:

=item * Get/examples/web_scan.pl

Run B<web_scan.pl> from a cron job hourly or daily to 
update the statistics from all know sites running 
LaBrea::Tarpit. A report can then be generated showing 
the activity worldwide. 

  # MIN HOUR DAY MONTH DAYOFWEEK   COMMAND
  30 * * * * ./web_scan.pl ./other_sites.txt ./tmp/site_stats

  Also see: LaBrea::Tarpit::Report::other_sites

=item * examples/tell_me.pl AGE

Run B<tell_me.pl> from a cron job daily to send yourself
an email detailing teergrubed hosts that have been
held longer than B<AGE> days. You might actually want
to tell the bad guys that they have a rogue machine.

  # MIN HOUR DAY MONTH DAYOFWEEK   COMMAND
  30 * * * * ./tell_me.pl 60  # default

=item * DShield/examples/mail_dshield.pm

Configure with your DShield UserID, email address, mail agent and 
the location of the daemon - DShield cache file, then run periodically from
cron to send reports to DShield.

=back

=head1 DESCRIPTION - LaBrea::Tarpit

A comprehensive Hack Attack reporting module when used in conjunction with
Tom Liston's LaBrea scanner/worm disruptor. When configured with reporting
and stat collection it provides a detailed HTML page containing:

=over 4

=item * Bandwidth consumed by attack/disruption daemon

=item * Summary of previous 5 days of attack/disruption

=item * All IP addresses currently attacking

=item * IP address, port attacked/held, attack start time

=item * As above, but history of terminated attacks

=item * By day detail graphs on port attack intensity

=item * Active summary of known LaBrea::Tarpit sites

=back

For more information on B<LaBrea> see: L<http://sourceforge.net/projects/labrea/> 
or contact the author of LaBrea, Tom Liston L<tliston@hackbusters.net>.

The parsed output of either syslog data or STDOUT from LaBrea using -o or -O
options is readily turned into text reports or an html output page.

Basically there are two methods of operation. You can use the B<daemon> mode
to create an almost realtime cache that may be parsed using the report
routines, or you can use the update and report routines to parse the syslog
files on an as needed basis. If you plan to create web page reports, the
daemon model will use less system resources in the long run and avoids
running syslog with the high volume output of LaBrea.

Improvements VERSION 1.00

As of version 1.00, B<daemon.pl> uses network sockets to provide data for
the report modules. This means that the daemon can run on a remote machine
and the report scripts and web server can be somewhere else.

For those of you upgrading from older versions, you B<MUST> upgrade all of
your report scripts as well. Older versions use a pipe or FIFO and this is
no longer supported as there were problems maintaining separate sessions.

=cut

# memory records are kept in the form:
#
# %tarpit			# time is kept in seconds since epoch
#	{bw}	-> bandwidth	# bytes per second
#
#	{tz}	-> timezone	# i.e. text string = -800	
#
#	{now"	-> epoch time	# only used when writing cache, 
#				# not current otherwise
#   active threads
#	{at}	-> {srcIP_1}	-> {sp1} -> {dip} -> destination IP
#		     .	      (src_port1)   {dp}  -> destination port
#		     .	      .		    {pst} -> protocol type (0,6=tcp)
#						for tcp = persistent [true/false]
#		     .	      .		    {ct}  -> capture time
#		     .	      .		    {lc}  -> last contact time
#		     .        .
#		     .		-> {sp2} -> {dip} -> destination IP
#		     .	      (src_port2)   {dp}  -> destination port
#		     .			    {pst} -> protocol type (0,6=tcp)
#						for tcp =  persistent [true/false]
#		     .			    {ct}  -> capture time
#		     .			    {lc}  -> last contact time
#		     .
#		   {srcIP_2}	-> etc...
#   dead threads
#	{dt}	-> {srcIP}	-> {dp}  -> last destination port
#				   {lc}  -> last contact time
#		     .
#   port stats
#	{ph}	-> {timea}	-> {port num.x}	  -> count
#		     .		-> {port num.y}   -> count
#		     .		-> {port num.z}   -> count
#		   (timeb}	-> etc...
#
#	{pt}	-> collection_interval

=over 2

=item * recurse_hash2txt(\$txt_buffer,\%hash,$keys_so_far,flag)

 Appends to txt_buffer.

 Generates a text tree of a hash.
 %hash{lvl1}->{lvl2}->{lvl3} = 5;	this real hash
 flag = 0, ksf = ''			with this input
 lvl1:lvl2:lvl3:5		produces this text
 flag = 1, ksf = ptr			this input
 ptr->{lvl1}->{lvl2}->{lvl3} = 5;	this txt

=cut

# input:	txt out pointer, pointer to hash, keys so far, dump | debug
# 		if the dod flag is 0, this is normal dump mode
#		else it's the fancy debug mode
sub recurse_hash2txt {
  my ($txp, $p, $ksf,$dod) = @_;
  foreach my $key (sort keys %{$p}) {
    my $keysnow = $ksf;
    $keysnow .= ($dod) ? qq|->{$key}|
	: ($ksf) 
		? ':'. $key
		: $key;
    if (ref $p->{$key}) {
      &recurse_hash2txt($txp,$p->{$key},$keysnow,$dod);
    } else {
      $keysnow .= ($dod) ? ' = ' : ':';
      $keysnow .= ($p->{$key} || 0) . "\n";
      $$txp .= $keysnow;
    }
  }
}

=item * ($LBfh,$version,$kid) = lbd_open($LaBrea,$DEBUG);

Core daemon start routine. Not exported, but can
be replaced externally with:

  *LaBrea::Tarpit::lbd_open = sub { stuff };

Returns the pid of the underlying process (if any) and the version number of
that process. It also sets the command line shown by 'ps' like this:

  $0 = 'stuff';

  input:	path to daemon,
		STDERR switch
  returns:	LaBrea file handle,
		version,
		pid of kid

=cut

sub lbd_open {
  my($LaBrea,$DEBUG) = @_;
  local *LABREA;
  $LaBrea =~ /^([^\s]+)/;		# bare path to LaBrea
  qx/$1 -V 2>&1/ =~ /(\d+\.[^\s]+)/;	# get version
  my $version = $1;			# save version
# open LaBrea daemon
  my $kid = open(LABREA,$LaBrea .' |');
  die "Can't open $LaBrea: $!" unless $kid;
  unless ($DEBUG) {
    open STDERR, '>&STDOUT'		or die "Can't dup stdout: $!";
  }
  $0 = __PACKAGE__.' '.$0;		# set ps(1) name to package name
  return(*LABREA,$version,$kid);
}

=item * lbd_close($LBfh,$kid);

Core daemon close routine, not exported but can be
replaced externally with:

  *LaBrea::Tarpit::lbd_close = sub { sutff };

Close the daemon and kill off $kid with sig 15

  input:	filehandle,
		pid of kid
  returns:	nothing

=cut

sub lbd_close {
  my($LBfh,$kid) = @_;
  kill 15, $kid;				# kill LaBrea
  close $LBfh;
}

# autoload everything to keep daemon small
sub daemon;
sub bandwidth;
sub midnight;
sub timezone;
sub restore_tarpit;
sub log2_mem;
sub process_log;
sub cull_threads;
sub write_cache_file;
sub prep_report;
sub find_old_threads;
sub array2_tarpit;

# helper subroutines
#sub _cullnsquish;
sub _check4cull;
sub _init_pt;
sub _add_array;
sub _cache2txt;
sub _ex_append;
sub _get_config;
sub DESTROY {};

1;
__END__

=item * daemon(&hash | \%hash)

 input parameters: from hash or pointer to hash
 {
  'LaBrea'	=> '/usr/local/bin/LaBrea -z -v -p 1000 -h -i eth0 -b -O 2>&1',
 # 'd_port'	=> '8686',		# default local comm port
  'd_host'	=> 'localhost',		# defaults to ALL interfaces 
					# NOT recommended
  'allowed'	=> 'localhost,remote.com',	# default is ALL
					# recommend only 'localhost'
  'pid'		=> '/path/to/pid/file_name',
  'cache'	=> '/path/to/cache/file',
  'DShield'	=> '/path/to/DShield/out_file',
 # 'kids'	=> default 5		# kids to deliver net msgs
					# why would you need more??
 # 'umask'	=> default 033,		# cache_file umask
 # 'cull'	=> default 600,		# seconds to keep old threads
  'scanners'	=> 100,			# keep this many dead threads
 # 'port_timer'	=> default 86400,	# seconds per collection period
  'port_intvls' => 30,			# keep #nintvls of port stats
					# 0 or missing disables
					# this can take lots of memory
  # optional exclusion information (required if files exist)
    'config'	=> '/etc/LaBreaConfig',
  # or
 #   'config'	=> 'LaBrea.cfg',        # windoze (untested)
  # or
 #   'config'	=> ['/etc/LaBreaExclude','/etc/LaBreaHardExclude'],
 };

=cut

# 'DEBUG'	=> undef,		turn on STDERR in daemon

=pod

The daemon can be run on a remote host with restricted client access and
the data retrieved by another host that has web server capabilities

=back

=over 4

B<scanners> is enabled by setting to a positive number. 
Since all IP's that are seen but not captured can 
potentially be saved, this list could grow very large.
You can limit the amount of memory used by setting the
number of items that can be saved. There is no default,
a value <= 0 turns of this feature. Scanners are saved on
a fifo basis, when full, the oldest will be deleted first.

=back

=over 2

 Signals:

  HUP		cull then write new cache file
  TERM		cull, write cache, exit

  Killing the daemon with SIG_KILL (-9) will NOT write
  a new cache file and will leave LaBrea running.
  YOU SHOULD NOT DO THIS

B<daemon operation>:
The daemon parses the output of LaBrea in real time and
collects the information in its memory cache, periodically
pruning away threads that are no longer active to minimize
the memory footprint. Upon receiving a HUP, it immediately
prunes memory of old threads and writes its cache to file.

B<data retrieval>

  Usage:
	connect to TCP port 8686
	send "standard" (endline)
	  or
	send "active" (endline)
	  or
	send "short" (endline)
	  or
	send "config" (endline)

to receive the complete memory cache described above or
only active threads or a truncated version suitable for 
making a B<short> report. B<config> sends the daemon
configuration file information to the client.

=cut

# helper routine
#
# check for time to cull cache of old threads
# this does not need to be done often because 
# LaBrea holds most indefinetly unless the black 
# hat guys give up. Call with a small wait time 
# when dumping the cache for use in a web page
# 
# input:	time between culls
#
# returns:	true if cull reduces thread count, else false
#
sub _check4cull {
  my ($tp,$ttcp,$wait_time,$cull,$scrs,$ph,$ds) = @_;
  my $now = $tp->{now} = time;
  if ( $now > $$ttcp + $wait_time ) {
    $$ttcp = $now;		# reset wait time
    return &cull_threads($tp, $cull, $scrs, $ph, $ds);
  }
  0;
}

# check as above and if there is a tarpit cull,
# collapse the tarpit hash to conserve memory
# 1) write out the hash to disk
# 2) set the tarpit hash to an anon empty array
# 3) reload the tarpit from the disk
#
# returns:	true if cull, else false
#		fails silently if there is no cache file

#sub _cullnsquish {
#  my ($tp,$ttcp,$wait_time,$cull,$scrs,$ph,$ds,$pt,$cache_file,$umask,$version) = @_;
#  my $rv;
#  if ($rv = &_check4cull($tp,$ttcp,$wait_time,$cull,$scrs,$ph,$ds)) {	# cull every few minutes
#    my $cache_txt = &write_cache_file($tp,$cache_file,$umask,1);	# write cache file and return cache text
#    %$tp = ();								# collapse tarpit hash;
#    my @lines = split("\n",$cache_txt);
#    &array2_tarpit($tp,\@lines);  # returns true
#    $tp->{LaBrea} = $version;						# set version number
#    $tp->{pt} = $pt || 86400;						# default data collection is one day
#  }
#  $rv;
#}
  
# input:	file name, mark text
# returns:	lines of file with ' mark text\n' appended
#
sub _get_config {
  my ($f,$mark) = @_;
  $mark = ' ' . $mark if $mark;
  local *F;
  return '' unless open(F,$f);
  @_ = (<F>);		# slurp lines
  close F;
  chop @_;
  my $rv = join("$mark\n",@_);
  $rv .= "$mark\n" if $rv;
};

# make daemon
#
# KILL with signal TERM, -15
# dump cache with SIG_HUP
#
# input:	%hash or \%hash above
#
sub daemon {
  my $pid;
  $_ = ( ref $_[0] ) ? $_[0] : {@_};
  my ($LaBrea,$config,$pid_file,$max_kids,$d_port,$d_host,$allowed,$cache_file,$umask,$cull,$scrs,   $ph,        $pt,       $ds,   $DEBUG) = @{$_}{
    qw(LaBrea  config  pid           kids  d_port  d_host  allowed  cache       umask  cull scanners port_intvls port_timer DShield DEBUG)};

# fork and test
  unless ( $pid = fork ) {
# clean up for proper daemon operation
    chdir '/';			# allow root dismount
    open STDIN, '/dev/null'	or die "Can't read /dev/null: $!";
    open STDOUT, '>/dev/null'	or die "Can't write to /dev/null: $!";
    unless ( $pid = fork ) {
      local(*SERVER,*CLIENT);

      require LaBrea::NetIO;
      import LaBrea::NetIO qw(
	open_listen_sock
	reap_kids
	set_so_linger
	sockaddr_in
	inet_ntoa
      );

# open server port

      die $_ if ($_ = open_listen_sock(*SERVER,$d_host,$d_port));
      my $flags = fcntl(SERVER,F_GETFL,0)	|| die "can't get socket flags";
      fcntl(SERVER,F_SETFL,$flags | O_NONBLOCK)	|| die "can't set socket non-blocking";

      require POSIX;
      my $tarpit = {};
      &POSIX::setsid()	or die "Can't start new session: $!";
      my($LBfh,$version,$kid) = lbd_open($LaBrea,$DEBUG);
      $umask = 033 unless $umask;
      $cull = defaults->{cull} unless $cull;
      $ph = 0 unless $ph;
      my $time2cull = time + $cull;	# first cull must wait

##### define signal services within this scope

      my $run = 1;
      my $hup = 0;

$__PACKAGE__::DOWARN = 0;		# quite warnings about 
      my $quit = sub {			# portability of $run, $hup
	$run = 0;
      };
      my $dohup = sub {
	$hup = 1;
      };
$__PACKAGE__::DOWARN = 1;

#      local $SIG{HUP} = $dohup;
#      local $SIG{INT} = $dohup;
#      local $SIG{TERM} = $quit;

      local $SIG{HUP} = sub { $hup = 1; };
      local $SIG{INT} = sub { $hup = 1; };
      local $SIG{TERM} = sub { $run = 0; };
      local $SIG{PIPE} = 'IGNORE';

      &restore_tarpit($tarpit,$cache_file) if -e $cache_file;
      $tarpit->{LaBrea} = $version;	# set version number
      $tarpit->{pt} = $pt || 86400;	# default data collection is one day

# prepare daemon loop
      my $WNOHANG = &POSIX::WNOHANG; 
      my $rin = '';
      vec($rin,fileno($LBfh),1) = 1;
      my $timeout = defaults->{s_timeout};
      my ($rout,$paddr,%kids);

      my @valid_clients;
      foreach(split(',', $allowed)) {
	(undef,undef,undef,undef,@_) = gethostbyname($_);
	push @valid_clients,@_;
      }

      $max_kids = 5 unless $max_kids;
      my $kids = 0;		# number of kids alive
      while($run) {
# accept for SERVER is not set for 'select', find it with the POLL
	my $ready = select($rout=$rin,undef,undef,$timeout);
	if ( $ready > 0 ) {
	  $_ = <$LBfh>;	# blocks, but doesn't matter here
	  last unless $_;	# Oops, LaBrea must have died, EXIT
	  &log2_mem($tarpit,$_,1,$ph,$ds);
#	  &_cullnsquish($tarpit,\$time2cull,defaults->{auto_cull},$cull,$scrs,$ph,$ds,$pt,$cache_file,$umask,$version);
	  if (&_check4cull($tarpit,\$time2cull,defaults->{auto_cull},$cull,$scrs,$ph,$ds)) {	# cull every few minutes
		;
# revert cull operation to previous behavior
# the code below does not seem to improve memory usage
#	    my $cache_txt = &write_cache_file($tarpit,$cache_file,$umask,1);	# write cache file and return cache text
#	    $tarpit = {};							# collapse tarpit hash;
#	    my @lines = split("\n",$cache_txt);
#	    &array2_tarpit($tarpit,\@lines);					# returns true
#	    $tarpit->{LaBrea} = $version;					# set version number
#	    $tarpit->{pt} = $pt || 86400;					# default data collection is one day
	  }
	} 
	elsif ( $hup ) {
#	  &write_cache_file($tarpit,$cache_file,$umask,1) unless
#	    &_cullnsquish($tarpit,\$time2cull,defaults->{min_age},$cull,$scrs,$ph,$ds,$pt,$cache_file,$umask,$version);	# cull immediate
	  &_check4cull($tarpit,\$time2cull,defaults->{auto_cull},$cull,$scrs,$ph,$ds);	# cull immediate
	  &write_cache_file($tarpit,$cache_file,$umask,1);				# and write cache file
	  $hup = 0;
	}
	elsif ( $kids < $max_kids && ($paddr = accept(CLIENT,SERVER)) ) {	# client has connected
	  if ($pid = fork) {
	    close CLIENT; 			# close if parent
	    $kids{$pid} = ++$kids if $pid;	# bump kid count, val is not used
	  } else {				# CHILD, service request
	    close SERVER;

########### CHILD PROCESS #################

	    local $SIG{ALRM} = sub { die "child connect timeout" };

	    my $iaddr = (sockaddr_in($paddr))[1];
	    unless ( ( ! @valid_clients || 			# allow all
			 grep($_ == $iaddr,@valid_clients)) && 	# or small number
			set_so_linger(*CLIENT,30)) {		# linger 30 seconds to deliver stuff
	      close CLIENT;
	      exit 0;			# exit silently if not allowed or can't set linger
	    }
	    
	    &_check4cull($tarpit,\$time2cull,defaults->{min_age},$cull,$scrs,$ph,$ds);	# cull immediate

	    eval {
	      my $cache_txt = '';
	      alarm defaults->{sock_timeout};
	      my $request = readline *CLIENT;
	      if ( $request =~ /^standard/ ) {			# full tarpit contents
		$request = $tarpit;
	      }
	      elsif ( $request =~ /^short/ ) {			# short totals only
		$request = { 'Tarpit'	=> $VERSION };		# version in format for other end
		prep_report($tarpit,$request);
	      }
	      elsif ( $request =~ /^active/ ) {		# only active threads
		$request = { 'at' => $tarpit->{at} };
	      }
	      elsif ( $request =~ /^config/ ) {		# return config info
		if ( $config ) {
		  if (ref $config) {	# if it is array format
		    @_ = @{$config};
		  } else {
		    @_ = ($config);
		  }
		  my ($hard_ex,$exclude,$new_config);
		  if ( $_[0] =~ /Exclude/ ) {		# old style
		    if ( $_[0] =~ /Hard/ ) {
		      $cache_txt .= &_get_config($_[0],'hardexclude');
		    } else {
		      $cache_txt .= &_get_config($_[0],'exclude');
		    }
		    if ( @_ > 1 ) {			# if second argument
		      if ( $_[1] =~ /Hard/ ) {
			$cache_txt .= &_get_config($_[1],'hardexclude');
		      } elsif ( $_[1] =~ /Exclude/ ) {
			$cache_txt .= &_get_config($_[1],'exclude');
		      }
		    }
		  } elsif ( $_[0] =~  /Config/ ||
				      /LaBrea\.cfg/ ) {	# new style, config true
		    
		    $cache_txt .= &_get_config($_[0],'');
		  }
		} # end config file info
		$cache_txt = "none\n" unless $cache_txt;

	      } else {		# unknown

		alarm 0;
		close CLIENT;
		exit 0;
	      }

	      &_cache2txt(\$cache_txt,$request,'daemon') unless $cache_txt;
	      my $len = length($cache_txt);
	      my $off = 0;
	      my $win = '';
	      my ($wout,$eout);
	      vec($win,fileno(CLIENT),1) = 1;
	      my $ein = $win;
	      while ($len) {
		$ready = select(undef,$wout=$win,undef,defaults->{pipe_timeout});	# block until write or error
		last unless $ready;		# punt if timeout
		my $wrote = syswrite(CLIENT,$cache_txt,$len,$off);
		last unless defined $wrote;	# only errors
#	      if ( ! defined $wrote ) {
#		next if $! == EAGAIN;		# would block
#	      }
		$off += $wrote;
		$len -= $wrote;
	      }
	    };	
	    alarm 0;
	    close CLIENT;
	    exit 0;				# child dies
	  }
########### END CHILD #################
	}
	else {
	  $kids = reap_kids(\%kids);		# dispose of dead kids, return remaining number
	}
      }
      lbd_close($LBfh,$kid);
      &_check4cull($tarpit,\$time2cull,defaults->{min_age},$cull,$scrs,$ph,$ds);	# cull threads
      &write_cache_file($tarpit,$cache_file,$umask,1);
      foreach $kid ( keys %kids ) {
	kill 15, $kid;				# kill remaining children
      }
      unlink $pid_file;
      exit 0;
    }
    exit 1 unless open(PID,'>'.$pid_file);
    print PID $pid, "\n";
    close PID;
    exit 0;
  }
  waitpid($pid,0);
}

=item * $bandwidth = bandwidth(\%tarpit);

Returns bandwidth reported by LaBrea or zero
if the -b option is not used or B<bw> is unknown.

=cut

# return the current bandwidth
#
# input:	\%tarpit
# return:	bandwidth
#
sub bandwidth {
  my ($tp) = @_;
  return $tp->{bw} || 0;
}

=item * $time = midnight($epoch_time,$tz);

 Returns epoch time at 00:00:00 of current day
 from any epoch time submitted. Time zone is
 calculated (inefficently) each time if omitted.  

=cut

sub midnight {
  my ($et,$tz) = @_;
  $tz = &timezone($et) unless $tz;
  my $mn= $et - tz2_sec($tz) - ($et%86400);
  if ($mn > $et) {
    $mn -= 86400;
  } elsif ($et - $mn >= 86400) {
  $mn += 86400;
  }
  $mn;
}

=item * $seconds = $tz2_sec($tz);

  Convert time zone into seconds

  input:	timezone i.e. -0800
  returns:	seconds i.e. -28800

=cut

sub tz2_sec {
  my ($tz) = @_;
  my $tza = abs $tz;
  my $min = $tza % 100;
  my $hr = $tza - $min;
  my $sec = ($hr * 36) + $min * 60;
  $sec = -$sec if $tz < 0;
  $sec;
}
  
=item * $time_string = their_date($gmtime,$tz);

  Returns date string like perl's 
  localtime(time)
  for the specified time zone

=cut

sub their_date {
  my ($time,$tz) = @_;
  return gmtime($time + tz2_sec($tz)) . ' ' . $tz;
}

=item * $timezone = timezone($now);

 Returns the local timezone as a text string
	i.e. -0800
 uses current time if $now is omitted, 
 this is the normal method of usage.

=cut

sub timezone {
  my $t = $_[0] || time;
  my $tt = $t;
  my (@lt) = localtime($t);
  my (@gt) = gmtime($t);
  my $tzmin = ($gt[1] - $lt[1]) + ($gt[2] - $lt[2]) * 60;
  if($lt[5] > $gt[5]) {
    $tzmin -= 1440;
  }
  elsif($gt[5] > $lt[5]) {
    $tzmin += 1440;
  }
  else {
    $tzmin += ($gt[7] - $lt[7]) * 1440;
  }
  $tzmin += 60 if $lt[8];
  my $time = $t + $tzmin * 60;
  my @test = localtime($time + ($tt - $t));
  $tzmin -= 60 if $test[2] != $gt[2];
  my $tz = abs $tzmin;
  my $min = $tz % 60;
  my $hr = ($tz - $min) / 60;
  $tz = ($tzmin < 0 )
        ? '+' : '-';
  $tz .= sprintf("%02d%02d",$hr,$min);
}

=item * $rv = restore_tarpit(\%tarpit,path2cache_file);

 Restore the memory cache from the file cache.

 returns	true if successful
		false if cache_file won't open

 File Cache is of the form:
   _VERSION:Package::Name version daemon | static
   _CACHEDUMP:date of last cache dump
	# for each src host
   at:ip_addr:sport:dest
   at:ip_addr:sport:dport
   at:ip_addr:sport:ct
   at:ip_addr:sport:last
   at:ip_addr:sport:persist
   at:ip_addr:sport:DShield:dest:dp:time

   bw:number
	# for each scanning (gone) host
   dt:ip_addr:sport:dport
   dt:ip_addr:sport:last
   dt:ip_addr:persist

   ph:time:dport:count

   now:1234567890

   tz:-0800

=cut

# build hash from database file
#
# input:	\%tarpit, $db_file_path_name
# return:	true or false if fail

sub restore_tarpit {
  my ($tp,$dbf) = @_;
  return undef unless open(DB,$dbf);
  my @lines = (<DB>);
  close DB;
  chop @lines;		# no new-lines
  &array2_tarpit($tp,\@lines);	# returns true
}

=item * array2_tarpit(\%tarpit,\@array);

Restore the memory cache from an array of
lines as described for B<restore_tarpit>. The lines
must already be stripped of return characters

Always returns true;

=cut

sub array2_tarpit {
  my ($tp,$ary) = @_;
  foreach(@$ary) {
    next unless $_ =~ /^[a-zA-Z]/;	# must start with alpha tag
    my @arg = split(':', $_);
    next unless @arg > 1;		# must be at least two items
    my $inst = '$tp';
    foreach(0..$#arg -1) {
      $inst .= '->{$arg[' . $_ . ']}';
    }
    $inst .= ' = $arg[' . $#arg . '];';
    eval $inst;
  }
  1;    # return true
}

=item * $rv = log2_mem(\%tarpit,log_line,is_daemon,port_intvls,DShield);

Update memory cache from log output line. Set 
B<is_daemon> if the log output is from daemon STDOUT

In order of minimum CPU overhead:
  Daemon mode or logs created from STDOUT require the
  least cpu overhead. 
  LaBrea -O is more efficient than Labrea -o.
  Logs from STDOUT are more efficient than syslogs.
  Standalone syslogs are more efficient than mixed.

 All log lines used are of the form:

 epoch time (seconds)
 	or
 date text	
	followed by
 [...LaBrea:]		# syslog only
	one of these
 info text bw:	bandwidth (bytes/sec)
	or
 info text:  src_ip src_port txt dest_ip dest_port

 Or more succinctly:
 time text: bandwidth
	or
 time text: src_ip src_port txt dest_ip dest_port

 Returns:	true / false on success / fail

=cut

# update the tarpit cache from log line, see comments below for format
#
# input:	\%tarpit, log_line, is_daemon, port_intvls, DShield_flag
#
#
sub log2_mem {
  my ($tp,$line,$id,$ph,$ds) = @_;
  return undef if (!$id && $line !~ /LaBrea:/);
# valid Labrea log line to parse
  if ( $line =~ /.+bw:\s+(\d+)\s+/ ) {	# if bandwidth line
    $tp->{bw} = $1 || 0;
    return 1;
  }
  # extract time / date
  my $time;
  if ( $line =~ /^(\d+)\s+/ ) {
    $time = $1;
  } else {		# complex form
    require Time::Local;
    return undef unless $line =~ /(.+)\s+(\d+):(\d+):(\d+)\s+(\w+)\s+/;
    @_ = split(/\s+/,$1);
    my $day = pop @_;
    my $mon = pop @_;
    $mon = mon->{"\L$mon"};
    my ($hr,$min,$sec,$yr) = ($2,$3,$4,$5);
    if ($yr =~ /[^\d]/) {
      my ($nowmo,$nowyr) = (localtime(time))[4,5];
      $yr = ($mon > $nowmo)		# roll over to new year??
	? $nowyr -1
	: $nowyr;
    } elsif ( $yr > 1900 ) {	# most likely
      $yr -= 1900;
    } elsif ( $yr < 70 ) {	# yr 2000 or more
      $yr += 100;
    }				# else leave as-is, 70 - 99
    $time = &Time::Local::timelocal($sec,$min,$hr,$day,$mon,$yr);
  }
# extract ip's and ports                     src              sp                 dest               dp
  return undef unless $line =~ /:\s+(\d+\.\d+\.\d+\.\d+)\s+([na\d]+)[^\d]+(\d+\.\d+\.\d+\.\d+)\s+([na\d]+)/;
  $tp->{now} = $time if (! $tp->{now}) || $tp->{now} < $time;
  my ($src,$sp,$dest,$dp) = ($1,$2,$3,$4);
  delete $tp->{dt}->{$src} if $tp->{dt}->{$src};	# remove dead soldiers
  $_ = $tp->{at}->{$src}->{$sp} || ($tp->{at}->{$src}->{$sp} = {});
  $_->{dip}	= $dest;
  $_->{dp}	= $dp;
  $_->{pst}	= ($line =~ /Persist/i) ? 6 : 0;
  $_->{ct}	= $time unless exists $_->{ct};
  $_->{lc}	= $time;
  if ( $ds && $line =~ /Initial/i ) {			# mark for DShield
    $_->{DShield} = {} unless $_->{DShield};
    $_->{DShield}->{$dest} = {} unless $_->{DShield}->{$dest};
    $_->{DShield}->{$dest}->{$dp} = $time;
  }

  if ( $ph ) {			# if port statistics are collected
    $_ = $tp->{pt} || 86400;
    $time -= ($time % $_);
    if (exists $tp->{ph}->{$time}->{$dp}) {
      $tp->{ph}->{$time}->{$dp} += 1;
    } else {
      $tp->{ph}->{$time}->{$dp} = 1;
    }
  }
  return 1;
}

=item * $rv = process_log(\%tarpit,path2log_file,is_daemon,port_intvls);

Update the memory cache from a file with lines of the
form described for B<log2_mem>

Set B<is_daemon> if the output log was created from 
STDOUT of LaBrea or if you can guarantee that
there is nothing in the file except LaBrea lines.

Returns true on success, false if file fails to open

=cut

# process a log file
#
# input:	\%tarpit, $log_file_path_name, is_daemon, port_intvls
# returns:	true or undef on fail
#
sub process_log {
  my ($tp,$logf,$id,$ph) = @_;
  return undef unless open(LOG,$logf);
  $ph = 0 unless $ph;
  while (<LOG>) {
    &log2_mem($tp,$_,$id,$ph);
  }
  close LOG;
  1;
}

=item * $rv=cull_threads(\%tarpit,timeout,scanners,port_intvls,DShield);

Cull aged threads from memory cache. Default time is 600
seconds (10 min). On startup, no culls are done for the cull
time interval to retain old capture time information for
any lingering black hats that may fall back into the tarpit.

See B<daemon> description for B<scanners>, B<port_intvls>

cull_threads updates the time zone of the tarpit cache

appends DShield info to file specified in DShield if present

  returns:	true if threads removed, else false

=cut

# cull threads helper for DShield
# see docs for 'ex_open', condensed version here
#
sub _ex_append {
  my ($LOCK,$fh,$fn) = @_;
  umask 0111;		# sorry about that, needs to be deletable by reader
    return undef unless sysopen $LOCK, $fn . '.flock', O_RDWR|O_CREAT|O_TRUNC;
#       die(&me . ': could not open file exclusive ' . $fn . '.flock');
  unless (flock($LOCK,LOCK_EX)) {
    close $LOCK; 
    return undef;
  }
  unless (sysopen $fh, $fn, O_RDWR|O_APPEND|O_CREAT) {
    close $LOCK;
    return undef;
  }
  my $tmp = select $fh;
  $| = 1;
  select $tmp;
  return 1;   
}

# cull old threads
#
# input:	\%tarpit, timeout_seconds, scanners, port_intervals, DShield_file
#			    default 600
# returns:	1 if threads removed, else 0

sub cull_threads {
  my ($tp,$timeout,$scrs,$ph,$ds) = @_;
  my $rv = 0;
  $scrs = ($scrs && $scrs > 0) ? int($scrs) : 0;
  my %scanners;			# trial dead threads
  my $dso;
  local (*LOCK,*DS);
  $timeout = defaults->{cull} unless $timeout;
  my $now = $tp->{now} || time;
  $tp->{tz} = timezone($now);
  my $expired = $now - $timeout;
  my ($src,$sp,$destdp);
  my $act = $tp->{at} || ($tp->{at} = {});	# pointer to active threads
  my @src = keys %{$act};			# active threads
  foreach $src (@src) {
    my @sp = keys %{$act->{$src}};
    foreach $sp ( sort {
	$act->{$src}->{$a}->{lc} <=> $act->{$src}->{$b}->{lc}
	}@sp) {
# process DShield notifications first
      if ( exists $act->{$src}->{$sp}->{DShield} ) {
	if (! $ds) {						# dshield not active
	  delete $act->{$src}->{$sp}->{DShield};		# don't want these around
	}
	elsif ( $dso || ($dso = _ex_append(*LOCK,*DS,$ds)) ) {	# DShield cache open
	  $_ = $tp->{tz};
	  substr($_,-2,0) = ':';				# insert colon in TZ string
	  my ($tza,$tzb) = split(':',$_);			# crude but effective
	  my $dshield = $act->{$src}->{$sp}->{DShield};
	  foreach my $shieldIP (keys %{$dshield}) {		# foreach dest IP
	    foreach my $shieldPort(keys %{$dshield->{$shieldIP}}) {	# and each target port
	      my($sec,$min,$hr,$md,$mon,$yr) = localtime($dshield->{$shieldIP}->{$shieldPort});
	      $_ = sprintf ("%04d-%02d-%02d %02d:%02d:%02d %+03d:%02d\t",$yr+1900,$mon+1,$md,$hr,$min,$sec,$tza,$tzb);
	      print DS $_,'UserID',$tp->{LaBrea},':',$VERSION,"\t1\t$src\t$sp\t$shieldIP\t$shieldPort\tTCP\tSYN\n";
	    }
	  }
	  delete $act->{$src}->{$sp}->{DShield};		# printed, destroy
	}
      }

      if ( $act->{$src}->{$sp}->{lc} < $expired ) {
	@{$scanners{$src}}{'dp','lc','pst'} = @{$act->{$src}->{$sp}}{'dp','lc','pst'};
	delete $act->{$src}->{$sp};			# remove active expired thread
      }
    }
    if (keys %{$act->{$src}}) {				# do threads remain for this IP?
      delete $scanners{$src};			# yes, dispose of parital deaths
    } else {
      delete $act->{$src};			# no, delete active thread
    }
    $rv = 1;
  }
  if ( $dso ) {		# dshield cache open
    close *DS;
    close *LOCK;
  }
  if ($scrs) {		# if scanners are saved
    my $dead = $tp->{dt} || ($tp->{dt} = {});
# add new dead threads
    foreach (keys %scanners) {
      @{$dead->{$_}}{'dp','lc','pst'} = @{$scanners{$_}}{'dp','lc','pst'};
    }
# remove old dead threads over limit
    if ((@_ = keys %{$dead}) > $scrs) {
      my @dead = sort {
	$dead->{$a}->{lc} <=> $dead->{$b}->{lc};
      } @_;
# extract the oldest dead threads
      splice(@dead,@_-$scrs);
      foreach(@dead) {
	delete $dead->{$_};
      }
      $rv = 1;
    }
  }
  if ( $ph ) {		# if port stats are present
    $_ = $tp->{pt} || 86400;
    my $intvls = $ph * $_;
    my $end = $now - ($now % $_) - $intvls + 1;
    foreach(keys %{$tp->{ph}}) {
      if ($_ < $end) {
	delete $tp->{ph}->{$_};		# drop old port stats
	$rv = 1;
      }
    }
  } elsif (exists $tp->{ph}) {
    delete $tp->{ph};				# remove unwanted port stats
    $rv = 1;
  }
  $rv;
}

=item * $rv = write_cache_file(\%tarpit,path2cache_file,umask,flag);

 Write memory cache to file.
 returns cache text on success, false if file fails to open.

 	umask defaults to 033 if not supplied

 File Cache is of the form:
   _VERSION:Package::Name version daemon | static
   _CACHEDUMP:date of last cache dump

see description above in B<restore_tarpit>

 flag	= true,  append 'daemon' to version
 flag	= false, append 'static' to version

=cut

# helper routine
#
# input:	\$txtstring, \%tarpit, $type
#	type = static or daemon
#
sub _cache2txt {
  my ($txp,$tp,$type) = @_;
  $tp->{now} = time unless $tp->{now};
  $_ = localtime($tp->{now});
# print info
  $$txp = '_VERSION:' . __PACKAGE__ .
	" $VERSION $type\n_CACHEDUMP:$_\n";
  $tp->{bw} = 0 unless $tp->{bw};	# must have a value
  $tp->{tz} = &timezone($tp->{now});
  &recurse_hash2txt($txp,$tp,'');
}

# write new db
#
# input:	\%tarpit,$db_file_path_name [umask], fork
# return:	cache text or false on fail
#
sub write_cache_file {
  my ($tp, $dbf, $umask, $flag) = @_;
  return undef unless $dbf;
  local *DB;
  $flag = ($flag) ? 'daemon' : 'static';
  $umask = 033 unless $umask;
  umask $umask;
  return undef unless open(DB,'>'.$dbf.'.tmp');
  $_ = select DB;
  $| = 1;
  select $_;
  my $cache_txt = '';
  &_cache2txt(\$cache_txt,$tp,$flag);
  print DB $cache_txt;
  close DB;
  return (rename ($dbf.'.tmp', $dbf)) ? $cache_txt : undef;
}

=item * prep_report(\%tarpit,\%hash);

 Prepare arrays of report values from the tarpit memory cache.
 Only the values requested will be filled.

 %hash values:		times in seconds since epoch
 {
 #	teergrubed hosts
	'tg_srcIP'  => \@tgsip,	# B<REQUIRED>
	'tg_sPORT'  => \@tgsp,	# B<REQUIRED>
	'tg_dstIP'  => \@tgdip,
	'tg_dPORT'  => \@tgdp,
	'tg_captr'  => \@tgcap,	# capture epoch time
	'tg_last'   => \@tglst,	# last contact
	'tg_prst'   => \@tgpst,	# type / persistent [true|false]
 #
 #	threads per teergrubed host
	'th_srcIP'  => \@thsip,	# B<REQUIRED>
	'th_numTH'  => \@thnum,	# number threads this IP
 #
 #	capture statistics	# all fields B<REQUIRED>
	'cs_days'  => number of days to show,
	'cs_date'  => \@csdate,	# epoch midnight of capt date
	'cs_ctd'   => \@csctd,	# captured this date
 #
 #	phantom IP's used (from our IP block)
	'ph_dstIP' => \@phdip,	# B<REQUIRED>
	'ph_prst'  => \@phpst,	# type / persistent [true|false]
 #
 #	scanning hosts lost
	'sc_srcIP' => \@scsip,	# B<REQUIRED>
	'sc_dPORT' => \@scdp,	# attacked port
	'sc_prst'  => \@scpst,	# type / persistent [true|false]
	'sc_last'  => \@sclst,	# last contact
 #
 #	port statistics		# all fields B<REQUIRED>
	'port_intvls'  => number of periods to show,
	'ports'     => \@ports,	# scanned port list
	'portstats' => \@portstats,
 # where @portstats = @stats_port1, @stats_port2, etc...

 # always returned
	$hash{tz}	  = timezone, always filled if not present
	$hash{now}	  = epoch time of last load from cache
	$hash{bw}	  = bandwidth always filled
	$hash{total_IPs}  = total teergrubed hosts
	$hash{threads}    = total # of threads
 # conditionally returned
	$hash{LaBrea}     = version if known
	$hash{pt}         = port activity collection interval
	$hash{tg_capt} 	  = active hard captured (need tg_prst)
	$hash{phantoms}	  = total phantoms
	$hash{ph_capt}	  = phantoms that were hard captures
	$hash{sc_total}	  = total dropped scans
	$hash{sc_capt}	  = dropped hard capture (need sc_prst)
}

NOTE: B<prep_report> will fill any subset of the
specified or all if they are all specified

=cut

# helper routine
#
# input:	\%hash, key
# returns:	pointer to cleared array or undef
#
sub _init_pt {
  my ($p,$k) = @_;
  return undef unless exists $p->{$k};
  @{$p->{$k}} = ();
  $p->{$k};
}

# helper routine
#
# input: 	\@array_of_digits, $match
# return:	number of matching digits
#
sub _add_array {
  my ($ary, $mat) = @_;
  my $sum = 0;
  foreach(@{$ary}) {
    ++$sum if $_ == $mat;
  }
  return $sum;
}

sub prep_report {
  my ($tp,$p) = @_;
# establish array pointers / flags
  my ($tgsip,$tgsp,$tgdip,$tgdp,$tgcap,$tglst,$tgpst);
  my ($thsip,$thnum);
  my ($csdays,$csdate,$csctd);
  my ($phdip,$phpst);
  my ($scsip,$scdp,$scpst,$sclst);
  my ($pintvls,$ports,$pstats);

  my $TCP = 6;		# persistent protcol

  $p->{LaBrea} = $tp->{LaBrea} || 'unknown';
  my (@now,%phantoms,%threadays);
  $now[0] = $p->{now} = $tp->{now} || time;
  $tp->{tz} = &timezone($now[0]) unless $tp->{tz};
  my $tz = $tp->{tz};

  if (exists $p->{tg_srcIP} && exists $p->{tg_sPORT}) {
    $tgsip	= $p->{tg_srcIP};
    $tgsp	= $p->{tg_sPORT};
    $tgdip	= &_init_pt($p,'tg_dstIP');
    $tgdp	= &_init_pt($p,'tg_dPORT');
    $tgcap	= &_init_pt($p,'tg_captr');
    $tglst	= &_init_pt($p,'tg_last');
    $tgpst	= &_init_pt($p,'tg_prst');

  }
  if ($thsip = &_init_pt($p,'th_srcIP')) {
    $thnum	= &_init_pt($p,'th_numTH');
  }
  if ($p->{cs_days} && exists $p->{cs_date} && exists $p->{cs_ctd}) {
    $csdays	= $p->{cs_days};
    $csdays	= ($p->{cs_days} && $p->{cs_days} > 1)
	? $p->{cs_days}
	: 2;
    $csdate	= &_init_pt($p,'cs_date');
# default 'capture this date'
    $csctd	= &_init_pt($p,'cs_ctd');
    $now[0] = $p->{now};
    foreach(1..$csdays-1) {
      $now[$_] = $now[$_-1] - 86400;	# previous days
    }
    foreach(0..$#now) {
      $now[$_] = midnight($now[$_],$tz);
    }
  }
  if (&_init_pt($p,'ph_dstIP')) {
    $phdip	= $p->{ph_dstIP};
    $phpst	= &_init_pt($p,'ph_prst');
  }
  if (&_init_pt($p,'sc_srcIP')) {
    $scsip	= $p->{sc_srcIP};
    $scdp	= &_init_pt($p,'sc_dPORT');
    $scpst	= &_init_pt($p,'sc_prst');
    $sclst	= &_init_pt($p,'sc_last');
  }

  my ($tot,$tg,$th,$cs) = (0,0,0,0);	# event counters

  my $act = $tp->{at} || ($tp->{at} = {});

  my @src = sort keys %$act;
  $p->{total_IPs} = @src;		# total hosts teergrubed

  foreach my $src (@src) {		# each black host
    my @sp = sort keys %{$act->{$src}};
    $tot += @sp;
    if ($thsip) {
      $thnum->[$th] = @sp if $thnum;
      $thsip->[$th++] = $src;		# threads per IP report
    }
    foreach my $sp (@sp) {
      $phantoms{$act->{$src}->{$sp}->{dip}}	# prep phantoms report
	= $act->{$src}->{$sp}->{pst} if $phdip;
      if ($csdate) {			# capture report
	my $capt = &midnight($act->{$src}->{$sp}->{ct},$tz);
	$threadays{$capt} = (exists $threadays{$capt}) 
		? $threadays{$capt} + 1
		: 1;
	$cs++;
      }
      if ($tgsip) {			# teergrube report
	$tgdip->[$tg]	= $act->{$src}->{$sp}->{dip} if $tgdip;
	$tgdp->[$tg]	= $act->{$src}->{$sp}->{dp}  if $tgdp;
	$tgcap->[$tg]	= $act->{$src}->{$sp}->{ct}  if $tgcap;
	$tglst->[$tg]	= $act->{$src}->{$sp}->{lc}  if $tglst;
	$tgpst->[$tg]	= $act->{$src}->{$sp}->{pst} if $tgpst;
	$tgsip->[$tg]	= $src;
	$tgsp->[$tg++]	= $sp;
      }
    }
  }
  if ($phdip) {				# complete phantoms report
    $p->{phantoms} = @_ = sort keys %phantoms;
    @{$phdip}	= @_;
    if ($phpst) {
      @{$phpst} = @phantoms{@_};
      $p->{ph_capt} = &_add_array($phpst,$TCP);
    }
  }
  if ($csdate) {			# finish capture report
    my $k = 0;
    foreach(0..$#now-1) {  
      $csdate->[$_]	= $now[$_];
      $csctd->[$_]	= $threadays{$now[$_]} || 0;
      $k 	       += $csctd->[$_];
    }
    $csdate->[$#now]	= $now[$#now];
    $csctd->[$#now]	= $cs - $k;
  }

# build report elements
  $p->{tz} = $tz;
  $p->{bw} = &bandwidth($tp);
  $p->{threads} = $tot;

# fill remaining conditional
  $p->{tg_capt} = &_add_array($tgpst,$TCP) 
	if $tgsip && $tgpst;

# this one is really totally independent
  if ($scsip) {				# dropped scanner report
    my $dead = $tp->{dt} || ($tp->{dt} = {});
    $p->{sc_total} = @{$scsip} = @_= sort keys %$dead;
    foreach(0..$#_) {
      $scdp->[$_]	= $dead->{$_[$_]}->{dp}	 if $scdp;
      $sclst->[$_]	= $dead->{$_[$_]}->{lc}	 if $sclst;
      $scpst->[$_]	= $dead->{$_[$_]}->{pst} if $scpst;
    }
    $p->{sc_capt} = &_add_array($scpst,$TCP) if $scpst;
  }

# ports also totally independent
  if (exists $p->{port_intvls} &&
	$p->{port_intvls} &&
	exists $p->{ports} &&
	exists $p->{portstats}) {	# port statistics report

    $pintvls = $p->{port_intvls};
    $p->{pt} = $tp->{pt} || 86400;
    $ports = $p->{ports};
    $pstats = $p->{portstats};
    @now = $p->{now};
    $now[0] -= ($now[0] % $p->{pt});
    foreach(1..$pintvls-1) {
      $now[$_] = $now[$_ -1] - $p->{pt};	# fill now with intvls of interest
    }
  # get port numbers so we have them all
    my @pnums;
    foreach (@now) {
      push @pnums, (keys %{$tp->{ph}->{$_}})
	if exists$tp->{ph}->{$_};
    }
    @_ = sort { $a <=> $b } @pnums;
    @pnums = ();
    my $lastp = 0;			# no port zero
    foreach (@_) {			# remove duplicates
      next if $_ == $lastp;
      $lastp = $_;
      push @pnums, $lastp;
    }
    @$ports = @pnums;			# export ports
    @$pstats = ();			# clear stats
    foreach(0..$#pnums) {		# fill stats array
      my $i = $pintvls * $_;		# index into array for port
      foreach my $d (0..$#now) {	# get data for each time slice
        ${$pstats}[$i+$d] = $tp->{ph}->{$now[$d]}->{$pnums[$_]} || 0;
      }
    }
  }
}

=item * $rv = find_old_threads(\%tarpit,\%report,$age);

  Report only aged threads

  input:        \%tarpit, \%report, age_in_days 
  returns:      false = fail, or nothing to report
		true  = number of items
		and fills \%report

	%report = (
	    [text string]	 [time since epoch]
	  ip.addr:sp -> dp	=> time captured,
		....

=back

=cut    

sub find_old_threads {
  my ($tp,$rpt,$age,$testime) = @_;
  $age *= 86400;				# age in days
  my $now = $testime || time;
  my $act = $tp->{at} || ($tp->{at} = {});	# pointer to active threads
  my @src = keys %{$act};			# active threads
  foreach my $src (@src) {
    my @sp = keys %{$act->{$src}};                              
    foreach my $sp (@sp) {
      my $ct = $act->{$src}->{$sp}->{ct};
      $rpt->{"${src}:${sp} -> $act->{$src}->{$sp}->{dp}"} = $ct
	if $ct + $age < $now;
    }
  }
  return scalar keys %$rpt;
}

#=item * $rv = refresh_cache_file($path2_pid_file,$path2_cache_file,$age);
#
#  DEPRECATED and REMOVED
#
#  Refresh (update) the cache file from the daemon memory
#  if the cache file is older than $age seconds. Ages of
#  zero or less force an immediate update.
#
#  Returns 0 (false) if the cache is current or when updated,
#  otherwise returns the ERRNO for the fault
#
#  WARNING: this only works if you have the necessary
#  file and daemon permissions. Normal usage to gain access
#  memory cache would be to read from the daemon pipe.
#
## conditionally refresh the cache file
##
## input:	$path2_pid_file, $path2_cache_file, $age
## returns:	errno or 0 on 'up 2 date'
##
#sub refresh_cache_file {
#  my ($pid,$p2cf,$age) = @_;
#  return ($! = ENOENT) unless -e $pid;	# validate pid file
#  return ($! = EACCES) unless -r $pid;
#  $age = defaults->{min_age} 
#	unless $age &&
#	  int($age) > 0;
#  $age = time - $age;				# benchmark time
#  if ( -e $p2cf ) { 				# cache file is present
#    return ($! = EACCES) unless -r $p2cf;	# validate it
#    return 0 if (stat($p2cf))[9] >= $age	# return if current
#  }
#  local(*F,*W);
#  return ($! = EACCES) unless open(F,$pid);
#  read(F, $pid, 100);				# slurp PID file
#  close F;
#  return EINVAL unless ($pid =~ /(\d+)/);	# pid -> $1
#  return $! unless kill 0, $pid;		# check for process alive
#  kill 1, $1;					# send HUP to daemon
#  pipe(F,W);					# open NULL handle
#  my $rin = '';
#  my $rout;
#  vec($rin,fileno(F),1) = 1;
#  my $timer = defaults->{s_timeout} || .1;	# may not be zero
#  my $hup_timeout = int(defaults->{hup_timeout} / $timer);
#  while(1) {
#    $_ = select($rout=$rin,undef,undef,$timer);
#    read(F,$_,1) if $_;				# should never happen
#    if ((stat($p2cf))[9] >= $age ) {
#      $! = 0;
#      last;
#    }
#    unless ($hup_timeout-- > 0) {
#      $! = ETIME;
#      last;
#    }
#  }
#  close W;
#  close F;
#  $!;
#}
#

=head1 DEPENDENCIES

        Net::Whois::IP version 0.35     
	Net::Netmask version 1.8 or higher
        LaBrea version 2.4b3 or higher

See the INSTALL document for complete information

=head1 EXPORT

  None by default.

=head1 EXPORT_OK

	recurse_hash2txt
	daemon
	bandwidth
	midnight
	timezone
	tz2_sec
	their_date
	restore_tarpit
	log2_mem
	process_log
	cull_threads
	write_cache_file
	prep_report
	find_old_threads
	array2_tarpit

=head1 COPYRIGHT

Copyright 2002 - 2008, Michael Robinton & BizSystems
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

perl(1), LaBrea::Codes(3), LaBrea::Tarpit::Get(3), LaBrea::Tarpit::Report(3),
LaBrea::Tarpit::Util(3), LaBrea::Tarpit::DShield(3)

=cut

1;
