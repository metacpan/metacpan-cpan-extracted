#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Test::Exception;

use_ok( 'Games::Dice::Roller' ); 
diag( "Testing the _validate_expr private subroutine" );

# NB: many of the following tests does NOT dies inside _validate_expr but elsewhere.
# Add $@ at the end of the string to see where the error message comes from

# avg
dies_ok { Games::Dice::Roller::_identify_type('2d4avgkh') } "expected to die if avg has also a result modification k or d";
dies_ok { Games::Dice::Roller::_identify_type('2d4avglt') } "expected to die if avg has also lt or gt";
dies_ok { Games::Dice::Roller::_identify_type('2d4avg3') } "expected to die if avg has also a modification value";

# cs
dies_ok { Games::Dice::Roller::_identify_type('2d4cs2kh') } "expected to die if cs has also a result modification k or d";
dies_ok { Games::Dice::Roller::_identify_type('2d4cs') } "expected to die if cs is not followed by a number";
dies_ok { Games::Dice::Roller::_identify_type('2d4cs2+33') } "expected to die if cs has a summation";

# x
# might be ok?
#dies_ok { Games::Dice::Roller::_validate_expr('3d8x8kl') } "expected to die if x has also a result modification k or d";
dies_ok { Games::Dice::Roller::_identify_type('3d8x') } "expected to die if x is not followed by a number";

# lt and gt
dies_ok { Games::Dice::Roller::_identify_type('3d8lt3') } "expected to die if gt|lt are not used exclusively with r x and cs";

# kh|kl|dh|dl
dies_ok { Games::Dice::Roller::_identify_type('3d8kl') } "expected to die if kh|kl|dh|dl is not followed by a number";
dies_ok { Games::Dice::Roller::_identify_type('3d8kl2x') } "expected to die if kh|kl|dh|dl is used with x, r, avg or cs";
dies_ok { Games::Dice::Roller::_identify_type('3d8kl2cslt2') } "expected to die if kh|kl|dh|dl is used with lt or gt";

# +3 -3
dies_ok { Games::Dice::Roller::_identify_type('3d8cs+3') } "expected to die if a summation is used within cs";

done_testing;