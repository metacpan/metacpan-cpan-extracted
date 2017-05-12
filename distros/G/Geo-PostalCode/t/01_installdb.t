#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

use Geo::PostalCode::InstallDB;


mkdir('blib');
mkdir('blib/tests');

ok(Geo::PostalCode::InstallDB->install(zipdata => "t/basictest.data",
                                       db_dir => "blib/tests/basictest"));
ok(Geo::PostalCode::InstallDB->install(zipdata => "t/polevault.data",
                                       db_dir => "blib/tests/polevault"));

exit(0);
