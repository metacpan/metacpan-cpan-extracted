#!/usr/bin/perl

use warnings;
use strict;
use lib 't/testlib';
use Test::More tests => 2;

use MyExport qw(:all :DEFAULT);

is(hello(), MyExport::hello(), 'exported sub hello()');
is(askme(), MyExport::askme(), 'exported sub askme()');
