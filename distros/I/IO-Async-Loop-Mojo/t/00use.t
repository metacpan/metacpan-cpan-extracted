#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use_ok( "IO::Async::Loop::Mojo" );

# It's useful when reporting results to know what reactor type was being used
my $loop = IO::Async::Loop::Mojo->new;
my $reactor = $loop->{reactor};
diag( "Using " . ref($reactor) );

done_testing;
