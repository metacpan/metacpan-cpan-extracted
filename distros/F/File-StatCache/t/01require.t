#!/usr/bin/perl -w

use strict;

use Test::More tests => 1;

use_ok( "File::StatCache", qw( stat get_stat get_item_mtime ) );
