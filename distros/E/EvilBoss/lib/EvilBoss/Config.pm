#!/usr/bin/perl

#  EvilBoss-api - API for creating FTN-tools
#
#  (EB)Config.pm - read EvilBoss configuration file
#
#  Copyright (c) 2004-2005 Alex Soukhotine, 2:5030/1157
#	
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  $Id$

package EvilBoss::Config;

require Exporter;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

$VERSION = 1.01;

@ISA=qw(Exporter);
#@EXPORT = qw(&f1 &f3 &name);
%EXPORT_TAGS=();

#@EXPORT_OK = qw(&name);

$ConfigFile="/etc/ftn/evilboss.conf";

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

sub _init
{
 my $self = shift;

 $ConfigFile=$_[0] if (@_);

 if (open(EBCONF,"<$ConfigFile"))
 {
  while(<EBCONF>)
  {
   if (/^\s*(\w+)\s+([\w\d:\/\., -]+)\#*/)
   {
    if (!$self->{$1})
    { 
     $self->{$1}=$2;
    }
    else
    {
     my @tmp=$1;
     push(@tmp,$self->{$1});
     push(@tmp,$2);
     $self->{$1}=@tmp;
    }   
   }
  }
  close(EBCONF);
 }
}

sub check
{
 my $self = shift;
 for ($i=0;$_[$i];$i++)
 {
  return 0 if (!$self->{$_[$i]});
 }
 return 1;
}


1;
