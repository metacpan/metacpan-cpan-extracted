#!perl
use 5.20.0;
use strict;
use warnings FATAL => 'all';
use lib 't';
use Test::More;

my @layers_before = PerlIO::get_layers(STDERR);

require Mail::TLSRPT::Report;

is_deeply( [ PerlIO::get_layers(STDERR) ], \@layers_before, 'loading the classes leaves STDERR layers alone' );

done_testing;
