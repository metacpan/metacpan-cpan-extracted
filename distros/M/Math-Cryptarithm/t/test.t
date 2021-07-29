# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Math-Cryptarithm.t'

#########################

use strict;
use warnings;

use Test::More tests => 10;
use Test::Deep;
BEGIN { use_ok('Math::Cryptarithm') };

#########################

# Total Running Time within 1 min (LinuxMint version 20.1, Perl v5.34.0)

my $ex04_lungty = ["A+B+B=AB"];
my $ex52_lungty = ["ABCAB*A=DDDDDD"];
my $first_property_two_and_four = [ "A**B = B**A" ];
my $second_property_two_and_four = [ "A+A = A*A" ];
my $use_of_property_of_nine = [ "A * D = BC", "B + C = 9", "A % 4 = 0" ];
my $pythagorean_triple1 = [ "A * A + B * B = C * C" ];
my $pythagorean_triple2 = [ "A * A + BC * BC = 169" ];
my $symmetry = [ "AAAAA * AAAAA  = ABCDEDCBA" ];
my $de_wikipedia = ["EINS + NEUN = ZEHN"];

cmp_deeply(
  Math::Cryptarithm->new($ex04_lungty)->solve_ans_in_equations(),
  [ [ "1+9+9=19" ] ],
  "Exercise 04 from Lung's article"
);


cmp_deeply(
  Math::Cryptarithm->new($ex52_lungty)->solve_ans_in_equations(),
  [ [ "37037*3=111111" ] ],
  "Exercise 52 from Lung's article"
);

cmp_set(
  Math::Cryptarithm->new($first_property_two_and_four)->solve(),
  [ { "A"=>2, "B"=>4 }, { "A"=>4, "B"=>2 } ],
  "Well-known property of 2 and 4"
);

cmp_set(
  Math::Cryptarithm->new($second_property_two_and_four)->solve(),
  [ {"A"=>2}, {"A"=>0} ],
  "Well-known property of 0, 2 and 4"
);

cmp_set(
  Math::Cryptarithm->new($use_of_property_of_nine)->solve(),
  [
    {"A" => 4, "B" => 3, "C" => 6, "D" => 9},
    {"A" => 8, "B" => 7, "C" => 2, "D" => 9}
  ],
  "Made use of well-known property of 9's multiples"
);


cmp_set(
  Math::Cryptarithm->new($pythagorean_triple1)->solve(),
  [
    {"A" => 3, "B" => 4, "C" => 5},
    {"A" => 4, "B" => 3, "C" => 5}
  ],
  "Pythagorean triple I"
);

cmp_set(
  Math::Cryptarithm->new($pythagorean_triple2)->solve(),
  [
    {"A" => 5, "B" => 1, "C" => 2 },
    {"A" => 0, "B" => 1, "C" => 3 }
  ],
  "Pythagorean triple II"
);


cmp_set(
  Math::Cryptarithm->new($symmetry)->solve(),
  [
    {"A" => 1, "B" => 2, "C" => 3, "D" => 4, "E" => 5}
  ],
  "11..11 ** 2 = 123..321"
);


cmp_set(
  Math::Cryptarithm->new($de_wikipedia)->solve_ans_in_equations(),
  [ 
    [ "2930 + 3283 = 6213"],
    [ "3940 + 4374 = 8314"],
    [ "1940 + 4184 = 6124"],
    [ "2950 + 5265 = 8215"],
    [ "1950 + 5185 = 7135"],
    [ "1960 + 6176 = 8136"],
  ],
  "From German Wikipedia and geogebra.org"
);  


# Mr T. Y. Lung's Article
# https://web.archive.org/web/20041207143645/
#    http://www.fed.cuhk.edu.hk/~fllee/mathfor/edumath/9612/12lungty.html

# geogebra.org applet for the test case "eins + neun = zehn"
# https://www.geogebra.org/m/dnnwbjad
