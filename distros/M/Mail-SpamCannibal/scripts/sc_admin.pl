#!/usr/bin/perl
#
# sc_admin.pl
#
# version 1.06, 4-30-08
#
#################################################################
# WARNING! do not modify this script, make one with a new name.	#
# This script will be overwritten by subsequent installs of 	#
# SpamCannibal.							#
#################################################################
#
# utility to manually 
# get, insert, remove records or view entire database
# for DBTarpit databases and related databases
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
#use diagnostics;
use lib qw(./ blib/lib blib/arch);
use IPTables::IPv4::DBTarpit::Tools qw(
	inet_aton
	inet_ntoa
	$DBTP_ERROR
	db_strerror
);
use Mail::SpamCannibal::ScriptSupport qw(
	unpack_contrib
);
use Mail::SpamCannibal::SiteConfig;

my $DBCONFIG = new Mail::SpamCannibal::SiteConfig;

sub syntax {
  my($comment) = @_;
  $comment = '' unless $comment;
  print <<EOF;
$comment

Syntax:	sc_admin.pl db_name (action) [dot.quad.ip.addr] [stuff]
	(or) [stuff]
	     [.]

  sc_admin.pl  db_name	get	dot.quad.ip.addr
  sc_admin.pl  db_name  recno   record number
  sc_admin.pl  db_name insert	dot.quad.ip.addr stuff...
  sc_admin.pl  db_name delete	dot.quad.ip.addr
  sc_admin.pl  db_name zap	key (unconstrained delete)
  sc_admin.pl  db_name view
  sc_admin.pl  db_name search	"search string"
  sc_admin.pl  db_name clear
    and
		where db_name is one of
EOF

  print qq|	|,	$DBCONFIG->{SPMCNBL_DB_TARPIT}, ', ',
			$DBCONFIG->{SPMCNBL_DB_ARCHIVE}, ', ',
			$DBCONFIG->{SPMCNBL_DB_CONTRIB}, ', or ',
			$DBCONFIG->{SPMCNBL_DB_EVIDENCE}, q|

  for "|, 	$DBCONFIG->{SPMCNBL_DB_TARPIT}, '" and "',
		$DBCONFIG->{SPMCNBL_DB_ARCHIVE}, q|" there are no arguments 
	for "insert" except dot.quad.ip.addr,

  for "|, 	$DBCONFIG->{SPMCNBL_DB_CONTRIB}, q|" the arguments are (in order):
	addr => resp, err, remrsp, time, zone

	dot.quad.ip.addr
	127.0.0.3	# response code from our DNSBL
	"error string... from remote DNSBL or our default"
	127.0.0.x	# remote response accepted from remote DNSBL
	1059422395	# time record expires (since epoch) or "0"
	remote.dnsbl.zone

  for "|,	$DBCONFIG->{SPMCNBL_DB_EVIDENCE}, q|" the arguments are
	dot.quad.ip.addr followed by STDIN of
	mail headers +
	message terminated on the last line by a
	.

  for "|,	$DBCONFIG->{SPMCNBL_DB_CONTRIB}, '" and "',
		$DBCONFIG->{SPMCNBL_DB_EVIDENCE}, q|" only, a string
	search in the "value" portion of the database.

  WARNING:	terminating any of these operations before 
		before completion risks corrupting the database

|;
  exit;
}

syntax if @ARGV < 2;

my %db_config = (
	dbfile	=> [	$DBCONFIG->{SPMCNBL_DB_TARPIT},
			$DBCONFIG->{SPMCNBL_DB_ARCHIVE}
		],
	txtfile	=> [	$DBCONFIG->{SPMCNBL_DB_CONTRIB},
			$DBCONFIG->{SPMCNBL_DB_EVIDENCE},
		],
	dbhome	=>	$DBCONFIG->{DBTP_ENVHOME_DIR},
	umask	=>	007,
);

my($dbname,$action,$addr,$orsp,$err,$trsp,$tim,$zon) = @ARGV;

syntax unless	grep($dbname, @{$db_config{dbfile}},@{$db_config{txtfile}});

if ($action =~ /^view/) {	# view
  View();
}
elsif ($action =~ /^insert/) {	# insert
  Insert();
}
elsif ($action =~ /^del/) {	# delete
  Delete();
}
elsif ($action =~ /^get/) {	# get
  Get();
}
elsif ($action =~ /^zap/) {	# zap a key
  Zap();
}
elsif ($action =~ /^clear/) {	# clear db
  Clear();
}
elsif ($action =~ /^search/) {	# search db
  Search();
}
elsif ($action =~ /^recno/) {	# get record number X
  Recno();
}
else {
  syntax;
}

sub getip {
  my($adr) = @_;
  syntax('BAD IP address') unless $adr;
  my $rv = inet_aton($adr);
  syntax() unless $rv;
  $rv;
}

sub db_open {
  (my $tool = new IPTables::IPv4::DBTarpit::Tools %db_config)
	or die "Could not open $db_config{dbhome}, $DBTP_ERROR " . db_strerror($DBTP_ERROR) . "\n";
  $tool;
}

sub get_t_a {
  my($saddr,$time) = @_;
  my $ip = safe_inet_ntoa($saddr);
  my $stime = scalar localtime($time);
  print "${ip}\t=> $time .. $stime\n";
}


sub print_contrib {
  print get_contrib(@_);
}

sub get_contrib {
  my($saddr,$record) = @_;
  my $ip = safe_inet_ntoa($saddr);
  my ($orsp,$err,$trsp,$tim,$zon) = unpack_contrib($record);
  my $stime = scalar localtime($tim);
  return "${ip}\t=> ". safe_inet_ntoa($orsp). ', '. $err . ",\n\t".
	safe_inet_ntoa($trsp). ", $stime, $zon\n";
}

sub print_e {
  print get_e(@_);
}

sub get_e {
  my($saddr,$record) = @_;
  my $ip = safe_inet_ntoa($saddr);
      return "${ip}\t=>\n$record\n";
}

sub Get {
  my $saddr = getip($addr);
  my $tool = db_open();
  $_ = $tool->get($dbname,$saddr);
  unless ($_) {
	die "Could not get $addr\n";
  }

  if (	$dbname eq $DBCONFIG->{SPMCNBL_DB_TARPIT} ||
	$dbname eq $DBCONFIG->{SPMCNBL_DB_ARCHIVE} ) {
	get_t_a($saddr,$_);
  }
  elsif ($dbname eq $DBCONFIG->{SPMCNBL_DB_CONTRIB}) {
	print_contrib($saddr,$_);
  }
  elsif ($dbname eq $DBCONFIG->{SPMCNBL_DB_EVIDENCE}) {
	print_e($saddr,$_);
  }
  $tool->closedb;
}

sub Recno {
  my $tool = db_open();
  my($saddr,$data) = $tool->getrecno($dbname,$addr);

  unless ($saddr || $data) {
	print db_strerror($DBTP_ERROR),"\n";
	die "Could not get record $addr\n";
  }

  if (	$dbname eq $DBCONFIG->{SPMCNBL_DB_TARPIT} ||
	$dbname eq $DBCONFIG->{SPMCNBL_DB_ARCHIVE} ) {
	get_t_a($saddr,$data);
  }
  elsif ($dbname eq $DBCONFIG->{SPMCNBL_DB_CONTRIB}) {
	print_contrib($saddr,$data);
  }
  elsif ($dbname eq $DBCONFIG->{SPMCNBL_DB_EVIDENCE}) {
	print_e($saddr,$data);
  }
  $tool->closedb;
}

sub Insert {
  my $saddr = getip($addr);
  my $tool = db_open();
  if (	$dbname eq $DBCONFIG->{SPMCNBL_DB_TARPIT} ||
	$dbname eq $DBCONFIG->{SPMCNBL_DB_ARCHIVE} ) {
    if($tool->touch($dbname,$saddr)) {
      die "Could not insert $addr\n";
    }
    my $time = time;
    my $stime = scalar localtime($time);
    print "${addr}\t=> $time .. $stime\n";
  }
  elsif ($dbname eq $DBCONFIG->{SPMCNBL_DB_CONTRIB}) {
    $tim = time unless $tim;
    if($tool->put($dbname,$saddr,pack("a4 x A* x a4 x N x A*",inet_aton($orsp),$err,inet_aton($trsp),$tim,$zon))) {
      die "Could not insert $addr\n";
    }
    my $stime = scalar localtime($tim);
    print "${addr}\t=> $orsp, $err,\n\t",
	"$trsp, $stime, $zon\n";
  }
  elsif ($dbname eq $DBCONFIG->{SPMCNBL_DB_EVIDENCE}) {
    my $string = '';
    while($_ = <STDIN>) {
      last if $_ =~/^\.$/;
      $string .= $_;
    }
    if($tool->put($dbname,$saddr,$string)) {
      die "Could not insert $addr\n";
    }
    print "${addr}:\n", $string;
  }
  $tool->closedb;
}

sub Zap {
   my $tool = db_open();
  if ($tool->remove($dbname,$addr)) {
	die "Could not delete $addr\n";
  }
  print "$addr deleted\n";
  $tool->closedb;
}

sub Delete {
  my $saddr = getip($addr);
  my $tool = db_open();
  if ($tool->remove($dbname,$saddr)) {
	die "Could not delete $addr\n";
  }
  print "$addr deleted\n";
  $tool->closedb;
}

sub Clear { 
  my $tool = db_open();
  die "Could not clear $dbname\n"   
	if $tool->clear($dbname);  
}  

sub safe_inet_ntoa {
  my $ip = shift;
  no warnings;
  eval {$ip = inet_ntoa($ip)};
  return $ip;
}

sub View {
  my $dump = {};
  my $tool = db_open();

  if ($tool->dump($dbname,$dump)) {
	die "Could not dump $dbname\n";
   }
  if (	$dbname eq $DBCONFIG->{SPMCNBL_DB_TARPIT} ||
	$dbname eq $DBCONFIG->{SPMCNBL_DB_ARCHIVE} ) {
    foreach(sort keys %$dump) {
	get_t_a($_,$dump->{$_});
    }
  }
  elsif ($dbname eq $DBCONFIG->{SPMCNBL_DB_CONTRIB}) {
    foreach(sort keys %$dump) {
	print_contrib($_,$dump->{$_});
    }
  }
  elsif ($dbname eq $DBCONFIG->{SPMCNBL_DB_EVIDENCE}) {
    foreach(sort keys %$dump) {  
	print_e($_,$dump->{$_});
    }
  }
  $tool->closedb;
}

sub Search {
# $addr contains search string
  if (	$dbname eq $DBCONFIG->{SPMCNBL_DB_TARPIT} ||
	$dbname eq $DBCONFIG->{SPMCNBL_DB_ARCHIVE} ) {
    die "Search not allowed in $dbname\n";
  }

  my $tool = db_open();

  if ($_ = $tool->nkeys($dbname)) {
    print "Searching $_ records in $dbname\n\n";
    my $record = 1;
    my @result;
    if ($dbname eq $DBCONFIG->{SPMCNBL_DB_CONTRIB}) {
      while (@result = $tool->getrecno($dbname,$record)) {
        $record++;
        my $dbstring = get_contrib(@result);
        print $dbstring if $dbstring =~ /$addr/i;
      }
    }
    elsif ($dbname eq $DBCONFIG->{SPMCNBL_DB_EVIDENCE}) {
      while (@result = $tool->getrecno($dbname,$record)) {
        $record++;
        my $dbstring = get_e(@result);
        print $dbstring if $dbstring =~ /$addr/i;
      }
    }
  } else {
    print "No records found in $dbname\n";
  }
  $tool->closedb;
}
