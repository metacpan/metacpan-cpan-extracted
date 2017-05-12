#!/usr/bin/perl -w

#
# dbpipeline_sink.pl
# Copyright (C) 2013 by John Heidemann
# $Id$
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblibdir for details.
#

use Fsdb::Support::NamedTmpfile;
use Fsdb::Filter::dbpipeline qw(dbpipeline_sink dbsort);
use Fsdb::Filter::dbcol;
use Fsdb::Filter::dbsort;
use Fsdb::Filter::dbroweval;
use 5.010;

# do the equivalent of
#
#   cat DATA/grades.jdb | dbcol name test1 | dbroweval '_test1 += 5;'

my $save_out_filename = Fsdb::Support::NamedTmpfile::alloc();
my(@writer_args) = (-cols => [qw(data)]);
my($save_out, $sorter_thread) = dbpipeline_sink(\@writer_args,
			'--output' => $save_out_filename,
			dbsort(qw(-n data)));
#			dbroweval('_data += 1;'));
foreach (9, 8, 7, 6, 5, 10, 11, 12, 13, 14) {
    my(@row) = ($_);
    $save_out->write_rowobj(\@row);
};
$save_out->close;
$sorter_thread->join();

# read it back, sorted
my $save_in = new Fsdb::IO::Reader(-file => $save_out_filename);
$save_in->error && die "interal error: re-read error " . $save_in->error;
for(;;) {
    my $fref = $save_in->read_rowobj;
    last if (!$fref || $#$fref == -1);
    say $fref->[0];
};

exit 0;
