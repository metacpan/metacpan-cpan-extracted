use Test::Most;

use strict;
use warnings;

do 'xt/utility_funcs.pl' or die 'Could not open utility_funcs';

my $tests = 1;
plan tests => $tests;

#my $script = '4_finger_swipes_new';
#gets_output($script);

my $script = 'key_code_with_number';
gets_output($script);
