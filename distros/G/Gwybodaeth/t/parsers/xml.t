#!/usr/bin/env perl

use strict;
use warnings;

use lib '../../lib';

use Test::More qw{no_plan};

BEGIN { use_ok( 'Gwybodaeth::Parsers::XML' ); }

my $xml = new_ok( 'Gwybodaeth::Parsers::XML' );
