#!/usr/local/bin/perl -w
use strict;
use warnings;
use lib qw( ../lib ./lib );
use Egg::Helper;
Egg::Helper->run( shift(@ARGV) );
