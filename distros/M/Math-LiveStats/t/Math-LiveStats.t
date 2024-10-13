# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl IO-Uncompress-Untar.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More;
BEGIN { use_ok('Math::LiveStats') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

#	
#	
#	my $d=new Math::LiveStats(10, 12, 23, 23, 16, 23, 21, 16);
#	
#	ok($d->mean()==18, "Mean OK");
#	ok((($d->variance()-4.89897948556636)**2<0.00000000001), "variance sensibleish");
#	ok((($d->variance()!=$d->sampleVariance)) , "sampleVariance sensibleish");
#	
#	my $d2=new Math::LiveStats(10, 12, 23, 23, 16, 23, 21);
#	$d2->Update(16);
#	
#	ok((($d2->mean()-18)**2<0.00000000001), "Mean 2 OK at:" . $d2->mean());
#	ok((($d2->variance()-4.89897948556636)**2<0.00000000001), "variance 2 sensibleish");
#	ok((($d2->variance()!=$d->sampleVariance)) , "sampleVariance 2 sensibleish");
#	
#	#warn $d2->mean();
#	#warn $d2->variance();
#	#warn $d2->sampleVariance();
#	#warn (($d2->variance()-4.89897948556636)**2);
#	
#	
#	done_testing();
#	
#	  # or
#	  #          use Test::More;   # see done_testing()
#	  #
#	  #                   require_ok( 'Some::Module' );
#	  #
#	  #                            # Various ways to say "ok"
#	  #                                     ok($got eq $expected, $test_name);
#	
#	
#	
#	



my $tolerance=2e-4;
my $debug=0;

# Create the window sizes
my @window_sizes = (5, 10, 20); # , 60, 120);

# Create the main object with all window sizes
my $stats_all = Math::LiveStats->new(@window_sizes);

# Create an identical object that we'll call recalc() on
my $stats_recalc = Math::LiveStats->new(@window_sizes);

# Create separate objects for each window size
my %stats_single;
foreach my $window (@window_sizes) {
    $stats_single{$window} = Math::LiveStats->new($window);
}

# Read input from STDIN
# while (my $line = <STDIN>) 
while (my $line = <DATA>) {

    chomp $line;
    my ($timestamp, $value, $volume, $tn20, $tm20, $ts20, undef, $tv20, $td20) = split(/\t/, $line); # cat  outpv | perl -ne '$z=",";BEGIN{use lib "./lib/";use Math::LiveStats;$s=Math::LiveStats->new(20);} chomp;($t,$p,$v)=split(/,/); $s->add($t,$p,$v); print "$t$z$p$z$v$z",$s->n(20),$z,$s->mean(20),$z,$s->stddev(20),$z,$z,join($z,$s->vwap(20)),$z,$s->vwapdev(20),"\n"' >yot5b.csv

    # Skip invalid lines
    next unless defined $timestamp && defined $value;

    # Convert timestamp and value to numbers
    $timestamp += 0;
    $value += 0;

    print "\nadding timestamp $timestamp, value $value:\n" if($debug);

    # Add data point to all objects
    $stats_all->add($timestamp, $value, $volume);
    $stats_recalc->add($timestamp, $value, $volume);
    foreach my $window (@window_sizes) {
        $stats_single{$window}->add($timestamp, $value, $volume);
    }



    # Check that stats match for each window size
    foreach my $window (@window_sizes) {

        # Call recalc() on the recalc object
        $stats_recalc->recalc($window);

        # From the main object
        my $mean_all = $stats_all->mean($window);
        my $stddev_all = $stats_all->stddev($window);
        my $n_all = $stats_all->n($window);
        my $vwap_all = $stats_all->vwap($window);
        my $vwapdev_all = $stats_all->vwapdev($window);

        # From the single-window-size object
        my $mean_single = $stats_single{$window}->mean($window);
        my $stddev_single = $stats_single{$window}->stddev($window);
        my $n_single = $stats_single{$window}->n($window);
        my $vwap_single = $stats_single{$window}->vwap($window);
        my $vwapdev_single = $stats_single{$window}->vwapdev($window);

        # From the recalc object
        my $mean_recalc = $stats_recalc->mean($window);
        my $stddev_recalc = $stats_recalc->stddev($window);
        my $n_recalc = $stats_recalc->n($window);
        my $vwap_recalc = $stats_recalc->vwap($window);
        my $vwapdev_recalc = $stats_recalc->vwapdev($window);

        # Compare stats between main and single-window-size objects
        if (abs($mean_all - $mean_single) > $tolerance) {
            &oops($stats_all, "Discrepancy in mean for window $window between main and single: all=$mean_all, single=$mean_single");
            &oops($stats_single{$window}, "(window $window)");
        } else {
          ok(1,"mean main==single");
        }

        if (abs($stddev_all - $stddev_single) > $tolerance) {
            &oops($stats_all, "Discrepancy in stddev for window $window between main and single: all=$stddev_all, single=$stddev_single");
            &oops($stats_single{$window}, "(window $window)");
        } else {
          ok(1,"stddev main==single");
        }
        if ($n_all != $n_single) {
            &oops($stats_all, "Discrepancy in n for window $window between main and single: all=$n_all, single=$n_single");
            &oops($stats_single{$window}, "(window $window)");
        } else {
          ok(1,"n main==single");
        }
        if (abs($vwap_all - $vwap_single) > $tolerance) {
            &oops($stats_all, "Discrepancy in vwap for window $window between main and single: all=$vwap_all, single=$vwap_single");
            &oops($stats_single{$window}, "(window $window)");
        } else {
          ok(1,"vwap main==single");
        }
        if (abs($vwapdev_all - $vwapdev_single) > $tolerance) {
            &oops($stats_all, "Discrepancy in vwapdev for window $window between main and single: all=$vwapdev_all, single=$vwapdev_single");
            &oops($stats_single{$window}, "(window $window)");
        } else {
          ok(1,"vwapdev main==single");
        }

        # Compare stats between main and recalc objects
        if (abs($mean_all - $mean_recalc) > $tolerance) {
            &oops($stats_recalc, "Discrepancy in mean for window $window between main and recalc: all=$mean_all, recalc=$mean_recalc");
            &oops($stats_all, "(window all)");
        } else {
          ok(1,"mean main==recalc");
        }
        if (abs($stddev_all - $stddev_recalc) > $tolerance) {
            &oops($stats_recalc, "Discrepancy in stddev for window $window between main and recalc: all=$stddev_all, recalc=$stddev_recalc");
            &oops($stats_all, "(window all)");
        } else {
          ok(1,"stddev main==recalc");
        }
        if ($n_all != $n_recalc) {
            &oops($stats_recalc, "Discrepancy in n for window $window between main and recalc: all=$n_all, recalc=$n_recalc");
            &oops($stats_all, "(window all)");
        } else {
          ok(1,"n main==recalc");
        }
        if (abs($vwap_all - $vwap_recalc) > $tolerance) {
            &oops($stats_recalc, "Discrepancy in vwap for window $window between main and recalc: all=$vwap_all, recalc=$vwap_recalc");
            &oops($stats_all, "(window all)");
        } else {
          ok(1,"vwap main==recalc");
        }
        if (abs($vwapdev_all - $vwapdev_recalc) > $tolerance) {
            &oops($stats_recalc, "Discrepancy in vwapdev for window $window between main and recalc: all=$vwapdev_all, recalc=$vwapdev_recalc");
            &oops($stats_all, "(window all)");
        } else {
          ok(1,"vwapdev main==recalc");
        }
    }
    foreach my $window (20) { # check the answers are correct

        my $mean_all = $stats_all->mean($window);
        my $stddev_all = $stats_all->stddev($window);
        my $n_all = $stats_all->n($window);
        my $vwap_all = $stats_all->vwap($window);
        my $vwapdev_all = $stats_all->vwapdev($window);


($timestamp, $value, $volume, $tn20, $tm20, $ts20, undef, $tv20, $td20) = split(/\t/, $line); # cat  outpv | perl -ne '$z=",";BEGIN{use lib "./lib/";use Math::LiveStats;$s=Math::LiveStats->new(20);} chomp;($t,$p,$v)=split(/,/); $s->add($t,$p,$v); print "$t$z$p$z$v$z",$s->n(20),$z,$s->mean(20),$z,$s->stddev(20),$z,$z,join($z,$s->vwap(20)),$z,$s->vwapdev(20),"\n"' >yot5b.  csv

        if (abs($mean_all - $tm20) > $tolerance) {
            &oops($stats_all, "Discrepancy in mean for window $window between main and expected output: all=$mean_all, expected=$tm20");
        } else {
          ok(1,"mean main==expected");
        }      
        if (abs($stddev_all - $ts20) > $tolerance) {
            &oops($stats_all, "Discrepancy in stddev for window $window between main and expected output: all=$stddev_all, expected=$tm20");
        } else {
          ok(1,"stddev main==expected");
        }      
        if (abs($n_all - $tn20) > $tolerance) {
            &oops($stats_all, "Discrepancy in n for window $window between main and expected output: all=$n_all, expected=$tm20");
        } else {
          ok(1,"n main==expected");
        }      
        if (abs($vwap_all - $tv20) > $tolerance) {
            &oops($stats_all, "Discrepancy in vwap for window $window between main and expected output: all=$vwap_all, expected=$tm20");
        } else {
          ok(1,"vwap main==expected");
        }      
        if (abs($vwapdev_all - $td20) > $tolerance) {
            &oops($stats_all, "Discrepancy in vwapdev for window $window between main and expected output: all=$vwapdev_all, expected=$tm20");
        } else {
          ok(1,"vwapdev main==expected");
        }      

    }

    # Display stats from the main object
    foreach my $window (@window_sizes) {
        my $mean = $stats_all->mean($window);
        my $stddev = $stats_all->stddev($window);
        my $n = $stats_all->n($window);
        my $vwap = $stats_all->vwap($window);
        my $vwapdev = $stats_all->vwapdev($window);

        printf "Window %3d: n=%d, mean=%.4f, stddev=%.4f vwap_mean=%.4f vwap_stddev=%.4f\n", $window, $n, $mean, $stddev, $vwap, $vwapdev if($debug);
    }
    print "\n" if($debug);
}

done_testing();

sub oops {
  my($self,$msg)=@_;
  print($msg,"\n");
  ok(0,$msg);
  foreach my $window (@{ $self->{window_sizes} }) {
    my $stats=$self->{stats}{$window};
    print "size=$window: n=$stats->{n} mean=$stats->{mean} M2=$stats->{M2} start_index=$stats->{start_index} d=[";
    if($stats->{synthetic}) {
      print("s(",$stats->{synthetic}->{timestamp},",",$stats->{synthetic}->{value},"), ");
    }
    for(my $i=$stats->{start_index}; $i<=$#{$self->{data}};$i++) {
    #for(my $i=$stats->{start_index}; $i < @{$self->{data}}; $i++) {
      print "(", $self->{data}[$i]{timestamp}, ",", $self->{data}[$i]{value},")";
      print ", " unless($i==$#{$self->{data}});
    }
    print "]\n";
  } # window
} # oops

# cat  outpv | perl -ne '$z=",";BEGIN{use lib "./lib/";use Math::LiveStats;$s=Math::LiveStats->new(20);} chomp;($t,$p,$v)=split(/,/); $s->add($t,$p,$v); print "$t$z$p$z$v$z",$s->n(20),$z,$s->mean(20),$z,$s->stddev(20),$z,$z,join($z,$s->vwap(20)),$z,$s->vwapdev(20),"\n"' > test_results.csv
__DATA__
27862368,9.975,2243.0,21,9.98427619047624,0.00825535612540758,,9.98848849173815,0.00887767427999851
27862369,9.975,600.0,21,9.98308571428576,0.0076552782908141,,9.98521891153458,0.0073315173645203
27862370,9.995,33110.0,21,9.98308571428576,0.0076552782908141,,9.98703307069604,0.00763117723290972
27862371,9.995,2300.0,21,9.98356190476195,0.00807957153479995,,9.98726020241209,0.00779144038238056
27862372,9.995,5750.0,21,9.98332380952386,0.00763222803363483,,9.98752307286358,0.00775692123821771
27862373,9.985,24892.0,21,9.98261428571433,0.00664261136224704,,9.98602506241233,0.00639958535504517
27862374,9.995,19729.0,21,9.98309047619053,0.00716044026282067,,9.98710162993314,0.00673113345333177
27862375,9.995,23657.0,21,9.98356666666672,0.00761205184748508,,9.98812932813796,0.00686239554693325
27862376,9.995,4483.0,21,9.98404285714291,0.00800865603106967,,9.9883275512399,0.00689148717032229
27862377,9.995,12279.0,21,9.98475714285719,0.00829388759412097,,9.98873565250837,0.00686552155655766
27862378,10.0,5400.0,21,9.98570952380957,0.00884996637039639,,9.98921150600345,0.00695886403974848
27862379,10.01,66440.0,21,9.987380952381,0.00995226703031466,,9.99434449018578,0.0107818846307271
27862380,10.01,32733.0,21,9.98857142857148,0.0110840941376411,,9.99651275294929,0.0112837362600946
27862389,10.01,0.0,13,9.99653846153854,0.00987096233536193,,10.0004184152862,0.00891410530775478
27862394,10.01,0.0,9,10.0022222222223,0.00754615428071309,,10.0041949113957,0.00719292291867902
27863430,9.96,19629.0,2,9.96048262548314,0.000682535502353064,,9.96047792153066,0.000482602626747786
27863431,9.97,4500.0,3,9.96363899613934,0.00552783814210206,,9.96144406298061,0.00294230734033374
27863432,9.98,10386.0,4,9.96771718146744,0.00935476929039476,,9.96500857142494,0.00779510761935744
27863433,9.975,1600.0,5,9.9691640926643,0.00874314285970774,,9.96527879037163,0.00787042378875424
27863434,9.92,5821.0,6,9.96096203346221,0.0215408599816176,,9.96095987039905,0.0152424365804563
27863435,9.93,2400.0,7,9.956531991175,0.0228813406151535,,9.95977833878799,0.0160698869380292
27863436,9.93,2851.0,8,9.95320945945959,0.0231657536986052,,9.95848887653548,0.0168346184636116
27863437,9.91,2200.0,9,9.94840304590316,0.0260167963734844,,9.95692467647777,0.0186271749802389
27863438,9.93,2443.0,10,9.94655791505802,0.0252067868716147,,9.95598909217277,0.018943968002122
27863439,9.91,4901.0,11,9.94323008073018,0.0263282162833348,,9.95301813807877,0.0215144670597494
27863440,9.91,2000.0,12,9.94045688545697,0.0268701135343773,,9.95190733413433,0.0222904522031031
27863441,9.9,8598.0,13,9.93734110484118,0.0280634055659717,,9.94675594696807,0.0262251047359449
27863442,9.9,4440.0,14,9.93467043574194,0.0287468172371543,,9.9444733668931,0.0274785394630092
27863443,9.91,1300.0,15,9.93302252252259,0.0284207541982262,,9.94398231042574,0.0275769681718047
27863444,9.9,800.0,16,9.93095559845566,0.0286680399013138,,9.94359875758539,0.0277483257032562
