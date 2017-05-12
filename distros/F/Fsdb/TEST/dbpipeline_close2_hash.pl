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
use Fsdb::Filter::dbpipeline qw(dbpipeline_open2 dbpipeline_close2_hash dbcolstats);
use Fsdb::Filter::dbcolstats;
use 5.010;

my($queue, $sink, $thread) = 
	    dbpipeline_open2([-cols => [qw(data)]], dbcolstats('data'));

# data from dbcolstats_ex.in
foreach (qw(0 0.046953 0.072074 0.075413 0.094088 0.096602)) {
    $sink->write_row($_);
};
$sink->close;
my $stats_href = dbpipeline_close2_hash($queue, $sink, $thread);
foreach (sort keys %$stats_href) {
    print "$_\t$stats_href->{$_}\n";
};

exit 0;
