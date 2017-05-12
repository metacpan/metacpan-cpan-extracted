#!/usr/bin/perl
#
# sc_recoverdb.pl
#
# version 1.01 6-8-04
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
use lib qw(blib/lib blib/arch);
use IPTables::IPv4::DBTarpit::Tools qw(
	$DBTP_ERROR
	db_strerror
	inet_ntoa
);
use Mail::SpamCannibal::SiteConfig;
use Mail::SpamCannibal::ScriptSupport qw(
	dbjob_recover
);
use Mail::SpamCannibal::PidUtil qw(
	is_running
);

sub usage {
  print STDERR $_[0],"\n\n" if $_[0];
  print STDERR qq|
Syntax:	$0 [-v] [-p path] [-t] db_file

	-d	debug, print trace info
	-p	optional non-standard path
		(default /var/run/dbtarpit)
	-t	db_file has text mode data
		(needed only for non-standard
		file names not in siteconfig)
	-v	optional verify only switch
		(do not write db_file.new)

All DB jobs must be stopped to run recovery
on a DB file. NOT applicable to 'verify mode'.

|;
  exit 1;
}

usage unless @ARGV;

my $DEBUG	= 0;
my $VERIFY	= 0;
my $FORCETXT	= 0;
my($path,$dbfile);

while ($_ = shift @ARGV) {
  if ($_ eq '-d') {
    $DEBUG = 1;
    next;
  }
  elsif ($_ eq '-p') {
    $path = shift || die "no path name found\n\n";
    next;
  }
  elsif ($_ eq '-t') {
    $FORCETXT = 1;
    next;
  }
  elsif ($_ eq '-v') {
    $VERIFY = 1;
    next;
  }
  else {
    $dbfile = $_;
  }
}

usage("no dbfile found\n") unless $dbfile;

my $newfile = $dbfile .'.new';

my $CONFIG = new Mail::SpamCannibal::SiteConfig;

# only open the db's we will need
my ($environment,$tarpit,$archive,$contrib,$evidence) = (
	$CONFIG->{SPMCNBL_ENVIRONMENT},
	$CONFIG->{SPMCNBL_DB_TARPIT},
	$CONFIG->{SPMCNBL_DB_ARCHIVE},
	$CONFIG->{SPMCNBL_DB_CONTRIB},
	$CONFIG->{SPMCNBL_DB_EVIDENCE},
);

$environment = $path if $path;
my %default = (
        dbhome  => $environment,
);

$_ = $environment .'/'. $dbfile;
unless (-e $_) {
  usage("no such file $_
try one of $environment
$tarpit, $archive, $contrib, $evidence");
}

if ($FORCETXT || $dbfile eq $contrib || $dbfile eq $evidence) {
  $default{txtfile} = [$dbfile];
  unless ($VERIFY) {
    push @{$default{txtfile}}, $newfile;
  }
} else {
  $default{dbfile} = [$dbfile,$newfile];
  unless ($VERIFY) {
    push @{$default{dbfile}}, $newfile;
  }
}

my @evfiles;
unless ($VERIFY) {
  opendir(D,$environment) or die "could not open db environment directory $environment\n\n";
  my @jobs = grep(/\.pid$/,readdir(D));
  @evfiles = grep(/^__/,readdir(D));
  closedir D;
  foreach (@jobs) {
    die "running DB jobs, stop all DB jobs before recovery of DB files\n\n"
	if is_running($environment .'/'. $_);
  }
  dbjob_recover(\%default);
}

my $tool = new IPTables::IPv4::DBTarpit::Tools(%default) ||
	die "could not open database ${environment}/$dbfile\n\n";

my $recno = 1;

print STDERR ($VERIFY) ? 'verifying ' : 'checking ';
print STDERR "\t",$tool->nkeys($dbfile), " records...\n";
while (1) {
  my($key,$txt) = $tool->getrecno($dbfile,$recno);
  if ($key) {
    print STDERR "$recno\t ", inet_ntoa($key), "\n" if $DEBUG;
    $tool->put($newfile,$key,$txt) unless $VERIFY
  }
  else {
    last if $recno >= $tool->nkeys($dbfile);
    print "bad record $recno\t ", db_strerror($DBTP_ERROR),"\n";
  }
  ++$recno;
}

--$recno;
my $records = $tool->nkeys($dbfile);

if ($VERIFY) {
  print STDERR "verified\t$recno records\n";
  print STDERR "ERROR: found $records in $dbfile\n"
	unless $records == $recno;
} else {
  print STDERR "$dbfile $recno -> $newfile ",$tool->nkeys($newfile),"\n";
}

$tool->closedb;

unless ($VERIFY) {
  $_ = $environment .'/'. $dbfile;
  my($mode,$uid,$gid) = (stat($environment .'/'. $dbfile))[2,4,5];
  $mode &= 0777;
  chmod $mode, $environment .'/'. $newfile;
  chown $uid, $gid, $environment .'/'. $newfile;
  foreach (0..$#evfiles) {
    $evfiles[$_] = $environment .'/'. $evfiles[$_];
  }
  unlink @evfiles;		# delete environment
}
