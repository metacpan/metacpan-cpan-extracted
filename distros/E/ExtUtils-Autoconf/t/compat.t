#!perl

use strict;
use warnings;
use Test::More tests => 2;
use ExtUtils::Autoconf;

can_ok( 'ExtUtils::Autoconf', 'reconf' );
is( ExtUtils::Autoconf->can('reconf'), ExtUtils::Autoconf->can('autogen'), 'reconf does the same than autogen' );
