use Test::Most;

use strict;
use warnings;

do 'xt/utility_funcs.pl' or die 'Could not open utility_funcs';

my $tests = 1;
plan tests => $tests;

#my $script = '4_finger_swipes_new';
#gets_output($script);

my $script = '4_finger_swipes_file_name';
gets_output($script);
