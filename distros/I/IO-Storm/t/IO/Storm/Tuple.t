#!/usr/bin/env perl

#===============================================================================
#
#         FILE: Tuple.t
#
#  DESCRIPTION: Test the IO::Storm::Tuple class.
#
#===============================================================================

use strict;
use warnings;

use Data::Dumper;
use Log::Log4perl qw(:easy);
use Test::More;
Log::Log4perl->easy_init($ERROR);

BEGIN { use_ok('IO::Storm::Tuple'); }
my $tuple = IO::Storm::Tuple->new(
    id        => 'test_id',
    component => 'test_comp',
    stream    => 'test_stream',
    task      => 'test_task',
    values    => 'test_values'
);

is ( $tuple->id, 'test_id', '$tuple->id returns right output');
is ( $tuple->component, 'test_comp', '$tuple->component returns right output');
is ( $tuple->stream, 'test_stream', '$tuple->stream returns right output');
is ( $tuple->task, 'test_task', '$tuple->task returns right output');
is ( $tuple->values, 'test_values', '$tuple->values returns right output');

done_testing();
