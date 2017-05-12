#!/usr/bin/perl
#
# sc_BLcheck.pl
#
# version 1.07, 11-16-08
#
#################################################################
# WARNING! do not modify this script, make one with a new name. #
# This script will be overwritten by subsequent installs of     #
# SpamCannibal.                                                 #
#################################################################
#
# Copyright 2003 - 2008, Michael Robinton <michael@bizsystems.com>
   
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
use Mail::SpamCannibal::ScriptSupport 0.40 qw(
	BLcheck
	doINCLUDE
	block4zonedump
);

use Mail::SpamCannibal::PidUtil 0.02 qw(
	if_run_exit
	zap_pidfile
);

sub usage {
  print STDERR $_[0],"\n\n" if $_[0];
  print STDERR qq|
Syntax:	$0 path/to/config.file
    or
	$0 -d path/to/config.file
	$0 -v path/to/config.file

The -d switch allows you to see what the 
script will do without any db updates 
taking place. The -v switch will print
the scripts actions to the screen. 
-v -v does it more verbosely.
The -d switch implies a single -v.

|;
  exit 1;
}

$| = 1;
my $DEBUG = 0;
my $VERBOSE = 0;
my $config;

while ($_ = shift @ARGV) {
  if ($_ eq '-d') {
    $DEBUG = 1;
    $VERBOSE += 1;
    next;
  }
  elsif ($_ eq '-v') {
    $VERBOSE += 1;
    next;
  }
  $config = $_;
}

usage() unless $config;

my $DNSBL = doINCLUDE($config);
usage('could not load config file')
	unless $DNSBL;

usage('corrupted config file')
	unless  keys %$DNSBL;

my $CONFIG = new Mail::SpamCannibal::SiteConfig;

# only open the db's we will need
my ($environment,$tarpit,$archive,$contrib,$evidence) = (
	$CONFIG->{SPMCNBL_ENVIRONMENT},
	$CONFIG->{SPMCNBL_DB_TARPIT},
	$CONFIG->{SPMCNBL_DB_ARCHIVE},
	$CONFIG->{SPMCNBL_DB_CONTRIB},
	$CONFIG->{SPMCNBL_DB_EVIDENCE},
);

my %default = (
        dbhome  => $environment,
        dbfile  => [$tarpit,$archive],
        txtfile => [$contrib,$evidence],
	DEBUG	=> $DEBUG,
	VERBOSE	=> $VERBOSE,
);

die <<EOF if -e $CONFIG->{DBTP_ENVHOME_DIR} .'/'. 'blockedBYwatcher';
##############################################

  startup blocked by DB watcher process

##############################################
EOF

if_run_exit($environment,'already running');

block4zonedump($environment);

my $err = BLcheck($DNSBL,\%default);
zap_pidfile($environment);
usage($err) if $err;

