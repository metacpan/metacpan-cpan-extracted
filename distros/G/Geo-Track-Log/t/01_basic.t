# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 23;
use FileHandle;
use strict;
use warnings;

BEGIN { use_ok('Geo::Track::Log') };

#########################

my $st;
my $trk = new Geo::Track::Log;
$st = qq(44?  3' 33.23" -123?  5'  0.07" 148.0 WGS84 00:50:19-2004/07/12 [1];);


my $pt = $trk->fixGarnixTrackLine($st);
# ok is okay, but doesn't return the actual and expected values...
is(sprintf("%.4f",  $pt->{lat}),   44.0592, "fixGarnixTrackLine Check latitude");
is(sprintf("%.4f", $pt->{long}), -123.0834, "fixGarnixTrackLine Check longitude");
isnt(sprintf("%.4f", $pt->{long}), -124.0834, "fixGarnixTrackLine test the test on longitude");
is($pt->{date}, "2004-07-12", "fixGarnixTrackLine Check date");
is($pt->{time}, "00:50:19", "fixGarnixTrackLine Check time");
is($pt->{segment}, 1, "fixGarnixTrackLine Check segment flag");
is(sprintf("%.0f", $pt->{elevation}), 148, "fixGarnixTrackLine Check xelevation");

# try a second point in another hemisphere
$st = qq(-45?  3' 32.54" 123?  4' 59.76" 4148.0 WGS84 23:01:59-2003/2/1 [0];);
$pt = $trk->fixGarnixTrackLine($st);
is(sprintf("%.5f",  $pt->{lat}),   -45.05904, "fixGarnixTrackLine Check latitude");
is(sprintf("%.4f", $pt->{long}), 123.0833, "fixGarnixTrackLine Check longitude");
TODO: {
    local $TODO = 'Garnix returns single digit months and days.';
    is($pt->{date}, "2003-2-1", "fixGarnixTrackLine Check date");
}
is($pt->{time}, "23:01:59", "fixGarnixTrackLine Check time");
is($pt->{segment}, 0, "fixGarnixTrackLine Check segment flag");
is(sprintf("%.0f", $pt->{elevation}), 4148, "fixGarnixTrackLine Check xelevation");


# load a garnix log file

my $test_track_file = 'eg/garnix_log.txt';
if (! -e $test_track_file) {
	ok(0, "Test file does not exist.  Check for $test_track_file\n");
	exit;
}

# these tests don't run unless the test file exists
    my $fh = FileHandle->new;
	my $ok = eval {
	    open $fh, $test_track_file;
	};
	is($ok, 1,  "Opening $test_track_file\n");
	# if we didn't have an error opening the file then run the rest of the tests
	if ( $ok) {
	    $trk->loadTrackFromGarnix($fh);
	    is (@{$trk->{log}}, '326', 'Read 326 track points in test file');
	} else {
	    ok(0,"Can't read test file");
	}

	my $minPt = $trk->minTimeStamp();
	my $maxPt = $trk->maxTimeStamp();

	# print "minPt: " . Dumper($minPt);
	# print "maxPt: " . Dumper($maxPt);
	is($minPt->{timestamp}, '2004-04-28 23:40:26', "Check minTimeStamp()");
	is($maxPt->{timestamp}, '2004-04-29 05:31:06', "Check maxTimeStamp()");

	TODO: {
		local $TODO = 'Add tests for the $self->{dirty} flag.  See t/1.t, right here...';
		# check min/max
		# add a point outside of current min/max range
		# check min/max
		# is the min or max value changed?
		# ie.  does it really recalculate?
		# are there other ways that points could be added?
		ok(0, 'Add $self->{dirty} tests');
	}



# Tests that need to be added
# midway between two readings
$pt = $trk->whereWasI('2004-04-29 05:24:50');

# exactly on a point

# after any point in tracklog

# before any point in tracklog

# create an arbitrary log
my $testlog = new Geo::Track::Log();
$testlog->addPoint( {
		timestamp => '2004-12-25 12:00:00',
		lat => 0.0,
		long=> 0.0,
	} );
$testlog->addPoint( {
		timestamp => '2004-12-25 12:30:00',
		lat => 0.0,
		long=> 1.0,
	} );
$testlog->addPoint( {
		timestamp => '2004-12-25 13:00:00',
		lat => 1.0,
		long=> 1.0,
	} );
my ($sPt,$ePt);
($pt, $sPt, $ePt) = $testlog->whereWasI('2004-12-25 12:15:00');
is(sprintf('%.2f', $pt->{long}), '0.50', "long Midway between 0,0 and 0,1");
is(sprintf('%.2f', $pt->{lat}),  '0.00', "lat  Midway between 0,0 and 0,1");

($pt, $sPt, $ePt) = $testlog->whereWasI('2004-12-25 12:45:00');
is(sprintf('%.2f', $pt->{long}), '1.00', "long Midway between 0,1 and 1,1");
is(sprintf('%.2f', $pt->{lat}),  '0.50', "lat  Midway between 0,1 and 1,1");
exit;
is($pt->{long},  1.0, "long Midway between 0,1 and 1,1");
is($pt->{lat},   0.5, "lat  Midway between 0,1 and 1,1");


ok(1,'Tests done');
