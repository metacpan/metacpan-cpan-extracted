#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 1;
use Test::Differences (qw( eq_or_diff ));
use File::Find::CaseCollide ();

my $obj     = File::Find::CaseCollide->new( { dir => '.' } );
my $results = $obj->find;

# TEST
eq_or_diff( $results, {}, "No results were found." );
