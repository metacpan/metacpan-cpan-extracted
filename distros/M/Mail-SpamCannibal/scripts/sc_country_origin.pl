#!/usr/bin/perl
#
# sc_CountryOrigin.pl
#
# version 1.05 2-5-04
#
#################################################################
# WARNING! do not modify this script, make one with a new name. #
# This script will be overwritten by subsequent installs of     #
# SpamCannibal.                                                 #
#################################################################
#
# Copyright 2004, Michael Robinton <michael@bizsystems.com>
   
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

use IPTables::IPv4::DBTarpit::Tools qw(
	inet_ntoa
);
use Mail::SpamCannibal::SiteConfig;

use Mail::SpamCannibal::PidUtil 0.02 qw(
	if_run_exit
	zap_pidfile
);

my $CONFIG = new Mail::SpamCannibal::SiteConfig;

# only open the db's we will need
my ($environment,$tarpit) = (
	$CONFIG->{SPMCNBL_ENVIRONMENT},
	$CONFIG->{SPMCNBL_DB_TARPIT},
);

my %default = (
        dbhome  => $environment,
        dbfile  => [$tarpit],
);

die <<EOF if -e $CONFIG->{DBTP_ENVHOME_DIR} .'/'. 'blockedBYwatcher';
##############################################

  startup blocked by DB watcher process

##############################################
EOF

if_run_exit($environment,'already running');

{
  require Geo::IP::PurePerl;
  my $tool = new IPTables::IPv4::DBTarpit::Tools (
	dbfile  => [$tarpit],
	dbhome	=> $environment,
  );
  
  my ($netaddr, $ip);
  my $ccnt = {};
  my $cursor = 1;		# first record number == 1

  while ($netaddr = $tool->getrecno($tarpit,$cursor)) {
    $cursor++;
    last unless $netaddr && ($ip = inet_ntoa($netaddr));
    my $cc = Geo::IP::PurePerl->new()->country_code_by_addr($ip);
    if (exists $ccnt->{$cc}) {
      $ccnt->{$cc}++;
    } else {
      $ccnt->{$cc} = 1;
    }
  }
  $tool->closedb;

  foreach (sort { $ccnt->{$b} <=> $ccnt->{$a} } keys %$ccnt) {
    print "$_\t$ccnt->{$_}\n";
  }
}

zap_pidfile($environment);


