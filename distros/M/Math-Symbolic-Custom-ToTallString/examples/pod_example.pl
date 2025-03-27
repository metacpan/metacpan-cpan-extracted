use strict;
use Math::Symbolic 0.613 qw(:all);
use Math::Symbolic::Custom::ToTallString;

my $example1 = "x / 5";
print parse_from_string($example1)->to_tall_string(), "\n\n";

#  x 
# ---
#  5 

my $example2 = "(sin((1 / x) - (1 / y))) / (x + y)";
print parse_from_string($example2)->to_tall_string(), "\n\n";

#     ( 1     1 ) 
#  sin(--- - ---) 
#     ( x     y ) 
# ----------------
#      x + y      

my $example3 = "K + (K * ((1 - exp(-2 * K * t))/(1 + exp(-2 * K * t))) )";
print parse_from_string($example3)->to_tall_string(10), "\n\n";

#               (           (-2*K*t) )
#               (     1 - e^         )
#           K + (K * ----------------)
#               (           (-2*K*t) )
#               (     1 + e^         )

my $example4 = "((e^x) + (e^-x))/2";
print parse_from_string($example4)->to_tall_string(3), "\n\n";

#       x     -x 
#     e^  + e^   
#    ------------
#         2     


