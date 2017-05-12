#!/usr/bin/perl
###########################################################################
#
# $Id: lcsvdmp.pl,v 1.1 2006/01/01 13:16:43 pkaluski Exp $
# $Name: Stable_0_16 $
#
# This is a tool for dumping select results to csv files.
# 
# $Log: lcsvdmp.pl,v $
# Revision 1.1  2006/01/01 13:16:43  pkaluski
# Initial revision
#
#
########################################################################### 

use strict;
use LRpt::CSVDumper;

dump_selects( @ARGV );

