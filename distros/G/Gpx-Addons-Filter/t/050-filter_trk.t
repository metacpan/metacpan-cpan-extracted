#!/usr/bin/perl -T

# $Id: --- $
# Created by Ingo Lantschner on 2009-06-24.
# Copyright (c) 2009 Ingo Lantschner. All rights reserved.
# ingo@boxbe.com, http://ingo@lantschner.name

#use warnings;
use strict;

#use lib '/Users/ingolantschner/Perl/lib';

# Debugging
use Data::Dumper;
our $DEBUG = 0;
#use Smart::Comments '###';

use Test::More tests => 42;
use Test::Output;
#use Test::Exception;
use Gpx::Addons::Filter qw( filter_trk );
use Geo::Gpx;

my $gpx = Geo::Gpx->new();

# The follwing datastructure sets up the testcase.
# pos-key of points: not evaluated - forget them
#
# posN-key of segments:
# possible values: in | out | on_limit   - define the position relativ to the tested timeframe 
# pos1: 1234560000, 1234570000
# pos2: 1234560000, undef
# pos3: undef, 1234570000
#
# cmt: Description of the segment

my $tracks = [
    {
        'name'     => 'Track A-C',
        'segments' => [
            {
                'points' => [
                    {
                        lat  => '54.5182217145253',
                        lon  => '-2.62191579018834',
                        time => 1234510000,
                        pos  => 'out',
                    },
                    {
                        lat  => '54.1507759448355',
                        lon  => '-3.05774931478646',
                        time => 1234510005,
                        pos  => 'out',
                    },
                    {
                        lat  => '54.6016296784874',
                        lon  => '-3.40418920968631',
                        time => 1234530000,
                        pos  => 'out',
                    }
                ],
                cmt => 'Segment A before the timeframe',
                pos1 => 'out',
                pos2 => 'out',
                pos3 => 'in',
            },
            {
                'points' => [
                    {
                        lat  => '54.5182217145253',
                        lon  => '-2.62191579018834',
                        time => 1234520000,
                        pos  => 'out',
                    },
                    {
                        lat  => '54.1507759448355',
                        lon  => '-3.05774931478646',
                        time => 1234530005,
                        pos  => 'out',
                    },
                    {
                        lat  => '54.6016296784874',
                        lon  => '-3.40418920968631',
                        time => 1234560000,
                        pos  => 'on_limit',
                    }
                ],
                cmt => 'Segment B touching the beginning of the timeframe',
                pos1 => 'in',
                pos2 => 'in',
                pos3 => 'in',
            },
            {
                'points' => [
                    {
                        lat  => '54.5182217145253',
                        lon  => '-2.62191579018834',
                        time => 1234520000,
                        pos  => 'out',
                    },
                    {
                        lat  => '54.1507759448355',
                        lon  => '-3.05774931478646',
                        time => 1234530005,
                        pos  => 'out',
                    },
                    {
                        lat  => '54.6016296784874',
                        lon  => '-3.40418920968631',
                        time => 1234565000,
                        pos  => 'in',
                    }
                ],
                cmt => 'Segment C with endpoint within the timeframe',
                pos1 => 'in',
                pos2 => 'in',
                pos3 => 'in',
            },

            # Single Point Segments
            {
                'points' => [
                    {
                        lat  => '54.6862790450185',
                        lon  => '-3.68760108982739',
                        time => 1234550000,
                        pos  => 'out',
                    }
                ],
                cmt => 'Single Point Segment X',
                pos1 => 'out',
                pos2 => 'out',
                pos3 => 'in',
            },
            {
                'points' => [
                    {
                        lat  => '54.6862790450185',
                        lon  => '-3.68760108982739',
                        time => 1234565000,
                        pos  => 'in',
                    }
                ],
                cmt => 'Single Point Segment Y',
                pos1 => 'in',
                pos2 => 'in',
                pos3 => 'in',
            },
            {
                'points' => [
                    {
                        lat  => '54.6862790450185',
                        lon  => '-3.68760108982739',
                        time => 1234575000,
                        pos  => 'out',
                    }
                ],
                cmt => 'Single Point Segment Z',
                pos1 => 'out',
                pos2 => 'in',
                pos3 => 'out',
                
            }
        ]
    },

    # More segments heading to the end of the timeframe
    {
        'name'     => 'Track D-I',
        'segments' => [
            {
                'points' => [
                    {
                        lat  => '54.5182217145253',
                        lon  => '-2.62191579018834',
                        time => 1234560000,
                        pos  => 'on_limit',
                    },
                    {
                        lat  => '54.1507759448355',
                        lon  => '-3.05774931478646',
                        time => 1234565005,
                        pos  => 'in',
                    },
                    {
                        lat  => '54.6016296784874',
                        lon  => '-3.40418920968631',
                        time => 1234568000,
                        pos  => 'in',
                    }
                ],
                cmt => 'Segment D with startpoint touching the beginning and endpoint within timeframe',
                pos1 => 'in',
                pos2 => 'in',
                pos3 => 'in',
            },
            {
                'points' => [
                    {
                        lat  => '54.5182217145253',
                        lon  => '-2.62191579018834',
                        time => 1234560000,
                        pos  => 'on_limit',
                    },
                    {
                        lat  => '54.1507759448355',
                        lon  => '-3.05774931478646',
                        time => 1234565005,
                        pos  => 'in',
                    },
                    {
                        lat  => '54.6016296784874',
                        lon  => '-3.40418920968631',
                        time => 1234568000,
                        pos  => 'on_limit',
                    }
                ],
                cmt => 'Segment matching exactly the timeframe',
                pos1 => 'in',
                pos2 => 'in',
                pos3 => 'in',
            },
            {
                'points' => [
                    {
                        lat  => '54.5182217145253',
                        lon  => '-2.62191579018834',
                        time => 1234500000,
                        pos  => 'out',
                    },
                    {
                        lat  => '54.1507759448355',
                        lon  => '-3.05774931478646',
                        time => 1234565005,
                        pos  => 'in',
                    },
                    {
                        lat  => '54.6016296784874',
                        lon  => '-3.40418920968631',
                        time => 1234580000,
                        pos  => 'out',
                    }
                ],
                cmt => 'Segment overspanning the timeframe (with one middle-point within)',
                pos1 => 'in',
                pos2 => 'in',
                pos3 => 'in',
            },
            {
                'points' => [
                    {
                        lat  => '54.5182217145253',
                        lon  => '-2.62191579018834',
                        time => 1234565000,
                        pos  => 'in',
                    },
                    {
                        lat  => '54.1507759448355',
                        lon  => '-3.05774931478646',
                        time => 1234565005,
                        pos  => 'in',
                    },
                    {
                        lat  => '54.6016296784874',
                        lon  => '-3.40418920968631',
                        time => 1234568000,
                        pos  => 'in',
                    }
                ],
                cmt => 'Segment E completely within the timeframe',
                pos1 => 'in',
                pos2 => 'in',
                pos3 => 'in',
            },
            {
                'points' => [
                    {
                        lat  => '54.5182217145253',
                        lon  => '-2.62191579018834',
                        time => 1234565000,
                        pos  => 'in',
                    },
                    {
                        lat  => '54.1507759448355',
                        lon  => '-3.05774931478646',
                        time => 1234565005,
                        pos  => 'in',
                    },
                    {
                        lat  => '54.6016296784874',
                        lon  => '-3.40418920968631',
                        time => 1234570000,
                        pos  => 'on_limit',
                    }
                ],
                cmt => 'Segment F touching the end of the timeframe',
                pos1 => 'in',
                pos2 => 'in',
                pos3 => 'in',
            },
            {
                'points' => [
                    {
                        lat  => '54.5182217145253',
                        lon  => '-2.62191579018834',
                        time => 1234565000,
                        pos  => 'in',
                    },
                    {
                        lat  => '54.1507759448355',
                        lon  => '-3.05774931478646',
                        time => 1234565005,
                        pos  => 'in',
                    },
                    {
                        lat  => '54.6016296784874',
                        lon  => '-3.40418920968631',
                        time => 1234588000,
                        pos  => 'out',
                    }
                ],
                cmt => 'Segment G from within the timeframe ranging over the end',
                pos1 => 'in',
                pos2 => 'in',
                pos3 => 'in',
            },
            {
                'points' => [
                    {
                        lat  => '54.5182217145253',
                        lon  => '-2.62191579018834',
                        time => 1234570000,
                        pos  => 'on_limit',
                    },
                    {
                        lat  => '54.1507759448355',
                        lon  => '-3.05774931478646',
                        time => 1234575005,
                        pos  => 'out',
                    },
                    {
                        lat  => '54.6016296784874',
                        lon  => '-3.40418920968631',
                        time => 1234588000,
                        pos  => 'out',
                    }
                ],
                cmt => 'Segment H touching only the end of the timeframe',
                pos1 => 'in',
                pos2 => 'in',
                pos3 => 'in',
                
            },
            {
                'points' => [
                    {
                        lat  => '54.5182217145253',
                        lon  => '-2.62191579018834',
                        time => 1234571000,
                        pos  => 'out',
                    },
                    {
                        lat  => '54.1507759448355',
                        lon  => '-3.05774931478646',
                        time => 1234585005,
                        pos  => 'out',
                    },
                    {
                        lat  => '54.6016296784874',
                        lon  => '-3.40418920968631',
                        time => 1234598000,
                        pos  => 'out',
                    }
                ],
                cmt => 'Segment I outside (after) the timeframe',
                pos1 => 'out',
                pos2 => 'in',
                pos3 => 'out',
            },
        ]
    },
    # =====================
    # = Confused Segments =
    # =====================
    # 
    # Segments with enpoints earlier than the startpoint (reversed or confused) 
    # should be ignored from fiter_trk (if later versions of this functian can cope wuth such
    # a segement, just remove the ignore-key completely, to include them again into the test)
    #
    # Note: As long as both start- and end-time were given, the present version of this function still
    # selected the right segments. But with seting start- or endpoint to undef, the confusin began. So I 
    # removed the "feature" of processing reversed segments.
    
    {
        'name'     => 'Track with Special-Segments',
        'segments' => [
            {
                'points' => [
                    {
                        lat  => '54.5182217145253',
                        lon  => '-2.62191579018834',
                        time => 1234568000,
                        pos  => 'in',
                    },
                    {
                        lat  => '54.1507759448355',
                        lon  => '-3.05774931478646',
                        time => 1234565005,
                        pos  => 'in',
                    },
                    {
                        lat  => '54.6016296784874',
                        lon  => '-3.40418920968631',
                        time => 1234560000,
                        pos  => 'on_limit',
                    }
                ],
                cmt => 'Confused Segment (time is inversed)',
                pos1 => 'in',
                pos2 => 'in',
                pos3 => 'in',
                ignore  => '',
            },
            {
                'points' => [
                    {
                        lat  => '54.5182217145253',
                        lon  => '-2.62191579018834',
                        time => 1234598000,
                        pos  => 'out',
                    },
                    {
                        lat  => '54.1507759448355',
                        lon  => '-3.05774931478646',
                        time => 1234565005,
                        pos  => 'in',
                    },
                    {
                        lat  => '54.6016296784874',
                        lon  => '-3.40418920968631',
                        time => 1234510000,
                        pos  => 'out',
                    }
                ],
                cmt => 'Confused Segment (time is inversed) with endpoints out of timeframe',
                pos1 => 'in',
                pos2 => 'in',
                pos3 => 'in',
                ignore  => '',
            },
            {
                'points' => [
                    {
                        lat  => '54.5182217145253',
                        lon  => '-2.62191579018834',
                        time => 1234598000,
                        pos  => 'out',
                    },
                    {
                        lat  => '54.1507759448355',
                        lon  => '-3.05774931478646',
                        time => 1234065005,
                        pos  => 'out',
                    },
                    {
                        lat  => '54.6016296784874',
                        lon  => '-3.40418920968631',
                        time => 1234510000,
                        pos  => 'out',
                    }
                ],
                cmt => 'Confused Segment (time is inversed, spans the timeframe) with no points in the timeframe',
                pos1 => 'in',
                pos2 => 'in',
                pos3 => 'in',
                ignore  => '',
            },
            {
                'points' => [
                    {
                        lat  => '54.5182217145253',
                        lon  => '-2.62191579018834',
                        time => 1234598000,
                        pos  => 'out',
                    },
                    {
                        lat  => '54.1507759448355',
                        lon  => '-3.05774931478646',
                        time => 1234595005,
                        pos  => 'out',
                    },
                    {
                        lat  => '54.1507759448355',
                        lon  => '-3.05774931478646',
                        time => 9999999999,
                        pos  => 'out',
                    },
                    {
                        lat  => '54.6016296784874',
                        lon  => '-3.40418920968631',
                        time => 1234590000,
                        pos  => 'out',
                    }
                ],
                cmt => 'Confused Segment (time is inversed, does NOT span the timeframe) with no points in the timeframe',
                pos1 => 'out',
                pos2 => 'in',
                pos3 => 'out',
                ignore  => '',
            },
            {
                'points' => [
                    {
                        lat  => '54.5182217145253',
                        lon  => '-2.62191579018834',
                        time => 9999999999,
                        pos  => 'out',
                    },
                    {
                        lat  => '54.1507759448355',
                        lon  => '-3.05774931478646',
                        time => 1234595005,
                        pos  => 'out',
                    },
                    {
                        lat  => '54.1507759448355',
                        lon  => '-3.05774931478646',
                        time => 1234588888,
                        pos  => 'out',
                    },
                    {
                        lat  => '54.1507759448355',
                        lon  => '-3.05774931478646',
                        time => 1111111111,
                        pos  => 'out',
                    },
                    {
                        lat  => '54.6016296784874',
                        lon  => '-3.40418920968631',
                        time => 0,
                        pos  => 'out',
                    }
                ],
                cmt => 'Confused Segment (time is inversed, spans the timeframe with EXTREME values) ',
                pos1 => 'in',
                pos2 => 'in',
                pos3 => 'in',
                ignore  => '',
            },
        ]
    }
];

$gpx->tracks($tracks);

if ( $DEBUG > 1 ) {
    my $xml = $gpx->xml('1.1');
    print {*STDERR} "$xml\n";
}

# ================================================================
# = Calculate the number of segments inside the different frames =
# ================================================================
# 1 .. start and end point
# 2 .. startpoint only
# 3 .. endpoint only
my ($inside_seg1, $inside_seg2, $inside_seg3) = 0;
foreach my $trk (@{$tracks}) {
    foreach my $seg (@{$trk->{segments}}) {
        next if defined $seg->{ignore};
        $inside_seg1++ if $seg->{pos1} eq 'in';
        $inside_seg2++ if $seg->{pos2} eq 'in';
        $inside_seg3++ if $seg->{pos3} eq 'in';
    }
}

#### Number of segments, that should be in between 1234560000 and 1234570000:    $inside_seg1
#### Number of segments, that should be after 1234560000:                        $inside_seg2
#### Number of segments, that should be before 1234570000:                       $inside_seg3


# =========
# = TESTS =
# =========

say("Testing a time frame with start- and end-point");
my $sel_trks1 = filter_trk( $tracks, 1234560000, 1234570000 );
#### Tracks within timeframe: $sel_trks1
cmp_ok(@{$sel_trks1}, '>' , 0, 'Non-Empty structure since segments match');
my $found_seg1 = 0;
foreach my $trk ( @{$sel_trks1} ) {
    foreach my $seg ( @{ $trk->{segments} } ) {
        $found_seg1++;
        is( $seg->{pos1}, 'in', "$seg->{cmt} selected" );
    }
}
is($found_seg1, $inside_seg1, "Number of selected tracks matches the expectations");


say("\nTesting a time frame with start-point only");
my $sel_trks2 = filter_trk( $tracks, 1234560000, undef );
#### Tracks within timeframe: $sel_trks2
cmp_ok(@{$sel_trks2}, '>' , 0, 'Non-Empty structure since segments match');
my $found_seg2 = 0;
foreach my $trk ( @{$sel_trks2} ) {
    foreach my $seg ( @{ $trk->{segments} } ) {
        $found_seg2++;
        is( $seg->{pos2}, 'in', "$seg->{cmt} selected" );
    }
}
is($found_seg2, $inside_seg2, "Number of selected tracks matches the expectations");

say("\nTesting a time frame with end-point only");
my $sel_trks3 = filter_trk( $tracks, undef, 1234570000 );
#### Tracks within timeframe: $sel_trks3
cmp_ok(@{$sel_trks3}, '>' , 0, 'Non-Empty structure since segments match');
my $found_seg3 = 0;
foreach my $trk ( @{$sel_trks3} ) {
    foreach my $seg ( @{ $trk->{segments} } ) {
        $found_seg3++;
        is( $seg->{pos3}, 'in', "$seg->{cmt} selected" );
    }
}
is($found_seg3, $inside_seg3, "Number of selected tracks matches the expectations");


say("\nSome other Tests");

my $no_tracks = filter_trk( $tracks, 1111111111, 1222222222);
is(@{$no_tracks}, 0, 'Empty structure since no segment matches');

stderr_like( sub {filter_trk( $tracks, 2009-05-01, 2010-01-02) }, qr/^You are working on track-points dated before Jan 1, 1999/);


sub say { print @_, "\n" };