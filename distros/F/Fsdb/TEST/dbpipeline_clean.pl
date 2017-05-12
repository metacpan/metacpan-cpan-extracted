#!/usr/bin/perl -w

#
# dbpipeline_clean.pl
# Copyright (C) 2007 by John Heidemann
# $Id$
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblibdir for details.
#

use Fsdb::Filter::dbpipeline qw(:all);

# do the equivalent of
#
#   cat DATA/grades.jdb | dbcol name test1 | dbroweval '_test1 += 5;'

dbpipeline(
    dbcol(qw(name test1)),
    dbroweval('_test1 += 5;'));

exit 0;
