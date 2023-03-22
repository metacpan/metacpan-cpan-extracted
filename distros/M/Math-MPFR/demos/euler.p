#################################################################################
# This script requires Math::GMPq, Math::GMPz, and Math::MPFR.                  #
# It calculates the euler number e (2.7182818...), correct to $ARGV[0] bits.    #
# The calculated value is displayed unless $ARGV[1] is both provided and false. #
# With each iteration of the for{} loop (below) we get closer and closer to     #
# the actual value of e. Furthermore, with successive iterations of the for{}   #
# loop, the values alternate between "less than e" and "greater than e".        #
# Hence the actual (irrational) value of e is always between the values         #
# calculated by successive iterations of the for{} loop.                        #
#                                                                               #
# Of course, the simplest and most efficient way to get the value of e, to      #
# $ARGV[0] bits is simply to do:                                                #
#   Rmpfr_exp($rop, Math::MPFR->new(1), MPFR_RNDN)                              #
# where $rop is a $ARGV[0]-bit precision Math::MPFR object.                     #
# But doing it that way is a bit less interesting.                              #
#                                                                               #
# The same for{} loop can be also used to calculate the exact probabilities of  #
# "winning" at a simplistic solitaire-type card game. See demos/solitaire.p     #
# in the Math::GMPz source distro.                                              #
#################################################################################

use strict;
use warnings;
use Math::GMPz qw(:mpz);
use Math::GMPq qw(:mpq);
use Math::MPFR qw(:mpfr);

die "Usage: perl euler.pl bits [True|False]" unless @ARGV;
my $bits = shift;
Rmpfr_set_default_prec($bits);

my $display_value;
$display_value = defined($ARGV[0]) ? shift : 1;

#################################################################################
# For the sanity checks (below), set $e_big_p to e, correct to $bits+100 bits.  #
# Then convert $e_big_p exactly to a rational, $e_q (a Math::GMPq object).      #
#################################################################################
my $e_q = Math::GMPq->new();                                                    #
my $e_big_p = Rmpfr_init2($bits + 100);                                         #
Rmpfr_exp($e_big_p, Math::MPFR->new(1), MPFR_RNDN);                             #
Rmpfr_get_q($e_q, $e_big_p);                                                    #
#################################################################################

#################################################################
# Create some variables, and assign some initial values         #
#################################################################
my $first = Math::GMPz->new(1);                                 #
my $second = Math::GMPz->new(0);                                #
my $current_items = 2;                                          #
my $factorial = Math::GMPz->new(1);                             #
my $e_check = Math::GMPq->new();                                #
my ($e, $e_first_fr, $e_second_fr) = (Math::MPFR->new(),        #
                                      Math::MPFR->new(),        #
                                      Math::MPFR->new(),        #
                                     );                         #
my $chance; # becomes a MATH::GMPz object on assignment         #
my $e_first = Math::GMPq->new(3);                               #
my $e_second = Math::GMPq->new();                               #
my $count = 0;                                                  #
my $t = Math::GMPq->new();                                      #
my $save = Math::GMPq->new(4);                                  #
#################################################################

#################################################################
# Set $e to a $bits-bit approximation of the euler number,      #
# rounded to nearest.                                           #
# This should exactly equal the number that we calculate.       #
#################################################################
Rmpfr_exp($e, Math::MPFR->new(1), MPFR_RNDN);                   #
#################################################################

#########################
# Do the calculations	#
#########################

for(;;) {
  $count++;

  Rmpz_mul_ui($factorial, $factorial, $current_items);  #$factorial *= $current_items;
  $chance = ($current_items - 1) * ($first + $second);

#########################################################
# In this block we just perform some sanity checks.     #
# This block plays no part in the calculation of the    #
# actual value.                                         #
# Assign the calculated rational value to $e_check.     #
# Check that for every 2nd iteration, $e_check > $e_q   #
# and that for every other iteration, $e_check < $e_q   #
# Also check that, with each iteration, we get closer   #
# to the value of e (ie closer to the value of $e_q)    #
#########################################################
  Rmpq_set_num($e_check, $factorial);                   #
  Rmpq_set_den($e_check, $chance);                      #
  Rmpq_canonicalize($e_check); # gcd(num, den) == 1     #
  if($count % 2) {                                      #
    unless($e_check < $e_q) {die "$count: >="}          #
  }                                                     #
  else {                                                #
    unless($e_check > $e_q) {die "$count: <="}          #
  }                                                     #
  Rmpq_sub($t, $e_q, $e_check);                         #
  if(abs($t) < $save) {Rmpq_set($save, abs($t))}        #
  else {die "$count: No closer to e"}                   #
#########################################################

  Rmpq_set_num($e_second, $factorial);
  Rmpq_set_den($e_second, $chance);
  Rmpq_canonicalize($e_second); # gcd(num, den) == 1
  Rmpfr_set_q($e_first_fr, $e_first, MPFR_RNDN);
  Rmpfr_set_q($e_second_fr, $e_second, MPFR_RNDN);

#########################################################
# Exit the loop when $e_first_fr == $e_second_fr        #
# as this equivalence indicates that both variables     #
# contain the euler number, correct to $bits bits.      #
#########################################################
  last if Rmpfr_equal_p($e_first_fr, $e_second_fr);     #
#########################################################

  Rmpz_set($first, $second);
  Rmpz_set($second, $chance);
  Rmpq_set($e_first, $e_second);
  $current_items++;
}

if($e == $e_first_fr) {
  print "Iterations: $count ok\n";
  if($display_value) {print "$e_first_fr\n"}
}
else {print print "Iterations: $count not ok\n$e\n$e_first_fr\n"}

__END__

The sequence:
With 1st iteration, e = 2!  divided by 1       (ie divided by 1 * (1     + 0     ))
With 2nd iteration, e = 3!  divided by 2       (ie divided by 2 * (0     + 1     ))
With 3rd iteration, e = 4!  divided by 9       (ie divided by 3 * (1     + 2     ))
With 4th iteration, e = 5!  divided by 44      (ie divided by 4 * (2     + 9     ))
With 5th iteration, e = 6!  divided by 265     (ie divided by 5 * (9     + 44    ))
With 6th iteration, e = 7!  divided by 1854    (ie divided by 6 * (44    + 265   ))
With 7th iteration, e = 8!  divided by 14833   (ie divided by 7 * (265   + 1854  ))
With 8th iteration, e = 9!  divided by 133496  (ie divided by 8 * (1854  + 14833 ))
With 9th iteration, e = 10! divided by 1334961 (ie divided by 9 * (14833 + 133496))


