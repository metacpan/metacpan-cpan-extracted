#!perl -w
#______________________________________________________________________
# Convert miles per gallon to liters per 100 kilometers symbolically.
# Mike Schilli, m@perlmeister.com, 2004
#______________________________________________________________________

use Math::Algebra::Symbols;
use Test::Simple tests => 3;

#($gallons, $liters, $miles, $kilometers, $mileage, $consumption) =
#     symbols(qw(gallons liters miles kilometers mileage consumption));

#$liters     = $gallons / 3.7854;                    # 1: * not /
#$kilometers = 1.609 * $miles;

#$mileage = $miles/$gallons;
#$consumption = $liters / (100 * $kilometers);       # 2: Brackets, order give wrong precedence

#$mileage = 40;                                      # 3: Overwrites $miles/$gallon

#print $consumption, "\n";

#______________________________________________________________________
# Convert miles per gallon to liters per 100 kilometers symbolically.
# PhilipRBrenan@yahoo.com, 2004                                      
#______________________________________________________________________

($gallons, $miles) = symbols(qw(gallons miles));

$liters      = $gallons * 3.8;                       # 4: Have to use fraction, not decimal, improvement needed.
$kilometers  = $miles   * 1.6;                       # 5: Have to use fraction, not decimal, improvement needed.
$consumption = $liters / $kilometers * 100;          # 6: Correct precedence

print "Liters per 100 kilometers = $consumption\n";  # 7: As a general formula.

$miles       = 40;                                   # 8:  This expresses that the mileage is 40. Mike points out that 
$gallons     =  1;                                   # it would be more natural to express this as $miles/$gallons == 40,

print
  "$miles miles per $gallons gallon = ",
  eval "$consumption",                               # 9: Evaluate for a specific example
  " liters per 100 kilometers\n";

# Liters per 100 kilometers = 475/2*$gallons/$miles         # 10: The general formula
# 40 miles per 1 gallon = 5.9375 liters per 100 kilometers  # 11: A specific example

ok("$consumption" eq '475/2*$gallons/$miles');
ok(eval "$consumption" == 5.9375);

my ($gallons, $miles) = symbols(qw(gallons miles));
ok($gallons/$miles == 1/($miles/$gallons));          # 12: Check inverse of $miles/$gallon    
