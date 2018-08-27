#!/usr/bin/env perl
use lib 'lib';

use strict;
use warnings;

use Test::More tests => 8;
use File::Spec ();

BEGIN {
  use_ok( 'FTN::Outbound::BSO' );
}

Log::Log4perl -> easy_init( $Log::Log4perl::DEBUG );

my $out = FTN::Outbound::BSO
  -> new( outbound_root => File::Spec -> tmpdir,
          domain => 'fidonet',
          zone => 15,
          domain_abbrev => { fidonet => 'out',
                           },
        );

ok( defined $out, 'object creating' );

# let's fake scanning
$out -> {scanned}{fidonet}{15} = { 'out.00f' => 1,
                                   'out' => 2,
                                   'out.00F' => 3,
                                 };
is( $out -> _select_domain_zone_dir( 'fidonet', 15 ), 'out', 'our domain our zone' );

$out -> {scanned}{fidonet}{15} = { 'out.00f' => 1,
                                   'ouT' => 2,
                                   'out.00F' => 3,
                                 };
is( $out -> _select_domain_zone_dir( 'fidonet', 15 ), 'ouT', 'our domain our zone, another domain casing' );

# this is a good test, but commented out, as it would create a correct dir and we bypass that
# $out -> {scanned}{fidonet}{15} = { 'out.00f' => 1,
#                                  };
# is $out -> _select_domain_zone_dir( 'fidonet', 15 ),
#   'out.00f',
#   'our domain our zone, no without zone extension' );

$out -> {scanned}{fidonet} = { 255 => { 'out.0fF' => 1,
                                        'out.0ff' => 2,
                                        'out.0Ff' => 3,
                                      },
                             };
is $out -> _select_domain_zone_dir( 'fidonet', 255 ),
  'out.0ff',
  'our domain another zone choosing the best from the existing ones (and the really best is there)';

$out -> {scanned}{fidonet} = { 255 => { 'out.0fF' => 1,
                                      },
                             };
is $out -> _select_domain_zone_dir( 'fidonet', 255 ),
  'out.0fF',
  'our domain another zone the only one dir';


$out -> {scanned}{fidonet} = { 255 => { 'out.0fF' => 1,
                                        'out.0Ff' => 2,
                                        'out.0FF' => 3,
                                      },
                             };
is $out -> _select_domain_zone_dir( 'fidonet', 255 ),
  'out.0fF',
  'our domain another zone choosing the best from the existing ones';

$out -> {scanned}{fidonet} = { 255 => { 'out.0FF' => 1,
                                        'out.0Ff' => 2,
                                        'out.0FF' => 3,
                                        'out.0fF' => 4,
                                      },
                             };
is $out -> _select_domain_zone_dir( 'fidonet', 255 ),
  'out.0fF',
  'our domain another zone choosing the best from the existing ones (more not best choices)';
