#!perl

use strict;
use warnings;

use Test::More;

use DateTime           qw( );
use DateTime::TimeZone qw( );
use DateTimeX::Start   qw( :ALL );


sub dt {
   return
      DateTime->new(
         year   => $_[0],
         month  => $_[1],
         day    => $_[2],
         hour   => $_[3] || 0,
         minute => $_[4] || 0,
         second => $_[5] || 0,
         time_zone => $_[6] || 'UTC',
      );
}


sub main {
   if ($DateTime::TimeZone::VERSION < 0.18) {
      plan skip_all => "DateTime::TimeZone 0.18 required";
      return;
   }

   my $local_tz_name = DateTime::TimeZone->new( name => 'local' )->name;

   my $nonlocal_tz_name = $local_tz_name eq 'America/Halifax' ? 'America/Vancouver' : 'America/Halifax';

   my $toronto_tz = DateTime::TimeZone->new( name => 'America/Toronto' );

   my @tests = (
      [ 'start_of_date($dt, $tz_name)',        sub { start_of_date(dt(2014, 2, 3, 4, 5, 6), 'America/Toronto') },  sub { dt(2014, 2, 3, 0, 0, 0, 'America/Toronto') } ],
      [ 'start_of_date([$y,$m,$d], $tz_name)', sub { start_of_date([ 2014, 2, 3 ],          'America/Toronto') },  sub { dt(2014, 2, 3, 0, 0, 0, 'America/Toronto') } ],
      [ 'start_of_date([$y,$m], $tz_name)',    sub { start_of_date([ 2014, 2    ],          'America/Toronto') },  sub { dt(2014, 2, 1, 0, 0, 0, 'America/Toronto') } ],
      [ 'start_of_date([$y], $tz_name)',       sub { start_of_date([ 2014,      ],          'America/Toronto') },  sub { dt(2014, 1, 1, 0, 0, 0, 'America/Toronto') } ],

      [ 'start_of_date($dt, $tz)',             sub { start_of_date(dt(2014, 2, 3, 4, 5, 6), $toronto_tz) },        sub { dt(2014, 2, 3, 0, 0, 0, $toronto_tz) } ],
      [ 'start_of_date([$y,$m,$d], $tz)',      sub { start_of_date([ 2014, 2, 3 ],          $toronto_tz) },        sub { dt(2014, 2, 3, 0, 0, 0, $toronto_tz) } ],
      [ 'start_of_date([$y,$m], $tz)',         sub { start_of_date([ 2014, 2    ],          $toronto_tz) },        sub { dt(2014, 2, 1, 0, 0, 0, $toronto_tz) } ],
      [ 'start_of_date([$y], $tz)',            sub { start_of_date([ 2014,      ],          $toronto_tz) },        sub { dt(2014, 1, 1, 0, 0, 0, $toronto_tz) } ],

      [ 'start_of_date($dt)',                  sub { start_of_date(dt(2014, 2, 3, 4, 5, 6, $nonlocal_tz_name)) },  sub { start_of_date(dt(2014, 2, 3, 4, 5, 6, $nonlocal_tz_name), $nonlocal_tz_name) } ],
      [ 'start_of_date([$y,$m,$d])',           sub { start_of_date([ 2014, 2, 3 ])                             },  sub { start_of_date([ 2014, 2, 3 ], $local_tz_name)                                } ],
      [ 'start_of_date([$y,$m])',              sub { start_of_date([ 2014, 2    ])                             },  sub { start_of_date([ 2014, 2    ], $local_tz_name)                                } ],
      [ 'start_of_date([$y])',                 sub { start_of_date([ 2014,      ])                             },  sub { start_of_date([ 2014,      ], $local_tz_name)                                } ],


      [ 'start_of_month($dt, $tz_name)',       sub { start_of_month(dt(2014, 2, 3, 4, 5, 6), 'America/Toronto') }, sub { dt(2014, 2, 1, 0, 0, 0, 'America/Toronto') } ],
      [ 'start_of_month([$y,$m], $tz_name)',   sub { start_of_month([ 2014, 2 ],             'America/Toronto') }, sub { dt(2014, 2, 1, 0, 0, 0, 'America/Toronto') } ],
      [ 'start_of_month([$y], $tz_name)',      sub { start_of_month([ 2014    ],             'America/Toronto') }, sub { dt(2014, 1, 1, 0, 0, 0, 'America/Toronto') } ],

      [ 'start_of_month($dt, $tz)',            sub { start_of_month(dt(2014, 2, 3, 4, 5, 6), $toronto_tz) },       sub { dt(2014, 2, 1, 0, 0, 0, $toronto_tz) } ],
      [ 'start_of_month([$y,$m], $tz)',        sub { start_of_month([ 2014, 2 ],             $toronto_tz) },       sub { dt(2014, 2, 1, 0, 0, 0, $toronto_tz) } ],
      [ 'start_of_month([$y], $tz)',           sub { start_of_month([ 2014    ],             $toronto_tz) },       sub { dt(2014, 1, 1, 0, 0, 0, $toronto_tz) } ],

      [ 'start_of_month($dt)',                 sub { start_of_month(dt(2014, 2, 3, 4, 5, 6, $nonlocal_tz_name)) }, sub { start_of_month(dt(2014, 2, 3, 4, 5, 6, $nonlocal_tz_name), $nonlocal_tz_name) } ],
      [ 'start_of_month([$y,$m])',             sub { start_of_month([ 2014, 2 ])                                }, sub { start_of_month([ 2014, 2 ], $local_tz_name)                                   } ],
      [ 'start_of_month([$y])',                sub { start_of_month([ 2014    ])                                }, sub { start_of_month([ 2014    ], $local_tz_name)                                   } ],


      [ 'start_of_year($dt, $tz_name)',        sub { start_of_year(dt(2014, 2, 3, 4, 5, 6), 'America/Toronto') },  sub { dt(2014, 1, 1, 0, 0, 0, 'America/Toronto') } ],
      [ 'start_of_year([$y], $tz_name)',       sub { start_of_year([ 2014 ],                'America/Toronto') },  sub { dt(2014, 1, 1, 0, 0, 0, 'America/Toronto') } ],

      [ 'start_of_year($dt, $tz)',             sub { start_of_year(dt(2014, 2, 3, 4, 5, 6), $toronto_tz) },        sub { dt(2014, 1, 1, 0, 0, 0, $toronto_tz) } ],
      [ 'start_of_year([$y], $tz)',            sub { start_of_year([ 2014 ],                $toronto_tz) },        sub { dt(2014, 1, 1, 0, 0, 0, $toronto_tz) } ],

      [ 'start_of_year($dt)',                  sub { start_of_year(dt(2014, 2, 3, 4, 5, 6, $nonlocal_tz_name)) },  sub { start_of_year(dt(2014, 2, 3, 4, 5, 6, $nonlocal_tz_name), $nonlocal_tz_name) } ],
      [ 'start_of_year([$y])',                 sub { start_of_year([ 2014 ])                                   },  sub { start_of_year([ 2014 ], $local_tz_name)                                      } ],


      [ 'start_of_today($tz_name)',            sub { start_of_today('America/Toronto') },                          sub { DateTime->today( time_zone => 'America/Toronto') } ],

      [ 'start_of_today($tz)',                 sub { start_of_today($toronto_tz) },                                sub { DateTime->today( time_zone => $toronto_tz) } ],

      [ 'start_of_today()',                    sub { start_of_today() },                                           sub { start_of_today($local_tz_name) } ],
   );

   plan tests => 0+@tests;

   for my $test (@tests) {
      my ($name, $test_code, $expected_code) = @$test;

      my $got_dt = eval { $test_code->() };
      if (!$got_dt) {
         my $e = $@;
         fail($name)
            or diag("Got exception executing test: $@");

         next;
      }

      my $expected_dt = eval { $expected_code->() };
      if (!$expected_dt) {
         my $e = $@;
         fail($name)
            or diag("Got exception determining expected value: $@");

         next;
      }

      my ($got, $expected) = map { join(' ', $_->epoch, $_->strftime('%Y-%m-%dT%H:%M:%S%z'), $_->time_zone->name) } $got_dt, $expected_dt;
      is($got, $expected, $name);
   }
}

main();
