#!/usr/bin/perl

use v5.26;
no feature 'indirect';
use warnings;

use Device::Chip::Si5351;
use Device::Chip::Adapter;

use Future::AsyncAwait;
use Future::IO;

use Getopt::Long;

use Data::Dump 'pp';

use List::UtilsBy qw( nsort_by );

use constant {
   PLL_VCO_MIN => 600E6,
   PLL_VCO_MAX => 900E6,
};

sub gcd
{
   my ( $x, $y ) = @_;
   # Good ol' Euclid
   ( $x, $y ) = ( $y, $x % $y ) while $y != 0;
   return $x;
}

GetOptions(
   'p|print-config' => \my $PRINT_CONFIG,

   'adapter|A=s' => \my $ADAPTER,

   'crystal|x=i'   => \(my $XTAL = 25E6),
) or exit 1;

my $target = @ARGV ? shift : 14.7456E6; # typical divider frequency for UART rates
$target =~ s/Hz$//i;
{
   use warnings FATAL => 'numeric';
   $target = $target * 1E6 if $target =~ s/M$//;
   $target = $target * 1E3 if $target =~ s/k$//;
   $target += 0;
}

sub calculate_config
{
   my ( $target ) = @_;

   # For targets under 500kHz, we must use the Rdiv output divider unit
   my $rdiv = 1;
   $rdiv *= 2, $target *= 2 while $rdiv < 128 and $target < 500000;

   # For a PLL somewhere in the range 600-900MHz, calculate the possible PLL
   # frequency and divisor ratios that would lead to it.

   # This is easiest if we start at the top and work down
   my $msdiv = int( PLL_VCO_MAX() / $target );
   # Ideally we want only even integers so we can run in integer mode
   $msdiv-- if $msdiv % 2;

   my @candidates;

   while(1) {
      my $vcofreq = $target * $msdiv;
      last if $vcofreq < PLL_VCO_MIN;
      next if $msdiv > 2048;

      my $pllnum = $vcofreq;
      my $plldiv = $XTAL;

      my $gcd = gcd( $pllnum, $plldiv );

      $pllnum /= $gcd;
      $plldiv /= $gcd;

      next if $plldiv >= 2**20;

      my $pllmult_c = $plldiv;
      my $pllmult_a = int( $pllnum / $plldiv );
      my $pllmult_b = $pllnum - $pllmult_a * $plldiv;

      my $pllmult = $pllmult_a + $pllmult_b / $pllmult_c;

      my $actual = $XTAL * $pllmult / $msdiv;

      my $err = $actual - $target;

      # Smaller PLL divider is better
      my $badness = $plldiv;

      push @candidates, {
         pllmult_a => $pllmult_a,
         pllmult_b => $pllmult_b,
         pllmult_c => $pllmult_c,
         pllmult   => $pllmult,
         msdiv     => $msdiv,
         rdiv      => $rdiv,
         actual    => $actual,
         err       => $err,
         badness   => $badness,
      };
   }
   continue {
      $msdiv -= 2;
   }

   # Sort candidates by how bad they are
   @candidates = nsort_by { $_->{badness} } @candidates;

   foreach my $candidate ( @candidates[0..4] ) {
      last if !defined $candidate;

      my $err_ppm = $candidate->{err}*1E6 / $target;

      printf "PLL at x%f x(%d + %5d/%5d), MS at /%d => %dHz (%+dHz, %+dppm)\n",
         @{$candidate}{qw( pllmult pllmult_a pllmult_b pllmult_c msdiv actual )}, $candidate->{err}, $candidate->{err}*1E6/$target;
   }
   printf "...\n" if @candidates > 5;

   # Select the best candidate
   return $candidates[0];
}

my $config = calculate_config( $target );

my $chip = Device::Chip::Si5351->new( fxtal => 25E6 );
await $chip->mount(
   Device::Chip::Adapter->new_from_description( $ADAPTER )
);

await $chip->protocol->power(0);
sleep 1;

await $chip->protocol->power(1);

$SIG{INT} = $SIG{TERM} = sub { exit 1; };

END {
   # $chip and $chip->protocol->power(0)->get;
}

# Await end of system init
my $count = 5;
while(1) {
   $count-- or die "Timeout awaiting !SYS_INIT\n";
   last if !( await $chip->read_status )->{SYS_INIT};
   await Future::IO->sleep( 0.1 );
}

await $chip->init;

await $chip->change_config(
   XTAL_CL => "10pF",
);

await $chip->change_pll_config( "A",
   ratio_a => $config->{pllmult_a},
   ratio_b => $config->{pllmult_b},
   ratio_c => $config->{pllmult_c},
);

await $chip->change_multisynth_config( 0,
   SRC   => "PLLA",
   ratio => $config->{msdiv},
);

await $chip->change_clk_config( 0,
   PDN => 0,
   SRC => "MSn",
   OE  => 1,
   DIV => $config->{rdiv},
);

await $chip->reset_plls;

print "Chip:\n", pp( await $chip->read_config() ), "\n";

print "PLL$_:\n", pp( await $chip->read_pll_config( $_ ) ), "\n" for qw( A );

print "MS$_:\n", pp( await $chip->read_multisynth_config( $_ ) ), "\n" for qw( 0 );

print "CLK$_:\n", pp( await $chip->read_clk_config( $_ ) ), "\n" for qw( 0 );

print "Status:\n", pp( await $chip->read_status ), "\n";
