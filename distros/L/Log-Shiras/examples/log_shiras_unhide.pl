#!perl
# Note this example uses the demonstration package Level1.pm Level2.pm, and Level3.pm
use	lib	'../lib',;
use Log::Shiras::Unhide qw( :debug  :Meditation  :Health :Family );#
my	$basic = 'Nothing';
###LogSD	$basic = 'Something';
warn 'Found ' . $basic;
my	$health = 'Sick';
###Health	$health = 'Healthy';
warn 'I am ' . $health;
my	$wealth = 'Broke';
###Wealth	$wealth = 'Rich';
warn 'I am ' . $wealth;
use Level1; # Which uses Level2 which uses Level3
warn Level1->check_return;