#!/usr/bin/perl
# 02-ctime_new_thread.t - [description]
# Copyright (c) 2006 Jonathan T. Rockway

use Test::More;
use File::CreationTime qw(creation_time);

plan skip_all=>"files from 01-ctime not found" 
  if !-r "new.file" && !-r "new.file.time";

plan tests=>1;

open my $timefile, "<new.file.time";
my $ctime = <$timefile>;
chomp $ctime;
close $timefile;

is(creation_time("new.file"), $ctime, "creation time matches saved time");

unlink("new.file");
unlink("new.file.time");


