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

my $out = FTN::Outbound::BSO -> new( outbound_root => File::Spec -> tmpdir,
                                     domain => 'fidonet',
                                     zone => 15,
                                     domain_abbrev => { fidonet => 'out',
                                                      },
                                   );

ok( defined $out, 'object creating' );

# let's fake scanning
$out -> {scanned}{fidonet}{14} = { 'Out.00e' => {},
                                   'out.00E' => { 451 => { 31 => { points_dir => { '01c3001f.pnt' => 'the best' },
                                                                 },
                                                         },
                                                },
                                   'out.00e' => {},
                                 };
is( $out -> _select_points_dir( 'fidonet', 14, 451, 31 ), 'the best', 'our_domain.other_zone does not have points dir, but our_domain.Other_Zone does' );

$out -> {scanned}{fidonet}{14} = { 'ouT.00e' => {},
                                   'ouT.00E' => { 451 => { 31 => { points_dir => { '01c3001f.pnt' => 'the best' },
                                                                 },
                                                         },
                                                },
                                   'out.00e' => {},
                                 };
is( $out -> _select_points_dir( 'fidonet', 14, 451, 31 ), 'the best', 'our_domain.other_zone does not have points dir, but our_domain.Other_Zone does - 2' );

$out -> {scanned}{fidonet}{15} = { 'out' => {},
                                   'ouT' => { 451 => { 31 => { points_dir => { '01c3001f.pnt' => 'the best' },
                                                             },
                                                     },
                                            },
                                   'Out' => {},
                                 };
is( $out -> _select_points_dir( 'fidonet', 15, 451, 31 ), 'the best', 'our_domain (our_zone) does not have points dir, but Our_Domain does' );

$out -> {scanned}{fidonet}{15} = { 'ouT' => { 451 => { 31 => { points_dir => { '01c3001f.pnt' => 'not the best' },
                                                             },
                                                     },
                                            },
                                   'out' => { 451 => { 31 => { points_dir => { '01c3001f.PnT' => 'the best' },
                                                             },
                                                     },
                                            },
                                   'Out' => {},
                                 };
is( $out -> _select_points_dir( 'fidonet', 15, 451, 31 ), 'the best', 'our_domain and Our_Domain have point dirs, but our_domain does not have best formatting of it' );

$out -> {scanned}{fidonet}{15} = { 'out' => {},
                                   'Out' => { 451 => { 31 => { points_dir => { '01c3001f.PnT' => 'not the best' },
                                                             },
                                                     },
                                            },
                                   'ouT' => { 451 => { 31 => { points_dir => { '01c3001f.pnt' => 'the best' },
                                                             },
                                                     },
                                            },
                                 };
is( $out -> _select_points_dir( 'fidonet', 15, 451, 31 ), 'the best', 'our_Domain and Our_Domain have point dirs, but one of them has best formatting of it' );

# $out -> {scanned}{fidonet}{15} = { 'out' => {},
#                                    'Out' => { 451 => { 31 => { points_dir => { '01c3001f.pnt' => 'the best' },
#                                                              },
#                                                      },
#                                             },
#                                    # 'ouT' => { 451 => { 31 => { points_dir => { '01c3001f.pnt' => 'not the best' },
#                                    #                           },
#                                    #                   },
#                                    #          },
#                                  };
# is( $out -> _select_points_dir( 'fidonet', 15, 451, 31 ), 'the best', 'our_Domain and Our_Domain have point dirs and both of them have best formatting of it' );

# $out -> {scanned}{fidonet}{15} = { 'out' => {},
#                                    'Out' => { 451 => { 31 => { points_dir => { '01c3001f.PnT' => 'the best' },
#                                                              },
#                                                      },
#                                             },
#                                    'ouT' => { 451 => { 31 => { points_dir => { '01c3001f.pNt' => 'not the best' },
#                                                              },
#                                                      },
#                                             },
#                                  };
# is( $out -> _select_points_dir( 'fidonet', 15, 451, 31 ), 'the best', 'our_Domain and Our_Domain have point dirs and none of them have best formatting of it' );

$out -> {scanned}{fidonet}{15} = { 'out' => {},
                                   'Out' => { 451 => { 31 => { points_dir => { '01c3001f.PnT' => 'not the best' },
                                                             },
                                                     },
                                            },
                                   'ouT' => { 451 => { 31 => { points_dir => { '01c3001f.pNt' => 'not the best',
                                                                               '01c3001f.pnt' => 'the best',
                                                                             },
                                                             },
                                                     },
                                            },
                                 };
is( $out -> _select_points_dir( 'fidonet', 15, 451, 31 ), 'the best', 'our_Domain and Our_Domain have point dirs (not ideally formatted) plus one of them has ideally formatted points dir' );
__END__
$out -> {scanned}{fidonet}{15} = { 'out.00f' => 1,
                                   'ouT' => 2,
                                   'out.00F' => 3,
                                 };
is( $out -> _select_points_dir( 'fidonet', 15 ), 'ouT', 'our domain our zone, another domain casing' );

# $out -> {scanned}{fidonet}{15} = { 'out.00f' => 1,
#                                  };
# is( $out -> _select_points_dir( 'fidonet', 15 ), 'out.00f', 'our domain our zone, no without zone extension' );

$out -> {scanned}{fidonet} = { 255 => { 'out.0fF' => 1,
                                        'out.0ff' => 2,
                                        'out.0Ff' => 3,
                                      },
                             };
is( $out -> _select_points_dir( 'fidonet', 255 ), 'out.0ff', 'our domain another zone' );

$out -> {scanned}{fidonet} = { 255 => { 'out.0fF' => 1,
                                      },
                             };
is( $out -> _select_points_dir( 'fidonet', 255 ), 'out.0fF', 'our domain another zone' );
