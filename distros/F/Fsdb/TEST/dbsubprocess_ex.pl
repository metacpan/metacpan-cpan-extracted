#!/usr/bin/perl -w

#
# dbsubprocess_ex.pl
# Copyright (C) 2008 by John Heidemann
# $Id$
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblibdir for details.
#

use Fsdb::Filter::dbsubprocess;
my $f = new Fsdb::Filter::dbsubprocess(qw(cat));
$f->setup_run_finish;
exit 0;

