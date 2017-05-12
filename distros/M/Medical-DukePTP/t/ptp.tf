

use strict;
use warnings;

use Test::More tests=> 14;

use_ok('Medical::DukePTP');

my $raah_tests = [
 [ { 'age' => 80, 'sex' => 'male' }, 84, 'male 84 yrs old no risk factors' ],
 [ { 'age' => 80, 'sex' => 'female' }, 25, 'female 84 yrs old no risk factors' ],
 [ { 'age' => 84, 'sex' => 'female', 'smoking' => 1 }, 26, 'female 84 yrs old, smoker' ],
 [ { 'age' => 84, 'sex' => 'female', 'smoking' => 1, 'chest_pain' => 'typical'  }, 83, 'female 84 yrs old, smoker, typical angina' ],
 [ { 'age' => 84, 'sex' => 'male', 'smoking' => 1, 'chest_pain' => 'typical'  }, 98, 'male 84 yrs old, smoker, typical angina' ],
 [ { 'age' => 50, 'sex' => 'male', 'smoking' => 1, 'diabetes' => 1, }, 38, 'male 50yrs old smoking diabetes' ], 
 [ { 'age' => 50, 'sex' => 'female', 'smoking' => 1, 'diabetes' => 1, }, 15, 'female 50yrs old smoking diabetes' ],
 [ { 'age' => 50, 'sex' => 'female', 'previous_MI' => 1, 'diabetes' => 1 }, 14, 'female 50yrs old previous MI diabetes' ],
 [ { 'age' => 90, 'sex' => 'female', 'hyperlipidemia' => 1, }, 33, 'female 90 yrs old hyperlipidemia' ], 
 [ { 'age' => 90, 'sex' => 'male', 'chest_pain' => 'typical', 'smoking' => 1, 'hyperlipidemia' => 1, 'previous_MI' => 1, 'diabetes' => 1, 'ECG_Q_wave' => 1, 'ECG_ST-T_wave' =>1,}, 100, '90yr old male all risk factors combined' ],
 [ { 'age' => 50, 'sex' => 'male', 'chest_pain' => 'atypical', 'diabetes' => 1, 'ECG_Q_wave' => 1, }, 76, '50 yr old male diabetes ECQ Q waves' ],
 [ { 'age' => 1 }, undef, 'missing params' ],
 [ { 'sex' => male }, undef, 'missing params' ], 
];

foreach my $ra ( @$raah_tests ) { 
  is( Medical::DukePTP::ptp( $ra->[0] ), $ra->[1], $ra->[2] );
}


1;
