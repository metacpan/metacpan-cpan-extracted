#!/usr/bin/perl

#  EvilBoss-api - API for creating FTN-tools
#
#  EBAddress.pm - work with FTN-style addresses
#
#  Copyright (c) 2004-2005 Alex Soukhotine, 2:5030/1157
#	
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  $Id$

package EvilBoss::Address;

require Exporter;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

$VERSION = 1.00;

@ISA=qw(Exporter);
#@EXPORT = qw(&f1 &f3 &name);
%EXPORT_TAGS=();

#@EXPORT_OK = qw(&name);

use overload	'==' => \&equal,
		'eq' => \&equal,
		'!=' => \&notequal,
		'ne' => \&notequal,
		'""' => \&stringify;

sub equal
{
 my ($a1,$a2)=@_;
 return $a1->string eq $a2->string;
}

sub noequal
{
 my ($a1,$a2)=@_;
 return $a1->string ne $a2->string;
}


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
 $self->{string}	= "0:0/0";
 $self->{zone}		= 0;
 $self->{net}		= 0; 
 $self->{node}		= 0; 
 $self->{point}		= 0; 
 if (@_)
 {
  my %extra = @_;
  @$self{keys %extra} = values %extra;
  
  $self->{string} = $self->string($extra{string}) if ($extra{string});
  
 } 
}

sub zone
{
 my $self = shift;
 if (@_)
 {
  $self->{zone}	= shift;
 }
 return $self->{zone};
}


sub net
{
 my $self = shift;
 if (@_)
 {
  $self->{net}	= shift;
 }
 return $self->{net};
}

sub node
{
 my $self = shift;
 if (@_)
 {
  $self->{node}	= shift;
 }
 return $self->{node};
}


sub point
{
 my $self = shift;
 if (@_)
 {
  $self->{point}	= shift;
 }
 return $self->{point};
}

sub string
{
 my $self = shift;
 if (@_)
 {
  my @tmp = @_;
  
  if ($tmp[0]=~/(\d+):(\d+)\/(\d+)\.?(\d+)?/)
  {
   $self->{zone}  = $1;
   $self->{net}   = $2;
   $self->{node}  = $3;    
   $self->{point} = $4;
  }
  else
  {
   if ($tmp[0]=~/^\d+$/ && $tmp[1]=~/^\d+$/ && $tmp[2]=~/^\d+$/  && $tmp[3]=~/^\d+$/)
   {
    $self->{zone}  = $tmp[0];
    $self->{net}   = $tmp[1];
    $self->{node}  = $tmp[2];
    $self->{point} = $tmp[3];
   }  
   elsif ($tmp[0]=~/^\d+$/ && $tmp[1]=~/^\d+$/ && $tmp[2]=~/^\d+$/  && $tmp[3]!~/^\d+$/)
   {
    $self->{zone}  = $tmp[0];
    $self->{net}   = $tmp[1];
    $self->{node}  = $tmp[2];
   }   
   elsif ($tmp[0]=~/^\d+$/ && $tmp[1]=~/^\d+$/ && $tmp[2]!~/^\d+$/  && $tmp[3]!~/^\d+$/)
   {
    $self->{zone}  = $tmp[0];
    $self->{net}   = $tmp[1];   
   }     
   elsif ($tmp[0]=~/^\d+$/ && $tmp[1]!~/^\d+$/ && $tmp[2]!~/^\d+$/  && $tmp[3]!~/^\d+$/)
   {
    $self->{zone}  = $tmp[0];
   }
  }  
 }
 $self->{string}=sprintf("%d",$self->zone).":".sprintf("%d",$self->net)."/".sprintf("%d",$self->node); 
 $self->{string}.=".".sprintf("%d",$self->point) if ($self->point);
 return $self->{string};
}

sub string3d
{
 my $self=shift;
 return sprintf("%d:%d/%d",$self->zone,$self->net,$self->node);
}

sub stringify
{
 my $self = shift;
 return $self->{string};
}

1;
