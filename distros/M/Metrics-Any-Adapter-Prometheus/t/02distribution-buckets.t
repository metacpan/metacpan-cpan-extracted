#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Metrics::Any 0.05 '$metrics';
use Metrics::Any::Adapter 'Prometheus';

use Net::Prometheus;

my $prom = Net::Prometheus->new;

# Decade buckets
{
   $metrics->make_distribution( default =>
      units => "",
      buckets_per_decade => [ 1 ],
   );
   $metrics->report_distribution( default => 0 );

   is_deeply( [ grep { m/^default_bucket/ } split m/\n/, $prom->render ],
      [ map { "default_bucket{le=\"$_\"} 1" } 1E-3, 1E-2, 1E-1, 1E0, 1E1, 1E2, 1E3, "+Inf" ],
      'Net::Prometheus->render contains default decade buckets'
   );

   # Large
   $metrics->make_distribution( large =>
      units => "",
      bucket_min => 1,
      bucket_max => 1E6,
   );
   $metrics->report_distribution( large => 0 );

   is_deeply( [ grep { m/^large_bucket/ } split m/\n/, $prom->render ],
      [ map { "large_bucket{le=\"$_\"} 1" } 1E0, 1E1, 1E2, 1E3, 1E4, 1E5, 1E6, "+Inf" ],
      'Net::Prometheus->render contains large decade buckets'
   );

   # Small
   $metrics->make_distribution( small =>
      units => "",
      bucket_min => 1E-6,
      bucket_max => 1,
   );
   $metrics->report_distribution( small => 0 );

   is_deeply( [ grep { m/^small_bucket/ } split m/\n/, $prom->render ],
      [ map { "small_bucket{le=\"$_\"} 1" } 1E-6, 1E-5, 1E-4, 1E-3, 1E-2, 1E-1, 1E0, "+Inf" ],
      'Net::Prometheus->render contains small decade buckets'
   );
}

# Custom buckets
{
   # Generate E6 values
   $metrics->make_distribution( E6 =>
      units => "",
      bucket_min => 1,
      buckets_per_decade => [ 1, 1.5, 2.2, 3.3, 4.7, 6.8 ],
   );
   $metrics->report_distribution( E6 => 0 );

   is_deeply( [ grep { m/^E6_bucket/ } split m/\n/, $prom->render ],
      [ map { "E6_bucket{le=\"$_\"} 1" }
         1.0, 1.5, 2.2, 3.3, 4.7, 6.8,
          10,  15,  22,  33,  47,  68,
         100, 150, 220, 330, 470, 680,
        1000, "+Inf",
      ],
      'Net::Prometheus->render contains custom value buckets'
   );
}

done_testing;
