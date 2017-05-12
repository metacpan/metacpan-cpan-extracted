#!/usr/local/bin/perl 
# ====================================================================
# Copyright (C) 1997 Stephen Farrell <stephen@farrell.org>
#
# All rights reserved.  This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.
#
# ====================================================================
# File: Makefile.PL
# Author: Stephen Farrell
# Created: December 1997
# Locations: http://people.healthquiz.com/sfarrell/TableLayout/
# CVS $Id: Makefile.PL,v 1.2 1997/12/07 21:36:25 sfarrell Exp $
# ====================================================================

## To Do:
##	1. replace _isa() with isa() for new perls that support isa().

use lib "lib";
use ExtUtils::MakeMaker;
use HTML::TableLayout;
use File::Path;
use strict;

WriteMakefile(
	"NAME"	=>	"HTML::TableLayout",
);
