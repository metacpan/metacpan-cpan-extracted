#!/usr/bin/perl -w
use warnings;
use strict;

use Test::More qw(no_plan);

use_ok('Lorem');
use Lorem::Util qw( in2pt pt2in );




my $doc    = Lorem->new_document;
isa_ok $doc, 'Lorem::Document';



