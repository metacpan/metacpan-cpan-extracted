#!/usr/bin/perl
#
# sc_initdb.pl
#
# version 1.03, 9-14-03
#
#################################################################
# WARNING! do not modify this script, make one with a new name. #
# This script will be overwritten by subsequent installs of     #
# SpamCannibal.                                                 #
#################################################################
#
# Copyright 2003, Michael Robinton <michael@bizsystems.com>
   
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
use vars qw($CONFIG);
use lib qw(blib/lib blib/arch);
use IPTables::IPv4::DBTarpit::Tools 1.05;

unless (eval {require Mail::SpamCannibal::SiteConfig;}) {
  print "\nYou must first install SpamCannibal before running 'initdb.pl'\n\n";
  exit 1;
}

$CONFIG = new Mail::SpamCannibal::SiteConfig;

my ($name,$passwd,$uid,$gid) = getpwnam($CONFIG->{SPAMCANNIBAL_USER});
unless ($uid && $gid) {
	print "\nCould not find user '$CONFIG->{SPAMCANNIBAL_USER}',
check your intallation and try again\n\n";
  exit;
}

# make the directory
mkdir $CONFIG->{SPMCNBL_ENVIRONMENT}
	unless -e $CONFIG->{SPMCNBL_ENVIRONMENT};

my %default = (
	dbhome	=> $CONFIG->{SPMCNBL_ENVIRONMENT},
	dbfile	=> [$CONFIG->{SPMCNBL_DB_TARPIT}, $CONFIG->{SPMCNBL_DB_ARCHIVE}],
	txtfile	=> [$CONFIG->{SPMCNBL_DB_CONTRIB}, $CONFIG->{SPMCNBL_DB_EVIDENCE}],
	umask	=> $CONFIG->{SPAMCANNIBAL_UMASK},
);

if (@ARGV && $ARGV[0] =~ /^\-R$/) {		# set run recovery if -R switch
  $default{recover} = 1;
}

# make the DB files
my $dbp = new IPTables::IPv4::DBTarpit::Tools(%default);
$dbp->closedb;

unless (opendir(D,$CONFIG->{SPMCNBL_ENVIRONMENT})) {
	print "\nCould not open '$CONFIG->{SPMCNBL_ENVIRONMENT}',
please check your intallation\n\n";
  exit;
}

my @files = grep(!/^\./,readdir(D));
closedir D;

foreach(0..$#files) {
  $files[$_] = $CONFIG->{SPMCNBL_ENVIRONMENT}.'/'.$files[$_];
}

# set ownership of the files to spamcannibal user, group
chown $uid, $gid, @files;

# set mode of files to 666 based on umask in case some files already exist
my $mask = 0777 ^ $CONFIG->{SPAMCANNIBAL_UMASK};
$mask &= 0666;
chmod $mask, @files;

# set ownership of the environment directory to spamcannibal user, group
chown $uid, $gid, $CONFIG->{SPMCNBL_ENVIRONMENT};
