#! /usr/bin/env perl
use strict;
use warnings;
no warnings 'once', 'redefine';
use Test::More;
use Data::Printer;

use_ok( 'Exporter::Handy' ) or BAIL_OUT;

done_testing;