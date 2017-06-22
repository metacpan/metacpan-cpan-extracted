use strict;
use warnings;

use Test::More;

use Finance::Contract;

my $params = {
    bet_type              => 'test',
    currency              => 'USD',
    supplied_barrier_type => 'relative',
    pip_size              => 0.001,
};

my $obj = new_ok('Finance::Contract', [$params]);
cmp_ok $obj->_barrier_for_shortcode_string('S20'), 'eq', 'S20', 'A relative barrier wont be changed if it is not a number';
cmp_ok $obj->_barrier_for_shortcode_string('20'),  'eq', '20',  'A relative barrier wont be changed if it is a number';

$params->{supplied_barrier_type} = 'absolute';
$obj = new_ok('Finance::Contract', [$params]);
cmp_ok $obj->_barrier_for_shortcode_string('20.20'), 'eq', '20',
    'An absolute barrier will be rounded to an interger if absolute_barrier_multiplier=0 ';
$params->{absolute_barrier_multiplier} = 1;
$obj = new_ok('Finance::Contract', [$params]);
cmp_ok $obj->_barrier_for_shortcode_string('0.12'), 'eq', '120000', 'A absolute barrier will be multiplied in 1e6 if absolute_barrier_multiplier=1';

$params->{bet_type} = 'DIGITMATCH';
$obj = new_ok('Finance::Contract', [$params]);
cmp_ok $obj->_barrier_for_shortcode_string('1'), 'eq', '1',
    'Even if absolute_barrier_multiplier is set there wont be any multiplication for ^DIGIT.*';

$params->{bet_type}              = 'test';
$params->{supplied_barrier_type} = 'difference';
$obj = new_ok('Finance::Contract', [$params]);
cmp_ok $obj->_barrier_for_shortcode_string('+0.12'), 'eq', 'S120P',  'A differnce barrier will manipulated to correct format depending on pipsize';
cmp_ok $obj->_barrier_for_shortcode_string('-0.12'), 'eq', 'S-120P', 'A differnce barrier will manipulated to correct format depending on pipsize';
cmp_ok $obj->_barrier_for_shortcode_string('-0'),    'eq', 'S0P',    'A differnce barrier that is -0 will be manipulated to correct format';
cmp_ok $obj->_barrier_for_shortcode_string('+0'),    'eq', 'S0P',    'A differnce barrier that is +0 will be  manipulated to correct format';
cmp_ok $obj->_barrier_for_shortcode_string('0'),     'eq', 'S0P',    'A differnce barrier that is  0 will be  manipulated to correct format';

done_testing;
