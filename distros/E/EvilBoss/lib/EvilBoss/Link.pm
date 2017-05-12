#!/usr/bin/perl

#  EvilBoss-api - API for creating FTN-tools
#
#  EBLink.pm - work with links
#
#  Copyright (c) 2004-2005 Alex Soukhotine, 2:5030/1157
#	
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  $Id$

package EvilBoss::Link;

require Exporter;
require EBDatabase;
require EBAddress;
require EBConfig;
require EBCheck;
use Carp;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $AUTOLOAD %ok_field);

$VERSION = 1.01;

@ISA=qw(Exporter);
#@EXPORT = qw(&f1 &f3 &name);
%EXPORT_TAGS=();

#@EXPORT_OK = qw(&name);

# type definitions

my %ATTRS = (
 address	=> "addr",
 name		=> "str_d",

 session_pass	=> "str",
# pkt_pass	=> "str",
# tic_pass	=> "str",
# afix_pass	=> "str",
# ffix_pass	=> "str",
# lctl_pass 	=> "str",

 netmail	=> "yn",
 roudirect	=> "yn",
 roumode	=> "str_d",

 echoes		=> "yn",
 eaccess	=> "str",
 elimit		=> "num",
 egroup		=> "str",

 fechoes	=> "yn",
 feaccess	=> "str",
 felimit	=> "num",
 fegroup	=> "str",

 level		=> "num_d",
 packer		=> "str_d",
 frwrq		=> "yn",
 active		=> "yn",
 timelimit	=> "yn",
 hunter		=> "yn",

 maxnologin	=> "num",
 warncnt	=> "num",
 maxwarn	=> "num",
 utime		=> "num",
 putime		=> "num",

 p_name		=> "str_d",
 p_station	=> "str_d",
 p_location	=> "str_d",
 p_phone	=> "str_d",
 p_speed	=> "num_d",
 p_flags	=> "str"
);

my %CHECKS = (
 address	=> "address",
 name		=> "name",

 session_pass	=> "pass",
# pkt_pass	=> "pass",
# tic_pass	=> "pass",
# afix_pass	=> "pass",
# ffix_pass	=> "pass",
# lctl_pass 	=> "pass",

 netmail	=> "yn",
 roudirect	=> "yn",
 roumode	=> "roumode",

 echoes		=> "yn",
 eaccess	=> "groups",
 elimit		=> "num",
 egroup		=> "group",

 fechoes	=> "yn",
 feaccess	=> "groups",
 felimit	=> "num",
 fegroup	=> "group",

 level		=> "num",
 packer		=> "packer",
 frwrq		=> "yn",
 active		=> "yn",
 timelimit	=> "yn",
 hunter		=> "yn",

 maxnologin	=> "num",
 warncnt	=> "num",
 maxwarn	=> "num",
 utime		=> "num",
 putime		=> "num",

 p_name		=> "name",
 p_station	=> "station",
 p_location	=> "location",
 p_phone	=> "phone",
 p_speed	=> "speed",
 p_flags	=> "flags"
);


# default values

my %link_defauts = (
 name		=> "SysOp",

 session_pass	=> "",
 pkt_pass	=> "",
 tic_pass	=> "",
 afix_pass	=> "",
 ffix_pass	=> "",
 lctl_pass	=> "",
 
 netmail	=> 'Y',
 roudirect	=> 'Y',
 roumode	=> 'h',
	
 echoes		=> 'Y',
 fechoes	=> 'N',
 timelimit	=> 'Y',
 hunter		=> 'N',
	    
 maxnologin	=> 30,
 warncnt	=> 0,
 maxwarn	=> 0,
 utime		=> time,
 putime		=> time,
		 
 elimit		=> 10,
 eaccess	=> "A",
 egroup		=> '',
 felimit	=> 2,
 feaccess	=> "Z",
 fegroup	=> '',

 level		=> 1,
 packer		=> "zip",
 frwrq		=> 'N',
 active		=> 'Y',
   
 p_name		=> "SysOp",
 p_station	=> "Unknown",
 p_location	=> "St.Petersburg",
 p_phone	=> "-Unpublished-",
 p_speed	=> 9600,
 p_flags	=> "MO"
	 		       
);
	      
for my $attr (keys %ATTRS) { $ok_field{$attr}++;}

sub new
{
 my $classname = shift;
 my $self = {};
 bless($self,$classname);
 $self->_init(@_);
 return $self;
}

sub DESTROY
{
 my $self = shift;
}

sub load_from_db
{
 my $self=shift;
 
 my $cfg=$_[0];
 my $db=$_[1];

 
 $self->{name}		= ($db->dbh->selectrow_array("SELECT name FROM " . $cfg->{LinkNameTable} . " WHERE link=\'" . $self->address->string . "\'"))[0] || $self->name;
 
 my $tmp=$db->dbh->selectrow_hashref(sprintf("SELECT password,pkt_password,tic_password,afix_password,ffix_password,lctl_password FROM %s WHERE link=\'%s\'",
		$cfg->{MailerPasswdTable},$self->address->string));
 


 $self->session_pass($$tmp{password});
# $self->pkt_pass($$tmp{pkt_password});
# $self->tic_pass($$tmp{tic_password});
# $self->afix_pass($$tmp{afix_password});
# $self->ffix_pass($$tmp{ffix_password});
# $self->lctl_pass($$tmp{lctl_password});
 
 
 $self->{netmail}	= 'Y'; # reserved


 my $tmp=$db->dbh->selectrow_hashref(sprintf("SELECT timelimit,echoes,fechoes,hunter,roudirect,roumode,active FROM %s WHERE link=\'%s\'",
	    $cfg->{LinkOptionsTable},$self->address->string));
 
 for my $i (keys %$tmp)
 {
  $self->{$i}=$$tmp{$i};
 }

 my $tmp=$db->dbh->selectrow_hashref(sprintf("SELECT level,eaccess,feaccess,elimit,felimit,egroup,fegroup,packer,frwrq FROM %s WHERE link=\'%s\'",
	    $cfg->{LinkTosserTable},$self->address->string));

 for my $i (keys %$tmp)
 {
  $self->{$i}=$$tmp{$i};
 }

 my $tmp=$db->dbh->selectrow_hashref(sprintf("SELECT utime,putime,warncnt,maxwarn,maxnologin FROM %s WHERE link=\'%s\'",
	    $cfg->{MailerLastLoginTable},$self->address->string));

 for my $i (keys %$tmp)
 {
  if ($i eq "maxnologin")
  {
   $self->{$i}=$$tmp{$i}/(60*60*24);
  }
  else
  {
   $self->{$i}=$$tmp{$i};
  } 
 }

 if ($self->address->point != 0)
 {
  my $tmp=$db->dbh->selectrow_hashref(sprintf("SELECT station,location,name,phone,speed,flags FROM %s WHERE point=\'%d\' AND aka=\'%s\'",
		$cfg->{PointListTable},$self->address->point,$self->address->string3d));
  
  for my $i (keys %$tmp)
  {
   $self->{"p_$i"}=$$tmp{$i};
  }
 }
 
}

sub remove_from_db
{
 my $self=shift;
 my $cfg=$_[0];
 my $db=$_[1];
 
 for $i (qw(MailerPasswdTable
            LinkNameTable 
	    LinkOptionsTable
	    LinkTosserTable
	    MailerLastLoginTable))
 {
  $db->dbh->do(sprintf("DELETE FROM %s WHERE link=\'%s\'",$cfg->{$i},$self->address->string));
 }
 
 if ($self->address->point != 0)
 {
  $db->dbh->do(sprintf("DELETE FROM %s WHERE point=\'%d\' AND aka=\'%s\'",
	    $cfg->{PointListTable},
	    $self->address->point,
	    $self->address->string3d));
 }
}

sub save_to_db
{
 my $self=shift;
 my $cfg=$_[0];
 my $db=$_[1];
 if ($self->exists_in_db($cfg,$db) != 1)
 {
  $db->dbh->do(sprintf("INSERT INTO %s (link,password) VALUES(\'%s\',\'%s\')",
	$cfg->{MailerPasswdTable},$self->address->string,$self->session_pass));
  $db->dbh->do(sprintf("INSERT INTO %s (link,name) VALUES(\'%s\',\'%s\')",
	$cfg->{LinkNameTable},$self->address->string,$self->name));
  $db->dbh->do(sprintf("INSERT INTO %s (link,timelimit,echoes,fechoes,hunter,roudirect,roumode,active) VALUES(\'%s\')",
	$cfg->{LinkOptionsTable},join("\',\'",$self->address->string,$self->timelimit,$self->echoes,$self->fechoes,
	$self->hunter,$self->roudirect,$self->roumode,$self->active)));
  $db->dbh->do(sprintf("INSERT INTO %s (link,level,eaccess,feaccess,elimit,felimit,egroup,fegroup,packer,frwrq) VALUES(\'%s\',\'%d\',\'%s\',\'%s\',\'%d\',\'%d\',\'%s\',\'%s\',\'%s\',\'%s\')",
	$cfg->{LinkTosserTable},$self->address->string,sprintf("%d",$self->level),$self->eaccess,$self->feaccess,
	sprintf("%d",$self->elimit),sprintf("%d",$self->felimit),$self->egroup,$self->fegroup,$self->packer,$self->frwrq));
  $db->dbh->do(sprintf("INSERT INTO %s (link,utime,putime,warncnt,maxwarn,maxnologin) VALUES(\'%s\',\'%d\',\'%d\',\'%d\',\'%d\',\'%d\')",
	$cfg->{MailerLastLoginTable},$self->address->string,$self->utime,$self->putime,
	$self->warncnt,$self->maxwarn,$self->maxnologin*60*60*24));

  if ($self->address->point != 0)
  {
   $db->dbh->do(sprintf("INSERT INTO %s (point,station,location,name,phone,speed,flags,aka) VALUES (\'%s\')",
	$cfg->{PointListTable},join("\',\'",sprintf("%d",$self->address->point),$self->p_station,$self->p_location,
	$self->p_name,$self->p_phone,sprintf("%d",$self->p_speed),$self->p_flags,$self->address->string3d)));
  }
 }
 else
 {
  my $rc;
  
  $rc=$db->dbh->do("UPDATE ".$cfg->{MailerPasswdTable}." SET ".
    "password=\'". $self->session_pass . "\', ".
#    "pkt_password=\'". $self->pkt_pass . "\', ".
#    "tic_password=\'". $self->tic_pass . "\', ".
#    "afix_password=\'". $self->afix_pass . "\', ".
#    "ffix_password=\'". $self->ffix_pass . "\', ".
#    "lctl_password=\'". $self->lctl_pass . "\' ".
    "WHERE link=\'" . $self->address->string ."\'");
  
  
  $rc=$db->dbh->do(sprintf("UPDATE %s SET name=\'%s\' WHERE link=\'%s\'",
    $cfg->{LinkNameTable},$self->name,$self->address->string));
  
  
  $rc=$db->dbh->do("UPDATE " . $cfg->{LinkOptionsTable} . " SET ".
    "timelimit=\'".$self->timelimit."\', ".
    "echoes=\'".$self->echoes."\', ".
    "fechoes=\'".$self->fechoes."\', ".
    "hunter=\'".$self->hunter."\', ".
    "roudirect=\'".$self->roudirect."\', ".
    "roumode=\'".$self->roumode."\', ".
    "active=\'".$self->active."\' ".
    "WHERE link=\'" . $self->address->string ."\'");

 
  $rc=$db->dbh->do("UPDATE " .$cfg->{LinkTosserTable}." SET ".
    "level=\'".sprintf("%d",$self->level)."\', ".
    "eaccess=\'".$self->eaccess."\', ".
    "feaccess=\'".$self->feaccess."\', ".
    "elimit=\'".sprintf("%d",$self->elimit)."\', ".
    "felimit=\'".sprintf("%d",$self->felimit)."\', ".
    "egroup=\'".$self->egroup."\', ".
    "fegroup=\'".$self->fegroup."\', ".
    "packer=\'".$self->packer."\', ".
    "frwrq=\'".$self->frwrq."\' ".
    "WHERE link=\'" . $self->address->string ."\'");

# print "maxnologin=".$self->maxnologin."<br>";
# print "utime=".$self->utime."<br>";
# print "putime=".$self->putime."<br>";
 
    
  $rc=$db->dbh->do("UPDATE " .$cfg->{MailerLastLoginTable}." SET ".
    "utime=\'".sprintf("%d",$self->utime)."\', ".
    "putime=\'".sprintf("%d",$self->putime)."\', ".
    "warncnt=\'".sprintf("%d",$self->warncnt)."\', ".
    "maxwarn=\'".sprintf("%d",$self->maxwarn)."\', ".
    "maxnologin=\'".sprintf("%d",($self->maxnologin*60*60*24))."\' ".
    "WHERE link=\'" . $self->address->string ."\'");

#  print "rc=$rc<br>";
  
  if ($self->address->point != 0)
  {
   $db->dbh->do("UPDATE " .$cfg->{PointListTable}." SET ". 
    "station=\'".$self->p_station."\', ".
    "location=\'".$self->p_location."\', ".
    "name=\'".$self->p_name."\', ".
    "phone=\'".$self->p_phone."\', ".
    "speed=\'".sprintf("%d",$self->p_speed)."\', ".
    "flags=\'".$self->p_flags."\' ".
    "WHERE point=\'" .$self->address->point."\' AND aka=\'" . $self->address->string3d ."\'");
  }

 }
}

sub exists_in_db
{
 my $self=shift;
 my $cfg=$_[0];
 my $db=$_[1];
 
 my $link=$db->dbh->selectrow_array(sprintf("SELECT link FROM %s WHERE link=\'%s\'",
	    $cfg->{MailerPasswdTable},$self->address->string));

 if ($link && ($link eq $self->address->string))
 {
  return 1;
 }
 
 return 0;
}

sub load_from_hash
{
 my $self=shift;
 
 my %tmp=@_;

 for $k (keys %ATTRS)
 {
  if ($ATTRS{$k} eq "yn")
  {
   $self->{$k} = $tmp{$k} ? "Y" : "N";
  }
  elsif (($ATTRS{$k} eq "str_d")||($ATTRS{$k} eq "num_d"))
  {
   $self->{$k} = $tmp{$k} ? $tmp{$k} : $link_defaults{$k};
  }
  elsif ($ATTRS{$k} ne "addr")
  {
   $self->{$k} = $tmp{$k};
  }
 }

}

sub print_hash
{
 my $self=shift;
 my %tmp;
 
 if (@_)
 {
  %tmp=@_;
 }
 else
 {
  %tmp=%$self;
 }
 
 for $k (keys %ATTRS)
 {
  print "$k=\"". $tmp{$k} ."\"<br>";
 }
}

sub check_hash
{
 my $self=shift;
 my @tmp;
 my %tmph=@_;
 my $addr=EvilBoss::Address->new(string => $tmph{address});
 
# print_hash(%tmph);
# print "addr1=".$addr."<br>";
 for $k (keys %CHECKS)
 {
#  print "debug k=\'$k\' c=\'".$CHECKS{$k}."\'  val=\'" . $tmph{$k} ."\'<br>";
  
  if (($addr->point!=0 && $k=~/^p_/) || ($k!~/^p_/))
  {
#   print "match: $k<br>";
   push(@tmp,$k) if (!check($CHECKS{$k},$tmph{$k}));
  } 
 }
 return (@tmp);
}

#usage: check($arg,$value)
sub check
{
# my $self=shift;
 my $rc;
 my $str=$_[0];
 my $val=$_[1];
# print "str=$str val=$val<br>";
 $rc=("EvilBoss::Check::".$str)->($val);
 return $rc;
}
    
sub _init
{
 my $self = shift;
 $self->{address}	= new EvilBoss::Address;

 for $k (keys %ATTRS)
 {
  if ($ATTRS{$k} ne "addr")
  {
   $self->{$k}=$link_defauts{$k};
  } 
 }
 
 if (@_)
 {
  my %extra = @_;
  @$self{keys %extra} = values %extra;
 }
 
}

sub AUTOLOAD
{
 my $self = shift;
 my $attr = $AUTOLOAD;
 $attr =~ s/.*:://;
 return unless $attr =~ /[^A-Z]/;
 croak "invalid attribute method: ->$attr()" unless $ok_field{$attr};
 $self->{lc $attr} = shift if (@_);
 return $self->{lc $attr};
}       

1;
