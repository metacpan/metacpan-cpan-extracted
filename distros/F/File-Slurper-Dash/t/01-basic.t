#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use File::Slurper qw(read_text read_binary write_text write_binary);
use File::Temp qw(tempdir);
use IPC::Run;

ok 1;
done_testing;
