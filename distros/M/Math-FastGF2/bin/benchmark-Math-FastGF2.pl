#!/usr/bin/perl -w

use Math::FastGF2 ":all";

sub benchmark_ops {

  my $bufsize=8192;

  for my $op (qw(mul inv div pow)) {

    print "Benchmarking gf2_$op  ... \n";

    for my $bits (8, 16, 32) {

      my @b1=();			# buffers to fill with random values
      my @b2=();			#
      my $count=0;
      my $time_up=0;
      my $result;

      for (1..$bufsize) {
	push @b1,int rand 2**$bits;
	push @b2,int rand 2**$bits;
      }

      local $SIG{ALRM}=sub { $time_up=1; };
      alarm(10);

      until ($time_up) {
	if ($op eq "mul") {
	  for (0..$bufsize-1) {
	    $result=gf2_mul($bits,$b1[$_],$b2[$_]);
	  }
	  $count+=$bufsize;
	} elsif ($op eq "div") {
	  for (0..$bufsize-1) {
	    $result=gf2_div($bits,$b1[$_],$b2[$_]);
	  }
	  $count+=$bufsize;
	} elsif ($op eq "inv") {
	  for (0..$bufsize-1) {
	    $result=gf2_inv($bits,$b1[$_]);
	  }
	  $count+=$bufsize;
	} elsif ($op eq "pow") {
	  for (0..$bufsize-1) {
	    $result=gf2_pow($bits,$b1[$_],$b2[$_]);
	  }
	  $count+=$bufsize;
	}
      }
      printf "%-2d-bit: %f M{$op}/s\n", $bits, (($count /10.0 / 1024.0) / 1024.0);
    }
  }
}

print "Math::FastGF2 Benchmarks\n";
print "Library is using ", gf2_info(0), " bytes for table lookups\n";
print map {
            sprintf "$_-bit polynomial is {1%0*lx}\n", $_/4, gf2_info($_);
      } qw(8 16 32);
print "Benchmarking all operations on each word size.\n";
print "Each test takes 10 seconds; result is M{op}/s == 1048576 {operations}/second\n";

benchmark_ops;
