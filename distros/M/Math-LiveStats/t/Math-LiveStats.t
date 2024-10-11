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
my @window_sizes = (5, 10); # , 60, 120);

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
    my ($timestamp, $value) = split(/\t/, $line);

    # Skip invalid lines
    next unless defined $timestamp && defined $value;

    # Convert timestamp and value to numbers
    $timestamp += 0;
    $value += 0;

    print "\nadding timestamp $timestamp, value $value:\n" if($debug);

    # Add data point to all objects
    $stats_all->add($timestamp, $value);
    $stats_recalc->add($timestamp, $value);
    foreach my $window (@window_sizes) {
        $stats_single{$window}->add($timestamp, $value);
    }



    # Check that stats match for each window size
    foreach my $window (@window_sizes) {

        # Call recalc() on the recalc object
        $stats_recalc->recalc($window);

        # From the main object
        my $mean_all = $stats_all->mean($window);
        my $stddev_all = $stats_all->stddev($window);
        my $n_all = $stats_all->n($window);

        # From the single-window-size object
        my $mean_single = $stats_single{$window}->mean($window);
        my $stddev_single = $stats_single{$window}->stddev($window);
        my $n_single = $stats_single{$window}->n($window);

        # From the recalc object
        my $mean_recalc = $stats_recalc->mean($window);
        my $stddev_recalc = $stats_recalc->stddev($window);
        my $n_recalc = $stats_recalc->n($window);

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
    }

    # Display stats from the main object
    foreach my $window (@window_sizes) {
        my $mean = $stats_all->mean($window);
        my $stddev = $stats_all->stddev($window);
        my $n = $stats_all->n($window);

        printf "Window %3d: n=%d, mean=%.4f, stddev=%.4f\n", $window, $n, $mean, $stddev if($debug);
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

__DATA__
27862371	2300.0
27862372	5750.0
27862373	24892.0
27862374	19729.0
27862375	23657.0
27862376	4483.0
27862377	12279.0
27862378	5400.0
27862379	66440.0
27862380	32733.0
27862389	0.0
27862394	0.0
27863430	19629.0
27863431	4500.0
