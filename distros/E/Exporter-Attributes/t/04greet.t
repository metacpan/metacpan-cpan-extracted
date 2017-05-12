#!/usr/bin/perl

use warnings;
use strict;
use lib 't/testlib';
use Test::More tests => 3;

use MyExport qw(:greet);

is( hello(), MyExport::hello(), 'exported sub hello()' );
is( hi(),    MyExport::hi(),    'exported sub hi()' );
is( hey(),   MyExport::hey(),   'exported sub hey()' );
