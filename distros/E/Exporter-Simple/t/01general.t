#!/usr/bin/perl

use warnings;
use strict;
use lib 't/testlib';
use Test::More tests => 7;

use MyExport qw(:DEFAULT :vars askme);

is($foo, 42, 'exported scalar');
ok(eq_array(\@bar, [2, 3, 5, 7]), 'expected array');
ok(eq_hash(\%baz, { a => 65, b => 66 }), 'expected hash');

$foo = 314;
is(get_foo(), $foo, 'exported sub get_foo()');
is(hello(), MyExport::hello(), 'exported sub hello()');
is(askme(), MyExport::askme(), 'exported sub askme()');
is($Exporter::ExportLevel, 0, 'ExportLevel properly localized');
