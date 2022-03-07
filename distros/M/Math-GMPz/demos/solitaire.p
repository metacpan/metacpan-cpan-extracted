#################################################################################
# This script requires Math::GMPq and Math::GMPz.				#
# It calculates the chance of winning at a simplistic form of solitaire.	#
# The game is as follows:							#
#										#
# Take (say) 4 cards, numbered 1 to 4, shuffle them, and deal them out one	#
# at a time. You lose the game if the first card dealt out is the "1", or	#
# the second card dealt out is the "2", or the third card dealt out is the	#
# "3" or the fourth card dealt out is the "4". Otherwise you win.		#
#										#
# What are the chances of winning ?						#
# How do those chances change if you have 10 cards numbered 1 to 10, and 	#
# you deal them all out one at a time, applying the same rules ? ... what if	#
# you were to play that game with a thousand cards numbered 1 to 1000 ?		#
#										#
# The below script calculates those chances for you. You just run:		#
# perl solitaire.pl X - where X is the number of cards you're playing with.	#
# If you want to see the probabilities for all numbers of cards up to and	#
# including X, just run: perl solitaire.pl X all				#
# NOTE: X must be greater than 1.						#
# 										#
# Turns out that the probability of winning doesn't change much as the number	#
# of cards is increased beyond about 5. As the number of cards increases, the	#
# probability of "winning" gets closer and closer to 1 in e, where e is the	#
# euler number (2.71828...)							#
# With each iteration of the for{} loop (below) we get closer and closer to	#
# the actual value of e. Furthermore, with successive iterations of the for{} 	#
# loop, the values alternate between "less than e" and "greater than e".	#
# Hence, to maximize your chances of "winning", always play with an even	#
# number of cards. With an even number of cards, your chances of winning are	#
# always better than 1 in e, whereas with an odd number of cards your chances	#
# are always less than 1 in e. (Of course, the difference is quite miniscule.)	#
#										#
# The same for{} loop can be also used to calculate the euler number to a   	#
# specified precision. See demos/euler.p in the Math::MPFR source distro.	#
#										#
# When played with a full deck of 52 standard playing cards, the game is known	#
# as "frustration solitaire".							#
# But that's a bit different to the exercise described above, because the	#
# standard deck of playing cards contains 4 cards for each of the 13 values.	#
#################################################################################

use strict;
use warnings;
use Math::GMPz qw(:mpz);
use Math::GMPq qw(:mpq);


die "Usage: perl solitaire.pl cards [all]" unless @ARGV;
die "\$ARGV[0] must be greater than 1" unless $ARGV[0] > 1;
my $its = shift;
$its--;

my $display_value;
$display_value = $ARGV[0] ? shift : 0;
$display_value = 0 unless lc($display_value) eq 'all';


#################################################################
# Create some variables, and assign some initial values		#
#################################################################
my $first = Math::GMPz->new(1);					#
my $second = Math::GMPz->new(0);				#
my $current_items = 2;						#
my $factorial = Math::GMPz->new(1);				#
my $chance; # becomes a MATH::GMPz object on assignment 	#
my $e_q = Math::GMPq->new();					#
my $count = 1;							#
my $t = Math::GMPq->new();					#
#################################################################

#########################
# Do the calculations	#
#########################

for(1 .. $its) {
  $count++;

  Rmpz_mul_ui($factorial, $factorial, $current_items);  #$factorial *= $current_items;
  $chance = ($current_items - 1) * ($first + $second);

  Rmpq_set_num($e_q, $factorial);
  Rmpq_set_den($e_q, $chance);
  Rmpq_canonicalize($e_q); # gcd(num, den) == 1

  if($display_value && $_ < $its) {
    Rmpq_inv($t, $e_q);
    print "With $count cards, chance of winning is ",Rmpq_get_d($t), "\n$chance / $factorial\n\n";
  }

  Rmpz_set($first, $second);
  Rmpz_set($second, $chance);
  $current_items++;
}

Rmpq_inv($e_q, $e_q);
print "With $count cards, chance of winning is ",sprintf(" %.16e ",Rmpq_get_d($e_q)), "\n$chance / $factorial\n";

__END__

The sequence is:
With 2  cards, chance of success is 1       (ie (2  - 1) * (1     + 0     )) in 2!
With 3  cards, chance of success is 2       (ie (3  - 1) * (0     + 1     )) in 3!
With 4  cards, chance of success is 9       (ie (4  - 1) * (1     + 2     )) in 4!
With 5  cards, chance of success is 44      (ie (5  - 1) * (2     + 9     )) in 5!
With 6  cards, chance of success is 265     (ie (6  - 1) * (9     + 44    )) in 6!
With 7  cards, chance of success is 1854    (ie (7  - 1) * (44    + 265   )) in 7!
With 8  cards, chance of success is 14833   (ie (8  - 1) * (265   + 1854  )) in 8!
With 9  cards, chance of success is 133496  (ie (9  - 1) * (1854  + 14833 )) in 9!
With 10 cards, chance of success is 1334961 (ie (10 - 1) * (14833 + 133496)) in 10!
and so on ...

There's a well known "derangement problem", which asks for the number D(n) of permutations
of an n-element set such that no member of the set is left in it's original position.
The above sequence gives us the values of D(2) = 1, D(3) = 2, D(4) = 9, D(5) = 44, D(6) = 265,
D(7) = 1854, D(8) = 14833, D(9) = 133496, D(10) = 1334961, ....

That is:
with a pack of 2  cards, there is  1       way  to rearrange the order so that no cards are in their original position
with a pack of 3  cards, there are 2       ways to rearrange the order so that no cards are in their original position
with a pack of 4  cards, there are 9       ways to rearrange the order so that no cards are in their original position
with a pack of 5  cards, there are 44      ways to rearrange the order so that no cards are in their original position
with a pack of 6  cards, there are 265     ways to rearrange the order so that no cards are in their original position
with a pack of 7  cards, there are 1854    ways to rearrange the order so that no cards are in their original position
with a pack of 8  cards, there are 14833   ways to rearrange the order so that no cards are in their original position
with a pack of 9  cards, there are 133496  ways to rearrange the order so that no cards are in their original position
with a pack of 10 cards, there are 1334961 ways to rearrange the order so that no cards are in their original position
and so on ...



