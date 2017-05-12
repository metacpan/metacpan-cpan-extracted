#!/usr/bin/perl -w

use strict;
use Test::More tests => 1;

use_ok( "IO::Async::Loop::Mojo" );

# It's useful when reporting results to know what reactor type was being used
my $loop = IO::Async::Loop::Mojo->new;
my $reactor = $loop->{reactor};
diag( "Using " . ref($reactor) );
