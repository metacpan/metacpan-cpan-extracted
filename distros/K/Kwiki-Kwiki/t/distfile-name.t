#!/usr/bin/perl

use strict;
use Kwiki::Kwiki::Command::Distfile;
use Test::More tests => 1;
use Cwd qw(cwd);
use File::Temp qw(tempdir);
use File::Basename;

print cwd(), "\n";

my $dir = tempdir ( CLEANUP => 1 );

chdir($dir);

is(basename($dir).".tar.gz", Kwiki::Kwiki::Command::Distfile->new->distfile_name);


