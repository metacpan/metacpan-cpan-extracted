#!/usr/bin/perl -w

#
# dbpipeline_flakey.pl
# Copyright (C) 2007-2008 by John Heidemann
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

# select below is to get a 100ms (0.1s) timeout
dbpipeline(
#    '-d',
#    '-d',
#    '-d',
    dbcol(qw(name test1)),
    dbroweval('_test1 += 1;'),
    dbroweval('_test1 += 1;'),
    dbroweval('_test1 += 1; select(undef,undef,undef,0.1);'),
    dbroweval('_test1 += 1; if (++$count == 2) { print STDERR "die"; };'),
    dbroweval('_test1 += 1; select(undef,undef,undef,0.1);'),
);

exit 0;
