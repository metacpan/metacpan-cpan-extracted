#!/usr/bin/perl -w

#
# dbpipeline_filter.pl
# Copyright (C) 2013 by John Heidemann
# $Id$
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblibdir for details.
#

use Fsdb::Support::NamedTmpfile;
use Fsdb::Filter::dbpipeline qw(dbpipeline_filter dbsort);
use Fsdb::Filter::dbcol;
use Fsdb::Filter::dbsort;
use Fsdb::Filter::dbroweval;
use 5.010;

my($new_reader, $new_thread) = dbpipeline_filter('-', [], dbsort(qw(cname)));

my $out = new Fsdb::IO::Writer(-file => '-', -clone => $new_reader);
$out->error && die "interal error: cannot write out " . $out->error;

while (my $fref = $new_reader->read_rowobj) {
    $out->write_rowobj($fref);
};
$out->close;
$new_thread->join();

exit 0;
