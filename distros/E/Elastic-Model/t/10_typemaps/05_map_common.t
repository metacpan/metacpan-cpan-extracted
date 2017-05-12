#!/usr/bin/perl

use strict;
use warnings;

our $test_class = 'TypeTest::Common';
our @mapping = ( 'datetime' => { type => 'date' }, );

do 't/10_typemaps/test_mapping.pl' or die $!;

1;
