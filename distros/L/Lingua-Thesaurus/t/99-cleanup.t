#!perl
use strict;
use warnings;
use Test::More;

my $db_file    = 'TEST.sqlite';
unlink $db_file;

plan skip_all => "Not a real test file -- just cleaning up";

