#!/usr/bin/perl
###########################################################################
#
# $Id: lks.pl,v 1.1 2006/01/07 21:16:04 pkaluski Exp $
# $Name: Stable_0_16 $
#
# This tool substitutes where key entries with the actual values. 
# 
# $Log: lks.pl,v $
# Revision 1.1  2006/01/07 21:16:04  pkaluski
# Initial revision. Works
#
# Revision 1.1  2006/01/01 12:38:36  pkaluski
# Initial revision. Works.
#
#
########################################################################### 
use strict;
use LRpt::KeySubst;

wkey_subst( @ARGV );



