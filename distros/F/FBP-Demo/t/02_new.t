#!/usr/bin/perl

use 5.008;
use strict;
use warnings;

use Test::More tests => 2;
use Test::NoWarnings;
use FBP::Demo ();

# Test basic application creation
my $application = FBP::Demo->new;
isa_ok( $application, 'FBP::Demo' );
