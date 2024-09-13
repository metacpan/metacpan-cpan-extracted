#!/usr/bin/perl

use v5.14;  # package NAME {BLOCK}
use warnings;

use Test2::V0;

use Syntax::Keyword::Try;

use Metrics::Any '$metrics', strict => 0;

package Metrics::Any::Adapter::_ToHash {
   sub new {
      my $class = shift;
      return bless { h => shift }, $class;
   }

   sub make_counter {}
   sub make_distribution {}
   sub make_gauge {}
   sub make_timer {}

   sub _inc { $_[0]->{h}->{$_[1]} += $_[2] }
   no warnings 'once';
   *inc_counter_by = *report_distribution = *inc_gauge_by = *report_timer = \&_inc;
}

package Metrics::Any::Adapter::_Dies {
   sub new { bless {}, shift }

   no warnings 'once';
   *make_counter = *make_distribution = *make_gauge = *make_timer = sub {};

   *inc_counter_by = *report_distribution = sub { die "die for best-effort test" };
}

require Metrics::Any::Adapter;
Metrics::Any::Adapter->import( Routable =>
   targets => [
      [ default => _ToHash => \my %metricsA ],
      [ default => _Dies => ],
      [ default => _ToHash => \my %metricsB ],
   ],
);

{
   $metrics->make_counter( counter => );

   my $err;
   try {
      $metrics->inc_counter( counter => );
   }
   catch ( $e ) {
      $err = $e;
   }

   like( $err, qr/^die for best-effort test at /, 'Exception is propagated' );
   is( \%metricsA, { "main/counter" => 1 },
      'Metrics still reported before failure' );
   is( \%metricsB, { "main/counter" => 1 },
      'Metrics still reported after failure' );
}

done_testing;
