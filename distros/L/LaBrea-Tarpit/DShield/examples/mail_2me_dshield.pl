#!/usr/bin/perl
#
# mail_2me_dshield.pl
#
my $version = '2.01';	# 7-6-04, michael@bizsystems.com, pere@hungry.com
#
# GPL'd, see Copyright notice in the package README file
#
use strict;
#use diagnostics;

use Net::NetMask;
use LaBrea::Tarpit::DShield qw(
	move2_Q
	deliver2_DShield
);

=pod

Thanks to Petter Reinholdtsen <pere@hungry.com> for this
improvement. This script allows our labrea reports to be sent to two
locations, depending on their source.  For local IP addresses, they are
mailed to ourself.  For remote addresses they are passed on to DShield.

=cut

##########################
### YOU MUST CONFIGURE ###
##########################

my $dshield_config = {
	'DShield'	=> '/site/LaBrea/DShield.cache',
	'UserID'	=> 'XXXXXXXXX',
	'To'		=> 'reports@dshield.org',
	'From'		=> 'XXXXXXXXX',
	'SrcIgnore'	=> ['129.240.0.0/16'],
	'sendmail'	=> '/usr/lib/sendmail -t -oi',
};
my $uio_config = {
	'DShield'	=> '/site/LaBrea/DShield.cache',
	'UserID'	=> 'XXXXXXXXX',
	'To'		=> 'root@local.domain',
	'From'		=> 'XXXXXXXXX',
	# Ignore all except 129.240/16
	'SrcIgnore'	=> [
			range2cidrlist("0.0.0.0","129.239.255.255"),
			range2cidrlist("129.241.0.0","255.255.255.255"),
			],
	'sendmail'	=> '/usr/lib/sendmail -t -oi',
};

# One report without clearing the cache
if ( ($_ = move2_Q($uio_config, 1)) ) {
  print STDERR $_,"\n";
}
elsif ( ($_ = deliver2_DShield($uio_config)) ) {
  print STDERR $_,"\n";
}
# Last report clear the cache
if ( ($_ = move2_Q($dshield_config)) ) {
  print STDERR $_,"\n";
}
elsif ( ($_ = deliver2_DShield($dshield_config)) ) {
  print STDERR $_,"\n";
}
