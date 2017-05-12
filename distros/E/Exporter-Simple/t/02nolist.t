#!/usr/bin/perl

use warnings;
use strict;
use lib 't/testlib';
use Test::More tests => 4;

# only using default imports
use MyExport;

is($foo, 42, 'exported scalar');
is(hello(), MyExport::hello(), 'exported sub hello()');
is_deeply(\%baz, { a => 65, b => 66 }, 'exported hash');
is($Exporter::ExportLevel, 0, 'ExportLevel properly localized');
