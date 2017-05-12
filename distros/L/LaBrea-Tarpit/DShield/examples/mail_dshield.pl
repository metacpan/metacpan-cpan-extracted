#!/usr/bin/perl
#
# mail_dshield.pl
#
my $version = '1.03';	# 5-6-02, michael@bizsystems.com
#
# GPL'd, see Copyright notice in the package README file
#
use strict;
#use diagnostics;

use LaBrea::Tarpit::DShield qw(
	move2_Q
	deliver2_DShield
);

##########################
### YOU MUST CONFIGURE ###
##########################

my $config = {
	'DShield'	=> '/var/tmp/DShield.cache',	# path/to/file
	'UserID'	=> '0',				# DShield UserID
	'To'		=> 'reports@dshield.org',
	'From'		=> 'john.doe@foo.com',
#	'Reply-To'	=> 'johns-work@foo.com',		# optional
#	'Obfuscate'	=> 'complete or partial',		# optional
#	'SrcIgnore'	=> ['10.11.12.0/23', '10.11.16.0/23'],	# optional

# either one or more working SMTP server's, your's or their's
#	'smtp'		=> 'iceman.dshield.org,mail.euclidian.com',
# or a sendmail compatible mail transport command
	'sendmail'	=> '/usr/lib/sendmail -t -oi',
};

if ( ($_ = move2_Q($config)) ) {
  print STDERR $_,"\n";
}
elsif ( ($_ = deliver2_DShield($config)) ) {
  print STDERR $_,"\n";
}

