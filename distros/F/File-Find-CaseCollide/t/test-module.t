#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 1;
use Test::File::Find::CaseCollide ();

# TEST
Test::File::Find::CaseCollide->verify( { dir => '.' } );
