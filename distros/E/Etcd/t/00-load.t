#!perl

use strict;
use warnings;

use Test::More tests => 1;

require_ok('Etcd');

local $Etcd::VERSION = $Etcd::VERSION || 'from repo';
note("Etcd $Etcd::VERSION, Perl $], $^X");
