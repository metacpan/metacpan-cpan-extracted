# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Gftracks.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 16;
use Data::Dumper;
use Gftracks;
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

($tr)=init('t/test.wav.tracks');


ok($tr,'Defined tracks');
ok($tr->[0],'Defined data');
is($#{$tr},3,'3 tracks found');


is($tr[0],undef,'nothing in 0th element');

# Test 5 .. 8

foreach('start','end','starttime','comment'){
	ok($tr->[1]{$_},"$_ found");
}

# Test 9 - 12
is($tr->[1]{start},'0:00:05.000','Starttime');
is($tr->[1]{starttime},5,'Starttime');
is($tr->[1]{end},'0:03:11.600','Stoptime');
is($tr->[1]{comment},'# Track 1 - blocks 0 to 1915 - length: 0:03:11.600','comment');

# Test 13 - 16
is($tr->[2]{start},'0:03:14.800','Starttime');
is($tr->[2]{starttime},194.8,'Starttime');
is($tr->[2]{end},'0:04:29.700','Stoptime');
is($tr->[2]{comment},'# Track 2 - blocks 1948 to 2696 - length: 0:01:14.900','comment');




