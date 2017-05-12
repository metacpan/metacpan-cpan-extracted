# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Gftracks.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 14;
use Data::Dumper;
use Gftracks;
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

($tr)=init('t/test.wav.tracks');

# Should not be able to delete tracknr < 1;
$tr=deltrack($tr,0);
is($#{$tr},3,'still 3 tracks found');
is($tr->[0]{Number_of_tracks},3,'still 3 tracks indicated');

# Should not be able to delete tracks after the last
$tr=deltrack($tr,4);
is($#{$tr},3,'still 3 tracks found');
is($tr->[0]{Number_of_tracks},3,'still 3 tracks indicated');


# Deleting a track, by default splicing it onto the beginning of the next track
$start=$tr->[2]{start};
$end=$tr->[3]{end};
$tr=deltrack($tr,2);
is($#{$tr},2,'2 tracks found');
is($tr->[0]{Number_of_tracks},2,'2 tracks indicated');
is($tr->[2]{start},$start,'Starttime for combined track');
is($tr->[2]{end},$end,'Endtime for combined track');


# Deleting the last track, splicing onto the former, since there is no next 
($tr)=init('t/test.wav.tracks');

$start=$tr->[2]{start};
$end=$tr->[3]{end};
$tr=deltrack($tr,3);
is($#{$tr},2,'2 tracks found');
is($tr->[2]{start},$start,'Starttime for combined track');
is($tr->[2]{end},$end,'Endtime for combined track');


# Deleting a track, having it spliced onto the former

($tr)=init('t/test.wav.tracks');

$start=$tr->[1]{start};
$end=$tr->[2]{end};
$tr=deltrack($tr,2,1);
is($#{$tr},2,'2 tracks found');
is($tr->[1]{start},$start,'Starttime for combined track');
is($tr->[1]{end},$end,'Endtime for combined track');
