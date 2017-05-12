#!/usr/bin/env perl
$^W=1; # for systems where env gets confused by "perl -w"
use strict;
use vars qw( $VERSION );

# $Id: Makefile.PL,v 1.1 2004/07/15 11:20:09 abuse Exp $
$VERSION = do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };

use ExtUtils::MakeMaker;

WriteMakefile(
	      NAME     => 'Linux::TunTap',
	      VERSION  => '0.001'
	     );
