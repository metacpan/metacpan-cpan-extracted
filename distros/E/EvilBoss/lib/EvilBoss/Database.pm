#!/usr/bin/perl

#  EvilBoss-api - API for creating FTN-tools
#
#  EBDatabase.pm - work with databases (PostgreSQL/MySQL/mSQL)
#
#  Copyright (c) 2004-2005 Alex Soukhotine, 2:5030/1157
#	
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  $Id$

package EvilBoss::Database;

require Exporter;
require DBI;
use Fcntl qw(:flock);
require EBConfig;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

$VERSION = 1.01;

@ISA=qw(Exporter);
#@EXPORT = qw(&f1 &f3 &name);
%EXPORT_TAGS=();

#@EXPORT_OK = qw(&name);

my $tmpfile		= ''; 
my $SQLConnectStr	= '';
my $dbh			= undef;
my $sth			= undef;
my $state		= 0;

sub new
{
 my $classname = shift;
 my $self = {};
 bless($self,$classname);
 my $cfg=$_[0];
 $tmpfile=$cfg->{TempDir}."/EBmSQL.tmp";
 $SQLConnectStr="DBI:".$cfg->{DBType}.":";
 
 if ($cfg->{DBType} eq "mSQL")
 {
  $SQLConnectStr .= $cfg->{DBName};
  $cfg->{DBUser} = undef;
  $cfg->{DBPass} = undef;
  if (open(TMP,">$tmpfile"))
  {
   print "Locking temporary file...\n\n";
   flock(TMP,LOCK_EX);
  } 
 }
 elsif ($cfg->{DBType} eq "mysql")
 {
  $SQLConnectStr .= $cfg->{DBName}.":".$cfg->{DBHost}.":".$cfg->{DBPort};
 }
 elsif ($cfg->{DBType} eq "Pg")
 {
  $SQLConnectStr .= "dbname=".$cfg->{DBName}.";host=".$cfg->{DBHost}.";port=".$cfg->{DBPort};
 } 
 
 $dbh = DBI->connect($SQLConnectStr,$cfg->{DBUser},$cfg->{DBPass},{ PrintError => 0, RaiseError => 0 }); 
 
 $state=1 if ($dbh);
 
 return $self;
}

sub DESTROY
{
 my $self = shift;
 if ($state)
 {
  $dbh->disconnect;
  $state=0;
 } 
}

sub state
{
 my $self = shift;
 return 1 if ($state);
 return 0;
}

sub dbh
{
 return $dbh;
}

sub quick_fetchrow
{
 my $self = shift;
 my $sth,$tmp;
 if ($dbh)
 {
  $sth=$dbh->prepare($_[0]);
  $sth->execute;
  $tmp=$sth->fetchrow;
  $sth->finish;
 } 
 return $tmp;
}


sub query
{
 my $self = shift;
 $sth=$dbh->prepare($_[0]);
 $sth->execute;
}

sub end_query
{
 my $self=shift;
 $sth->finish;
 $sth=undef;
}

sub fetchrow
{
 my $self = shift;
 my $tmp;
 if ($dbh && $sth)
 {
  $tmp=$sth->fetchrow;
 } 
 return $tmp;
}

sub fetchrow_array
{
 my $self = shift;
 my @tmp;
 if ($dbh && $sth)
 {
  @tmp=$sth->fetchrow_array;
 } 
 return @tmp;
}

sub fetchrow_hashref
{
 my $self = shift;
 my %tmp;
 if ($dbh && $sth)
 {
  %tmp=$sth->fetchrow_hashref;
 }
 return %tmp;
}
	

sub quick_fetchrow_array
{
 my $self = shift;
 my $sth,@tmp;
 if ($dbh)
 { 
  $sth=$dbh->prepare($_[0]);
  $sth->execute;
  @tmp=$sth->fetchrow_array;
  $sth->finish;
 } 
 return @tmp;
}

sub quick_fetchrow_hashref
{
 my $self = shift;
 my $sth,%tmp;
 if ($dbh)
 {
  $sth=$dbh->prepare($_[0]);
  $sth->execute;
  %tmp=$sth->fetchrow_hashref;
  $sth->finish;
 }
 return %tmp;
}
	      

1;
