#!/usr/bin/perl -w

#
# dbpipeline_flakey.pl
# Copyright (C) 2008 by John Heidemann
# $Id$
#

use Fsdb::Filter::dbpipeline qw(:all);

my(@pipeline_args) = ('--noautorun', '--input' => '-');
push(@pipeline_args,
    dbcolcreate('test2'),
    dbroweval('_test2 = _test1 + 10;')
);
my $pipeline = dbpipeline(@pipeline_args);
$pipeline->setup_run_finish;
exit 0;

