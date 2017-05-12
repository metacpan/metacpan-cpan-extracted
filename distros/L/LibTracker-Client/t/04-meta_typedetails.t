use Test::More tests => 5;
use LibTracker::Client;
use LibTracker::Client::MetaDataTypeDetails;

SKIP: {
	skip "LTC_TRACKER_RUNNING not set", 5 unless defined $ENV{LTC_TRACKER_RUNNING};

	my $tracker = LibTracker::Client->get_instance();
	ok( $tracker, "LibTracker::Client instance" );
	isa_ok( $tracker, "LibTracker::Client", "type check" );

	my $mdtd = $tracker->get_metadata_type_details("Doc:Author");
	ok( $mdtd, "return value" );
	isa_ok( $mdtd, "LibTracker::Client::MetaDataTypeDetails", "MTDT type check" );

	$mdtd = $tracker->get_metadata_type_details("Will:NotMatch");
	ok( !defined $mdtd, "undef on failure" );
}

