#!/usr/bin/perl
#
# sc_abuse.pl
#
# version 1.09, 4-23-10
#
#################################################################
# WARNING! do not modify this script, make one with a new name. #
# This script will be overwritten by subsequent installs of     #
# SpamCannibal.                                                 #
#################################################################
#
# Copyright 2003 - 2010 Michael Robinton <michael@bizsystems.com>
   
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
   
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
   
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#

use strict;
#use diagnostics;
use lib qw(blib/lib blib/arch);
use Mail::SpamCannibal::SiteConfig;
use Mail::SpamCannibal::ScriptSupport 0.09 qw(
	mailcheck
	list2NetAddr
	abuse_host
	doINCLUDE

	matchNetAddr
);
use Mail::SpamCannibal::SMTPsend qw(
	sendmessage
);
use Mail::SpamCannibal::PidUtil qw(
	get_script_name
	make_pidfile
);
use Fcntl qw(:DEFAULT :flock);

sub usage {
  print STDERR $_[0],"\n\n" if $_[0];
  print STDERR qq|
Syntax:	$0 path/to/config.file
    or
	$0 -d path/to/config.file
	$0 -v path/to/config.file
|, q|
The -d switch causes the normal output to
be sent to the REPORT target email address
rather than to the target abuse address

The -v switch sends debug error messages to 
the REPORT target email address (if present)

This script sends it's "message" to abuse@domain.name of
the first remote MTA found in the headers of the "message".
The script decodes the last character in the To: field of 
it's own received headers to determine the length of the 
domain to append to "abuse@" to determine the target address.

i.e. for some.spam.domain.com
To: localabuse	2 domain fields	'abuse@domain.com'
To: localabuse1	2 domain fields	'abuse@domain.com'
To: localabuse2	2 domain fields	'abuse@domain.com'
To: localabuse3	3 domain fields	'abuse@spam.domain.com'
To: localabuse4	4 domain fields	'abuse@some.spam.domain.com'

Also see the comments for the ABUSE key in sc_mailfilter.conf
to send abuse messages to multiple destination addresses or a
destination address that differs from the offending domain.

|;
  exit 1;
}

# set real to effective
$< = $>;

$| = 1;
my $X = 0;
my $DEBUG = 0;
my $VERBOSE = 0;
my $config;
my $blacklist;

usage() unless @ARGV;

while ($_ = shift @ARGV) {
  if ($_ eq '-x') {
    $X = 1;
    $DEBUG = 1;  
    $VERBOSE = 2;
    next;
  }
  elsif ($_ eq '-d') {
    $DEBUG = 1;
    $VERBOSE = 1;
    next;
  }
  elsif ($_ eq '-v') {
    $VERBOSE = 1;
    next;
  } else {
    $config = $_;
  }
}

usage ('no config file') unless $config;

my $MAILFILTER = doINCLUDE($config);
usage ('could not load config file')
	unless $MAILFILTER;

usage ('corrupted config file')
	unless keys %$MAILFILTER
	&& $MAILFILTER->{BLCONFIG}
	&& exists $MAILFILTER->{MXhosts}
	&& ref $MAILFILTER->{MXhosts} eq 'ARRAY'
	&& @{$MAILFILTER->{MXhosts}};

my $DNSBL = doINCLUDE($MAILFILTER->{BLCONFIG});
usage ('could not load BlackList file')
	unless $DNSBL;

usage ('corrupted corrupted BlackList file')
	unless  keys %$DNSBL
	&& exists $DNSBL->{IGNORE}
	&& ref $DNSBL->{IGNORE} eq 'ARRAY'
	&& @{$DNSBL->{IGNORE}};

my $CONFIG = new Mail::SpamCannibal::SiteConfig;

my $environment = $CONFIG->{SPMCNBL_ENVIRONMENT};

my $pidfile = $environment .'/'. get_script_name() .'.'. $$ .'.pid';
make_pidfile($pidfile);

my @NAignor;
list2NetAddr($DNSBL->{IGNORE},\@NAignor)
	or usage('missing IGNORE array in BlackList file');

my $emailfmt = '^.+\@.+\..+';

my $localvars = {
	dbhome	=> $environment,
};

my $run = 1;
local $SIG{TERM} = sub { $run = 0 };

# this is set up so that it can be enhanced to pass a file handle in a
# loop for batch message processing
#
my $admin = ($MAILFILTER->{REPORT} &&
            $MAILFILTER->{REPORT} =~ /$emailfmt/)
	? $MAILFILTER->{REPORT} : '';
my $fh = *STDIN;
{	# while loop
  if ( $run ) {
    if ((@_ = abuse_host($fh,$MAILFILTER,$DNSBL,$localvars,\@NAignor)) &&
     ( $X || $admin)) {
      my($verb,$err) = @_;
      if ($VERBOSE || $verb > 1) {
	$err = "Subject: debug $0\n\n$err"
		unless $err =~ /Subject:/;
	if ($X) {
          print $err,"\n";
	} elsif ($run) {
	  sendmessage($err,$admin)
	  	if $VERBOSE || $verb > 1;
	}
      }
    }
    else {
      my $target = lc $localvars->{to};
      my @target;
      if (exists $MAILFILTER->{ABUSE} &&
	  grep($target eq lc $_,keys %{$MAILFILTER->{ABUSE}})) {
	foreach (keys %{$MAILFILTER->{ABUSE}}) {
	  next unless $target eq lc $_;
	  $target = $_;
	  last;
	}
	@target = @{$MAILFILTER->{ABUSE}->{$target}};
      }
      @target = ('abuse@'. $target)
	unless @target;

# if copies of spam need to be sent to standard addresses, add them now
      if (exists $MAILFILTER->{spamCC} && @{$MAILFILTER->{spamCC}}) {
	push @target, @{$MAILFILTER->{spamCC}};
      }
      foreach $target (@target) {
	next unless $target =~ /$emailfmt/;
	my $to = ($DEBUG) ? $admin : $target;
	sendmessage('X-abuse-rcpt: '. $localvars->{ab2} ."\n".
		"X-abuse-target: $target\n".
		'Subject: spam from '. $localvars->{shost} ."\n\n". $localvars->{SPAM},
		$to,
		$admin
	);
      }
      if (exists $MAILFILTER->{SPAMCOUNT} &&					# spam counting active
	  $MAILFILTER->{SPAMCOUNT} =~ m|.+/| &&					# extract directory portion
	  -d $& &&								# directory exists
	  sysopen(FILE,$MAILFILTER->{SPAMCOUNT},O_RDWR|O_CREAT) &&		# open counter file
	  ($_ = select(FILE)) && ($| = 1) && (select $_)) {			# flush file handle
	if (flock(FILE, LOCK_EX)) {						# block until locked
	  $_ = <FILE> || 0;							# last count
	  seek(FILE,0,0);							# rewind file
	  print FILE $_+1,"\n";							# increment count
	  truncate(FILE, tell(FILE));
	}      
	close FILE;
      }
    }
  }
} # end while

unlink $pidfile;

