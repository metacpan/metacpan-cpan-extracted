#!/usr/bin/perl
###########################################################################
#
# $Id: lrptxml.pl,v 1.2 2006/09/10 18:48:17 pkaluski Exp $
# $Name: Stable_0_16 $
# 
# Creates an XML report from csv dumps.
#
# $Log: lrptxml.pl,v $
# Revision 1.2  2006/09/10 18:48:17  pkaluski
# Cosmetic changes
#
# Revision 1.1  2006/01/07 21:57:30  pkaluski
# Initial revision. Works.
#
#
##########################################################################
use strict;
use LRpt::XMLReport;

create_report( @ARGV );


