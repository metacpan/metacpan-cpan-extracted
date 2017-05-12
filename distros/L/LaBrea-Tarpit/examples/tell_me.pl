#!/usr/bin/perl
#
# tell_me.pl
#
my $version = '2.01';	# 5-18-02, michael@bizsystems.com
#
# GPL'd, see Copyright notice in the package README file
#
use strict;
#use diagnostics;

use LaBrea::NetIO qw (fetch);
use LaBrea::Tarpit qw(find_old_threads array2_tarpit);
use LaBrea::Tarpit::DShield qw(mail2_Q process_Q);

##########################
### YOU MUST CONFIGURE ###
##########################

my $config	= {
# where is the host??
#	'd_port'	=> '8686',              # default local comm port
	'd_host'	=> 'localhost',		# daemon host
#	'd_timeout'	=> default 180,
#	     just the directory is needed for mail QUEUE (with trailing /)
	'DShield'	=> '/var/tmp/DShield.cache',	# path/to/file
	'To'		=> 'your@emailaddy',
	'From'		=> 'root@localhost',
#	'Reply-To'	=> 'johns-work@foo.com',	# optional
# either one or more working SMTP server's, your's or their's
#	'smtp'		=> 'smtp.serverA.com,smtp.serverB.com',
# or a sendmail compatible mail transport command
	'sendmail'	=> '/usr/lib/sendmail -t -oi',
};

my $daemon_timeout	= 180;			# seconds

##########################
###  END CONFIG ITEMS  ###
##########################

my $age		= $ARGV[0] || 60;	# days, tell me about those older than this

my (%message,%tarpit,@response);
my $msg = fetch($config,\@response,'active');
unless ( $msg ) {			# error ??
  chop @response;			# remove endlines
  array2_tarpit(\%tarpit,\@response);
  if ( find_old_threads(\%tarpit,\%message,$age) ) {
    foreach(sort { $message{"$a"} <=> $message{"$b"} } keys %message) {
      $msg .= $_ . ' ' . scalar localtime($message{$_}) . "\n";
    }
  }
} else {	# could not reach daemon
  $msg = "failed to contact daemon\n" .
  $config->{d_host} . "\n" .
  scalar localtime(time) . "\n";
}

if ($msg) {
  if ( ($_ = mail2_Q($config,\$msg,'Old Threads')) ) {
    print STDERR $_,"\n";
  }
  elsif ( ($_ = process_Q($config)) ) {
    print STDERR $_,"\n";
  }
}
