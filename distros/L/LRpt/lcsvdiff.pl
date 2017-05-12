#!/usr/bin/perl
###########################################################################
#
# $Id: lcsvdiff.pl,v 1.1 2006/01/14 21:17:27 pkaluski Exp $
# $Name: Stable_0_16 $
#
# This tool compares 2 sets of CSV files.
# 
# $Log: lcsvdiff.pl,v $
# Revision 1.1  2006/01/14 21:17:27  pkaluski
# First revision. New design of lreport.
#
#
########################################################################### 
use LRpt::CSVDiff;
use strict;

diff( @ARGV );

