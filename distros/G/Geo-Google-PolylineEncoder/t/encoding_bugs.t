use strict;
use warnings;

use lib 'lib';
use lib 't/lib';

use Test::More 'no_plan';

use_ok( 'Geo::Google::PolylineEncoder' );

# Test - RT #46337 Truncated levels & points
# Joe Navratil:
# generating a polyline encoding from many moderately complex sets of data ends
# up with the wrong number of levels (as reported by Google's Interactive
# Polyline Encoder Utility,
# http://code.google.com/apis/maps/documentation/polylineutility.html)
# and also fails to display the last few points (in the attached example,
# approximately three points are left off the end when the encoded line is
# rendered).

# Wrong number of levels & fails to display the last few points

my @points =
  (
   { lat => 37.7989715881429, lon => -122.474730627442 },
   { lat => 37.7991044932363, lon => -122.474760648468 },
   { lat => 37.7997304316188, lon => -122.474656120138 },
   { lat => 37.7999895395801, lon => -122.474652853546 },
   { lat => 37.7999212677559, lon => -122.474858626516 },
   { lat => 37.799943774049,  lon => -122.474999623484 },
   { lat => 37.800059487658,  lon => -122.475178420175 },
   { lat => 37.8004643339641, lon => -122.475519161545 },
   { lat => 37.8011545426717, lon => -122.475676860194 },
   { lat => 37.8016095214345, lon => -122.475636726377 },
   { lat => 37.8022878678636, lon => -122.475663162897 },
   { lat => 37.8025453271667, lon => -122.475633288859 },
   { lat => 37.8028771202341, lon => -122.47561651559 },
   { lat => 37.8028878805922, lon => -122.475808002577 },
   { lat => 37.8031295274047, lon => -122.47643430601 },
   { lat => 37.8031161231909, lon => -122.476967879765 },
   { lat => 37.8032644778961, lon => -122.477394945039 },
   { lat => 37.8037137067877, lon => -122.477241719044 },
   { lat => 37.8040357702484, lon => -122.477039498073 },
   { lat => 37.804074836754,  lon => -122.477030419892 },
   { lat => 37.8042903811412, lon => -122.476890165752 },
   { lat => 37.8043130717563, lon => -122.476846736984 },
   { lat => 37.8045306223459, lon => -122.476874043697 },
   { lat => 37.8047248947759, lon => -122.476814977033 },
   { lat => 37.8048390088063, lon => -122.476742060609 },
   { lat => 37.8049875167115, lon => -122.476683316412 },
   { lat => 37.805215742199,  lon => -122.476537473695 },
   { lat => 37.8053411001784, lon => -122.476421204776 },
   { lat => 37.8055118549266, lon => -122.476218070222 },
   { lat => 37.8056829885773, lon => -122.476101482588 },
   { lat => 37.8057514525547, lon => -122.476057729227 },
   { lat => 37.8059114063705, lon => -122.475998899088 },
   { lat => 37.8060597207586, lon => -122.475896887119 },
   { lat => 37.8061846917281, lon => -122.475694084825 },
   { lat => 37.8062987382832, lon => -122.47560673853 },
   { lat => 37.8064240952632, lon => -122.475490457589 },
   { lat => 37.8068497536903, lon => -122.475992265848 },
   { lat => 37.8069530668413, lon => -122.476063663163 },
   { lat => 37.8072028225147, lon => -122.475614758302 },
   { lat => 37.8074184448507, lon => -122.475209374188 },
   { lat => 37.807566300183,  lon => -122.475006390348 },
   { lat => 37.8076348328425, lon => -122.474977061759 },
   { lat => 37.8076922462421, lon => -122.475019925719 },
   { lat => 37.8078186367323, lon => -122.475134426842 },
   { lat => 37.8079338431969, lon => -122.475306691234 },
   { lat => 37.8080370899649, lon => -122.475363658691 },
   { lat => 37.8081513962978, lon => -122.4753339946 },
   { lat => 37.8082195376959, lon => -122.475218129872 },
   { lat => 37.8082881325219, lon => -122.475203216677 },
   { lat => 37.8083685604356, lon => -122.475274770449 },
   { lat => 37.8084830601043, lon => -122.475288375808 },
   { lat => 37.8085746649273, lon => -122.475302154912 },
   { lat => 37.8086436464467, lon => -122.47537378136 },
   { lat => 37.8086897446167, lon => -122.475445581523 },
   { lat => 37.808689937897,  lon => -122.475488848464 },
   { lat => 37.8087364224447, lon => -122.475647179773 },
   { lat => 37.8087487680079, lon => -122.47584902979 },
   { lat => 37.8087500553651, lon => -122.476137500553 },
   { lat => 37.8087969823783, lon => -122.476396793661 },
   { lat => 37.8088896251485, lon => -122.476641351198 },
   { lat => 37.808959235524,  lon => -122.476842375928 },
   { lat => 37.8094273436666, lon => -122.476939682306 },
   { lat => 37.8100228890407, lon => -122.477091685002 },
   { lat => 37.8104463544408, lon => -122.477058875889 },
   { lat => 37.8110915194506, lon => -122.477224017339 },
  );

{
    # Test #1: this is a bootstrapped test, the results below were generated
    # by Geo::Google::PolylineEncoder and verified against Google's
    # Interactive Polyline Utility to confirm they no longer break.

    my $encoder = Geo::Google::PolylineEncoder->new(zoom_factor => 2, num_levels => 18 );
    my $eline   = $encoder->encode( \@points );
    is( $eline->{num_levels}, 18, 'RT 46337: num_levels' );
    is( $eline->{zoom_factor}, 2, 'RT 46337: zoom_factor' );
    is( $eline->{points}, 'qrueF`zojVYD}BSs@ALh@CZWb@oAbAiC^{AGgCBuBGAd@o@zB@jB[rAyA]sBeACGk@Be@KWM]Km@[WWa@g@o@_@_@K]SWi@o@g@uAbBSL}AiD]g@KEe@\\Ub@UHUEMUMCOLg@DMLINIf@A`BIr@_@vA}ARuB\\uAE_C^', 'RT 46337: points' );
    is( $eline->{levels}, 'PA@DB@DBD@@FAABFA@BA@?CA?A?@AAE@DA@F@@C@@CA@D@A@AE?ABP', 'RT 46337: levels' );

    my $d_points = $encoder->decode_points( $eline->{points} );
    my $d_levels = $encoder->decode_levels( $eline->{levels} );
    is( scalar @$d_points, scalar @$d_levels, 'decode: num levels == num points' );

    #is( $eline->{points}, 'qrueFdzojVYB}BSq@?Jd@CZUb@qAbAiC`@yAGgCBs@CaAEAf@o@|B@fB]tAyA[sBeACIk@Be@KUK]Mm@[YWa@g@o@a@_@I[SYi@o@e@sAbBUJ{AkD]e@MEc@^W^SLWEKYMAONi@BMNGJIh@C`BGr@_@xA}APwB\\sAGaC`@', 'RT 46337: points' );
    #is( $eline->{levels}, 'PA@D@CACD@@@FAAAFA@BB@@CA@A@@BAE@EA@F@@CA@C@@E@A@AE@AAP', 'RT 46337: levels' );

}

{
    # Test #2: compare against output from Google's Interactive Polyline Utility
    # (modified version, see t/js_reference/test.html)
    # encode _all_ points on the line by setting visible_threshold very low
    my $encoder = Geo::Google::PolylineEncoder->new(zoom_factor => 2, num_levels => 18, visible_threshold => 0.0000001 );
    my $eline   = $encoder->encode( \@points );
    is( $eline->{num_levels}, 18, 'RT 46337 all: num_levels' );
    is( $eline->{zoom_factor}, 2, 'RT 46337 all: zoom_factor' );
    is( $eline->{points}, 'qrueF`zojVYD}BSs@ALh@CZWb@oAbAiC^{AGgCBs@EaAAAd@o@zB@jB[rAyA]aAg@EAk@[CGk@Be@KWM]Km@[WWa@g@a@WMG_@K]SWi@WOWWuAbBSLq@yAk@oA]g@KEKFYTUb@UHUEMUMCOLUBQ@MLIN?FI^Af@?x@Ir@Qn@Mf@}ARuB\\uAE_C^', 'RT 46337 all: points' );

    # Note: levels were bootstrapped again, but verified with the Google IPU
    is( $eline->{levels}, 'PGGKHGJIKGGELGHHMHEEFIHFFJGFHCFFHGEKGKDHGMDGGJGGIGBGKFEHEGHDLEHHP', 'RT 46337 all: levels' );
    is( scalar @points, length( $eline->{levels} ), 'num points == num levels' );

    my $d_points = $encoder->decode_points( $eline->{points} );
    my $d_levels = $encoder->decode_levels( $eline->{levels} );
    is( scalar @$d_points, scalar @$d_levels, 'decode: num levels == num points' );
    is( scalar @$d_points, scalar @points, 'decode: num points == orig num points' );

  SKIP: {
	eval "use Test::Approx";
	skip 'Test::Approx not available', scalar( @points ) * 2 if $@;

	# compare the decoded & original points, should be only rounding diffs
	for my $i (0 .. $#points) {
	    my ($Pa, $Pb) = ($points[$i], $d_points->[$i]);
	    is_approx_num( $Pa->{lon}, $Pb->{lon}, "d.lon[$i] =~ o.lon[$i]", 1e-5 );
	    is_approx_num( $Pa->{lat}, $Pb->{lat}, "d.lat[$i] =~ o.lat[$i]", 1e-5 );
	}
    }


    # Finally, compare the points & levels to results from:
    # http://www.usnaviguide.com/google-encode.htm

    # with 0.001m tolerance:
    #'qrueFbzojVYD}BUq@?Jf@CZUb@qAbAiC^yAGgCDs@EaACAd@o@|B@hB]tAyA]_Ai@G?k@[CIk@De@KUM]Km@]YUa@i@a@UMI_@K[SYg@UQYUsAbBULq@yAi@qA]g@MEKFWVW`@SJWEKWMAOLW@QBMLGL?FI^Af@Ax@Gr@Qp@Mf@}APwB^sAGaC`@';
    #'PKJNJMKMNJJIPJKKPKHHJLLJIMKIKFIILJHOJOGKJPGJJMJJMJFJNIHKHJKGOIKKP';

    # with 0.01m tolerance:
    my $usng_points = $encoder->decode_points( 'qrueFbzojVYD}BUq@?Jf@CZUb@qAbAiC^yAGgCDs@EaACAd@o@|B@hB]tAyA]_Ai@G?k@[CIk@De@KUM]Km@]YUa@i@a@UMI_@K[SYg@UQYUsAbBULq@yAi@qA]g@MEKFWVW`@SJWEKWMAOLW@QBMLGL?FI^Af@Ax@Gr@Qp@Mf@}APwB^sAGaC`@' );
    my $usng_levels = $encoder->decode_levels( 'PGGKGIGJKGGELGHHMHEEFIHFFJGFHCFFHGEKGKDHGMDGGJGGIGCGKFEGDFHCKFHHP' );
    is( scalar @$usng_points, scalar @$usng_levels, 'decode usng: num levels == num points' );
    is( scalar @$usng_points, scalar @points, 'decode usng: num points == orig num points' );

  SKIP: {
	eval "use Test::Approx";
	skip 'Test::Approx not available', scalar( @points ) * 3 if $@;

	# compare the decoded & usng points & levels
	for my $i (0 .. $#points) {
	    my ($Pa, $Pb) = ($usng_points->[$i], $d_points->[$i]);
	    my ($La, $Lb) = ($usng_levels->[$i], $d_levels->[$i]);
	    # should be only rounding diffs for the points:
	    is_approx_num( $Pa->{lon}, $Pb->{lon}, "d.lon[$i] =~ usng.lon[$i]", 1.1e-5 );
	    is_approx_num( $Pa->{lat}, $Pb->{lat}, "d.lat[$i] =~ usng.lat[$i]", 1.1e-5 );
	    # be a bit more flexible with the levels:
	    is_approx_int( $La, $Lb, "d.level[$i] =~ usng.level[$i]", 3 );
	}
    }

    # with 0.1m tolerance:
    #'qrueFbzojVYD}BUq@?Jf@CZUb@qAbAiC^yAGgCDs@EaACAd@o@|B@hB]tAyA]_Ai@G?k@[CIk@De@KUM]Km@]YUa@i@a@UMI_@K[SYg@UQYUsAbBULq@yAi@qA]g@MEKFWVW`@SJWEKWMAOLW@QBMLGL?FI^Af@Ax@Gr@Qp@Mf@}APwB^sAGaC`@';
    #'PDCGDFDGGCCBIDEEIEBBCEECBGDBE@CCEDAHCHADCIACCFDDFD@DHCBDACD@HBDDP';

}

