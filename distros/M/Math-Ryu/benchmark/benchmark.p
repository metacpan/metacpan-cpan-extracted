# Timings for ryu (both reformatted and not reformatted),
# perl's sprintf() and, if available, Math::MPFR's nvtoa().
# Note that Math::Ryu::nv2s() and Math::MPFR::nvtoa() should
# return identical strings for the same input argument.

use warnings;
use Benchmark;

use Math::Ryu qw(:all);

$mpfr = 1;
eval{require Math::MPFR;};

if($@) { $mpfr = 0 }
elsif($Math::MPFR::VERSION < 4.14) { $mpfr = 0 }
elsif(Math::MPFR::MPFR_VERSION_MAJOR() < 3 ||
     (Math::MPFR::MPFR_VERSION_MAJOR() == 3  &&
     Math::MPFR::MPFR_VERSION_PATCHLEVEL() < 6)) { $mpfr = 0 }

if   (Math::Ryu::MAX_DEC_DIG == 17) { *NVtos =\&d2s  }
elsif(Math::Ryu::MAX_DEC_DIG == 21) { *NVtos =\&ld2s }
elsif(Math::Ryu::MAX_DEC_DIG == 36) { *NVtos =\&q2s  }
else                                { die "Something seriously wrong here" }

my $fmt = Math::Ryu::MAX_DEC_DIG;

@nums = ();

for(1..100000) {
   my $exp = 1 + int rand 10;
   my $num = rand();
   $num .= "e+$exp" unless $num =~ /e/i;
   $num += 0;
   push @nums, $num;
}
for(1..100000) {
   my $exp = 1 + int rand 300;
   my $num = rand();
   $num .= "e+$exp" unless $num =~ /e/i;
   $num += 0;
   push @nums, $num;
}
for(1..100000) {
   my $exp = 1 + int rand 10;
   my $num = rand();
   $num .= "e-$exp" unless $num =~ /e/i;
   $num += 0;
   push @nums, $num;
}
for(1..100000) {
   my $exp = 1 + int rand 300;
   my $num = rand();
   $num .= "e-$exp" unless $num =~ /e/i;
   $num += 0;
   push @nums, $num;
}


print "sprintf() performs \"%.${fmt}g\" formatting of the given values.\n";
timethese (1, {
 'ryu_fmt'    => '$r = nv2s ($_) for @nums;',
 'ryu_unfmt'  => '$r = NVtos($_) for @nums;',
 'sprintf'    => '$r = sprintf("%.${fmt}g", $_) for @nums;',
});

if($mpfr) {
  timethese (1, {
   'mpfr_fmt' => '$r = Math::MPFR::nvtoa($_) for @nums;',
  });
}
