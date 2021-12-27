
# Provide timings of 1_040_000 random values for:
# 1) Math::Ryu::d2s();
# 2) perl's sprintf();
# and, if a sufficiently recent version of Math::MPFR loads:
# 3) Math::MPFR::doubletoa(); # grisu3, falling back to nvtoa as needed
# 4) Math::MPFR::nvtoa().

use warnings;

use Math::Ryu qw(:all);
use Benchmark;

my $have_mpfr = 1; # optimistic

eval {require Math::MPFR;};

if($@) {
  $have_mpfr = 0;
  warn "Could not load Math::MPFR\n";
}
elsif($Math::MPFR::VERSION < 4.12) { # doubletoa() added to Math::MPFR in 4.12
  $have_mpfr = 0;
  warn "Need at least Math-MPFR-4.12, have Math-MPFR-$Math::MPFR::VERSION\n";
}
elsif(Math::MPFR::MPFR_VERSION() <= 196869) {
  $have_mpfr = 0;
  warn "mpfr-3.1.6 needed for mpfr benchmarking, have mpfr-", Math::MPFR::MPFR_VERSION_STRING(), "\n";
}

my $first = -324;

if($have_mpfr && $Math::MPFR::VERSION < 4.19) {
  warn "Avoiding -0 as doubletoa() does not handle it correctly until Math-MPFR-4.19\n";
  $first = -322;
}

our @nvs = ();
$count = 0;

for my $exp ($first .. -290, -200 .. -180, -50 .. 50, 200 .. 250) {
  for(1 .. 5000) {
    $count ++;
    my $str = (5 + int(rand(5))) . "." . random_digits() . "e$exp";
    my $nv = $str + 0;

    $nv = -$nv unless $count % 5;
    $nv /= 10 unless $count % 3;

    push @nvs, $nv;
  }
}

#print scalar @nvs, "\n";

timethese(1, {
  'd2s'     => 'for(@nvs) { $s = d2s($_); }',
  'sprintf' => 'for(@nvs) { $s = sprintf("%.17g", $_); }',
});


if($have_mpfr) {

  timethese(1, {
    'doubletoa' => 'for(@nvs) { $s = Math::MPFR::doubletoa($_); }',
    'nvtoa' => 'for(@nvs) { $s = Math::MPFR::nvtoa($_); }',
  });

}
else {
  warn "Skipping Math-MPFR benchmarking\n";
}

sub random_digits {
  my $ret = '';
  $ret .= int(rand(10)) for 1 .. 6;
  return $ret;
}

__END__

For me, on Windows 7, outputs:

Benchmark: timing 1 iterations of d2s, sprintf...
       d2s:  0 wallclock secs ( 0.38 usr +  0.00 sys =  0.38 CPU) @  2.67/s (n=1)
            (warning: too few iterations for a reliable count)
   sprintf:  3 wallclock secs ( 2.96 usr +  0.00 sys =  2.96 CPU) @  0.34/s (n=1)
            (warning: too few iterations for a reliable count)
Benchmark: timing 1 iterations of doubletoa, nvtoa...
 doubletoa:  1 wallclock secs ( 0.48 usr +  0.00 sys =  0.48 CPU) @  2.07/s (n=1)
            (warning: too few iterations for a reliable count)
     nvtoa:  3 wallclock secs ( 3.38 usr +  0.00 sys =  3.38 CPU) @  0.30/s (n=1)
            (warning: too few iterations for a reliable count)

