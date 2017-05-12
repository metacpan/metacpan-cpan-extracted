#!/usr/bin/perl -w

#
# pipeline_basic.pl
# Copyright (C) 2007 by John Heidemann
# $Id: pipeline_threaded.pl 567 2007-11-18 05:23:47Z johnh $
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblibdir for details.
#


use IO::Handle;
use Fsdb::Filter::dbcol;
use Fsdb::Filter::dbroweval;
use Fsdb::Support::Freds;

# do the equivalent of
#
#   cat DATA/grades.jdb | dbcol name test1 | dbroweval '_test1 += 5;'

my $read_fh = new IO::Handle;
my $write_fh = new IO::Handle;
pipe $read_fh, $write_fh;

my $dbcol = new Fsdb::Filter::dbcol('--output' => $write_fh, qw(name test1));
my $dbrow = new Fsdb::Filter::dbroweval('--input' => $read_fh, '_test1 += 5;');

#
# this time, do it with real threads
#
my $rowthr = Fsdb::Support::Freds->new(sub { $dbrow->setup_run_finish; });
# However, reverse the thread start, forcing rowthr to block.
# On my system (Fedora 8, perl 5.8.8), this works correctly sometimes
# and fails others.  It fails more often with sleep().
# The bug is that I didn't thread->join the threads, so the exit 
# below was terminating them.  Who knew that perl didn't do an implicit join?
# See perl bug #48214 for my proposed resolution.
#
# This code was all about perl threads; not clear it ports to Freds.
# threads->yield;
my $colthr = Fsdb::Support::Freds->new(sub { sleep 1; $dbcol->setup_run_finish; });

$rowthr->join;
$colthr->join;

exit 0;
