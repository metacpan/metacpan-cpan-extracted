#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf;

my @trace;
neaf helper => log_printf => sub { push @trace, $_[2] };

get '/' => sub { $_[0]->log_printf( debug => "foo" ); +{} };

neaf->run_test( "/" );

is_deeply \@trace, ["foo"], "Captured output";

done_testing;
