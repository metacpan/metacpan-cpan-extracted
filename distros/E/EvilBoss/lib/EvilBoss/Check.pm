#!/usr/bin/perl

#  EvilBoss-api - API for creating FTN-tools
#
#  EBCheck.pm - data check routines
#
#  Copyright (c) 2004-2005 Alex Soukhotine, 2:5030/1157
#	
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  $Id$

package EvilBoss::Check;

require Exporter;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

$VERSION = 1.00;

@ISA=qw(Exporter);
#@EXPORT = qw(&f1 &f3 &name);
%EXPORT_TAGS=();

#@EXPORT_OK = qw(&name);

sub address
{
 return 1 if ($_[0]=~/^(\d+):(\d+)\/(\d+)\.?(\d+)?$/);
 return 0;
}

sub group
{
 return 1 if ($_[0]=~/^([A-Z])?$/);
 return 0;
}

sub groups
{
 return 1 if ($_[0]=~/^[A-Z]*$/);
 return 0;
}
  
sub packer
{
 return 1 if ($_[0]=~/^(zip|rar|arj)$/);
 return 0;
}

sub num
{
 return 1 if ($_[0]=~/^[0-9]*$/);
 return 0;
}

sub yn
{
# return 1 if ($_[0]=~/^[YN]$/);
# return 0;
 return 1;
}

sub roumode
{
 return 1 if ($_[0]=~/^[hndc]$/);
 return 0;
}

sub pass
{
 return 1 if (($_[0] !~ /[^a-zA-Z0-9]+/)&&((length($_[0])<=8)&&(length($_[0]) > 3)));
 return 0;
}

sub pass1
{
 return 1 if (($_[0] =~ /[a-zA-Z0-9]*/)&&(length($_[0])<=8));
 return 0;
}

sub station
{
 return 1 if (($_[0] !~ /[^a-zA-Z0-9 #'"=!.]+/)&&((length($_[0])<=30)&&(length($_[0]) > 1)));
 return 0;
}

sub location
{
 return 1 if (($_[0] !~ /[^a-zA-Z0-9 .]+/)&&((length($_[0])<=20)&&(length($_[0]) > 3)));
 return 0;
}

sub name
{
 return 1 if (($_[0] =~ /^[a-zA-Z .]+$/)&&((length($_[0])<=30))&&(length($_[0]) > 3));
 return 0;
}


sub phone
{
 return 1 if ((($_[0] =~ /\d+-\d+-\d+-\d+/)&&($_[0] !~ /[^0-9-]+/))||($_[0] eq "-Unpublished-"));
 return 0;
}

sub speed
{
 return 1 if (($_[0] == 300)||($_[0] == 1200)||($_[0] == 2400)||($_[0] == 9600)||($_[0] == 14400)||($_[0] == 19200)||($_[0] == 28800)||($_[0] == 33600));
 return 0;
}

#usage: flags($string)
sub flags
{
###
my %FLIST=(
CM => 0,
MO => 0,
LO => 0,
V22 => 0,
V29 => 0,
V32 => 0,
V32B => 0,
V34 => 0,
V42 => 0,
V42B => 0,
MNP => 0,
H96 => 0,
HST => 0,
H14 => 0,
H16 => 0,
MAX => 0,
PEP => 0,
CSP => 0,
V32T => 0,
VFC => 0,
ZYX => 0,
V90C => 0,
V90S => 0,
X2C => 0,
X2S => 0,
Z19 => 0,
MN => 0,
XA => 0,
XB => 0,
XC => 0,
XP => 0,
XR => 0,
XW => 0,
XX => 0,
IBN => 0,
IFC => 0,
IFT => 0,
ITN => 0,
IVM => 0,
IP => 0,
IMI => 0,
ISE => 0,
ITX => 0,
IUC => 0,
IEM => 0,
EVY => 0,
EMA => 0,
V110L => 0,
V110H => 0,
V120L => 0,
V120H => 0,
X75 => 0,
ISDN => 0,
U => 0
);

my $errflag,$badflag,$wtflag;

 if ($_[0] =~ /,U$/) 
 {
  $errflag=1;
 }
 else
 { 
  my @CFLAGS = split(/,/,$_[0]);
  $wtflag=0;
  $errflag=0;
  for my $cflag (@CFLAGS)
  {
   $badflag=1;
   for my $flag (keys %FLIST)
   {
    if (($cflag eq $flag)&&($FLIST{$flag}==0))
    {
     $badflag=0;
     $FLIST{$flag}=1;
     if ($cflag eq "U")
     {
      for $i (keys FLIST)
      {
       $FLIST{$i}=1;
      }
     } 
     if ($cflag =~ /^X[ABCPRWX]$/)
     {
      for my $xf (A,B,C,P,R,W,X)
      {
       $FLIST{"X$xf"}=1;
      }
     }     
    }
    if (($cflag =~ /^T[a-zA-Z]{2}$/)&&($wtflag==0)&&($FLIST{U}==1))
    {
     $badflag=0;
     $wtflag=1;
    } 
    if ((($cflag eq "K12")||($cflag eq "ENC")||($cflag eq "CDP")||($cflag eq "SDS"))&&($FLIST{U}==1))
    {
     $badflag=0;
    }    
   }
   $errflag=1 if ($badflag==1);
  }
 }
 
###
 return 1 if ($errflag==0);
 return 0;
}

1;
