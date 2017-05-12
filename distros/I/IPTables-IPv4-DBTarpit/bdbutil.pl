#!/usr/bin/perl
#
# bdbutil.pl
#
# utility to manually 
# get, insert, remove records or view entire database
# for DBTarpit databases and related databases
#
# version 1.03, 8-14-03
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
use lib qw(./ blib/lib blib/arch);
use IPTables::IPv4::DBTarpit::Tools qw(
	inet_aton
	inet_ntoa
	$DBTP_ERROR
	db_strerror
);
use IPTables::IPv4::DBTarpit::SiteConfig;

my $DBCONFIG = new IPTables::IPv4::DBTarpit::SiteConfig;

sub syntax {
  print <<EOF;

Syntax:	bdbutil.pl db_name (action) [dot.quad.ip.addr]

  bdbutil.pl  db_name	get	dot.quad.ip.addr
  bdbutil.pl  db_name insert	dot.quad.ip.addr
  bdbutil.pl  db_name delete	dot.quad.ip.addr
  bdbutil.pl  db_name zap	key (unconstrained delete)
  bdbutil.pl  db_name view
  bdbutil.pl  db_name clear
    and
	where db_name is one of
EOF

  print qq|	  |, $DBCONFIG->{DBTP_DB_TARPIT}, 
	qq| or |, $DBCONFIG->{DBTP_DB_ARCHIVE},"\n\n";
  exit;
}

syntax if @ARGV < 2;

my %db_config = (
	dbfile	=> [	$DBCONFIG->{DBTP_DB_TARPIT},
			$DBCONFIG->{DBTP_DB_ARCHIVE}
		],
	dbhome	=>	$DBCONFIG->{DBTP_ENVHOME_DIR},
	umask	=>	007,
);

my($dbname,$action,$addr) = @ARGV;
syntax unless grep($dbname, @{$db_config{dbfile}});

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
elsif ($action =~ /^clear/) {	# clear db
  Clear();
}
elsif ($action =~ /^zap/) {
  Zap();
}
else {
  syntax;
}

sub getip {
  my($adr) = @_;
  syntax() unless $adr;
  my $rv = inet_aton($adr);
  syntax() unless $rv;
  $rv;
}

sub db_open {
  my $tool = new IPTables::IPv4::DBTarpit::Tools %db_config
	or die "Could not open %db_config{dbhome}, $DBTP_ERROR " . db_strerror($DBTP_ERROR) . "\n";
  $tool;
}

sub Get {
  my $saddr = getip($addr);
  my $tool = db_open();
  my $time = $tool->get($dbname,$saddr);
  unless ($time) {
	die "Could not get $addr\n";
  }
  my $stime = scalar localtime($time);
  print "${addr}\t=> $time .. $stime\n";
  $tool->closedb;
}

sub Insert {
  my $saddr = getip($addr);
  my $tool = db_open();
  if($tool->touch($dbname,$saddr)) {
    die "Could not insert $addr\n";
  }
  my $time = time;
    my $stime = scalar localtime($time);
  print "${addr}\t=> $time .. $stime\n";
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

sub Zap {
    my $tool = db_open();
  if ($tool->remove($dbname,$addr)) {
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

sub View {
  my $dump = {};
  my $tool = db_open();
  if ($tool->dump($dbname,$dump)) {
	die "Could not dump $dbname\n";
  }
  foreach(sort keys %$dump) {
    my $ip = $_;
    eval { $ip = inet_ntoa($_)};
    my $time = $dump->{$_};
    my $stime = scalar localtime($time);
    print "${ip}\t=> $time .. $stime\n";
  }
  $tool->closedb;
}
