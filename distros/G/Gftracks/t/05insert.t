# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Gftracks.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 12;
use Data::Dumper;
use Gftracks;
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# 1 - 5 Checks a plain insert
($tr)=init('t/test.wav.tracks');
$instime='00:04:00';
$stoptime=$tr->[2]{end};
$tr=instime($tr,$instime);
is($#{$tr},4,'4 tracks found');
is($tr->[0]{Number_of_tracks},4,'4 tracks indicated');
is($tr->[2]{end},$instime);
is($tr->[3]{start},$instime);
is($tr->[3]{end},$stoptime);

# 6 - 10 Checks an insert in the last track

($tr)=init('t/test.wav.tracks');
$instime='00:07:30';
$stoptime=$tr->[3]{end};
$tr=instime($tr,$instime);
is($#{$tr},4,'4 tracks found');
is($tr->[0]{Number_of_tracks},4,'4 tracks indicated');
is($tr->[3]{end},$instime);
is($tr->[4]{start},$instime);
is($tr->[4]{end},$stoptime);


# 11 - 12 Checks an insert between two tracks, no duration

($tr)=init('t/test.wav.tracks');
$instime='00:04:31';
$stoptime=$tr->[3]{end};
$tr=instime($tr,$instime);
is($#{$tr},3,'3 tracks found');
is($tr->[0]{Number_of_tracks},3,'3 tracks indicated');

