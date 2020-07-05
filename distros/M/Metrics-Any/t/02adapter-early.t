#!/usr/bin/perl

use v5.14;  # package NAME {BLOCK}
use warnings;

use Test::More;

my @method_call_args;

package Metrics::Any::Adapter::Testing {
   sub new { bless {}, shift }

   sub make_counter   { shift; push @method_call_args, [ make_counter => @_ ] }
   sub inc_counter_by { shift; push @method_call_args, [ inc_counter_by => @_ ] }
}

use Metrics::Any::Adapter 'Testing';
use Metrics::Any '$metrics';

$metrics->make_counter( handle => name => "the_name" );
$metrics->inc_counter( handle => );

is_deeply( \@method_call_args,
   [
      [qw( make_counter main/handle ), collector => $metrics, name => "the_name" ],
      [qw( inc_counter_by main/handle 1 )],
   ],
   'Adapter methods invoked'
);

done_testing;
