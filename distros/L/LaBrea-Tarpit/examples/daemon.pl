#!/usr/bin/perl
#
# daemon.pl
#
# version 1.05 5-18-02, michael@bizsystems.com
#
use strict;
use LaBrea::Tarpit qw(daemon);

# set these for your system
#
my $config = {
  'LaBrea'	=> '/usr/local/bin/LaBrea -z -v -p 1000 -h -i eth0 -b -O 2>&1',
#  'LaBrea'	=> '/usr/local/bin/LaBrea -z -v -p 1000 -h -i eth1 -b -O 2>&1',
#  'd_port'	=> '8686',		# default local comm port
  'd_host'	=> 'localhost',		# defaults to ALL interfaces 
					# NOT recommended
  'allowed'	=> 'localhost',		# default is ALL
					# recommend only 'localhost'
  'pid'		=> '/var/run/labrea.pid',
  'cache'	=> '/var/tmp/labrea.cache',
  'DShield'	=> '/var/tmp/DShield.cache',
#  'umask'	=> default 033,		# cache_file umask
#  'cull'	=> default 600,		# seconds to keep old threads
  'scanners'	=> 100,			# keep this many dead threads
#  'port_timer'	=> default 86400,	# seconds per collection period
  'port_intvls' => 30,			# keep #nintvls of port stats
					# 0 or missing disables
					# this can take lots of memory
# optional exclusion information (required if files exist)
  'config'	=> '/etc/LaBreaConfig',
#	or
# 'config'	=> 'LaBrea.cfg',	# windoze (untested)
#	or
# 'config'	=> ['/etc/LaBreaExclude','/etc/LaBreaHardExclude'],
};

#	HUP (1) /var/run/labrea.pid
#	to produce
#	/var/tmp/labrea.cache
#
#	TERM (15) /var/run/labrea.pid
#	to write 
#	/var/tmp/labrea.cache
#	then  exit. 
#
#	DO NOT USE
#	KILL (9) this will result in the perl daemon
#	exiting with no cache file dump and the 
#	LaBrea daemon will continue to run uselessly.
#
#	See the other samples for generating reports
#	from 'labrea.cache'

daemon ($config);
