#!/usr/bin/perl
use strict;
use warnings;

use Fennec::Lite;

our $CLASS = "Exporter::Declare::Export::Variable";
require_ok $CLASS;
isa_ok( $CLASS, 'Exporter::Declare::Export' );

done_testing;
