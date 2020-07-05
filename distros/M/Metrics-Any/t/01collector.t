#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;
use Test::Fatal;

use Metrics::Any '$metrics', strict => 1;

ok( defined $metrics, '$metrics global is defined' );

# counter
{
   can_ok( $metrics,
      qw( make_counter inc_counter inc_counter_by ));

   $metrics->make_counter( c => );

   ok( exception { $metrics->make_counter( c => ) },
      'Fails duplicate registration of counter' );

   ok( !exception { $metrics->inc_counter( c => ) },
      'Can report to registered counter' );
   ok( exception { $metrics->inc_counter( c2 => ) },
      'Fails attempt to report to unregistered counter' );
}

# distribution
{
   can_ok( $metrics,
      qw( make_distribution report_distribution ));

   $metrics->make_distribution( d => );

   ok( exception { $metrics->make_distribution( d => ) },
      'Fails registration of distribution' );

   ok( !exception { $metrics->report_distribution( d => 5 ) },
      'Can report to registered distribution' );
   ok( exception { $metrics->report_distribution( d2 => 5 ) },
      'Fails attempt to report to unregistered distribution' );
}

# gauge
{
   can_ok( $metrics,
      qw( make_gauge inc_gauge inc_gauge_by dec_gauge_by dec_gauge set_gauge_to ));

   $metrics->make_gauge( g => );

   ok( exception { $metrics->make_gauge( g => ) },
      'Fails duplicate registration of gauge' );

   ok( !exception { $metrics->inc_gauge( g => ) },
      'Can report to registered gauge' );
   ok( exception { $metrics->inc_gauge( g2 => ) },
      'Fails attempt to report to unregistered gauge' );
}

# timer
{
   can_ok( $metrics,
      qw( make_timer report_timer ));

   $metrics->make_timer( t => );

   ok( exception { $metrics->make_timer( t => ) },
      'Fails duplicate registration of timer' );

   ok( !exception { $metrics->report_timer( t => ) },
      'Can report to registered timer' );
   ok( exception { $metrics->report_timer( t2 => ) },
      'Fails attempt to report to unregistered timer' );
}

# misc
{
   is( $metrics->package, "main", '$metrics->package' );
}

done_testing;
