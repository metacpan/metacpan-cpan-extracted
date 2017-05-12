use Test::More tests => 6;
BEGIN { use_ok('LibTracker::Client') };

SKIP: {
	skip "LTC_TRACKER_RUNNING not set", 5 unless defined $ENV{LTC_TRACKER_RUNNING};

	my $tracker = LibTracker::Client->get_instance();
	ok( $tracker, "get instance" );
	isa_ok( $tracker, "LibTracker::Client", "type check" );

	# version
	my $version = $tracker->get_version();
	ok( $version, "tracker version : $version" );

	# status
	my $status = $tracker->get_status();
	ok( $status, "tracker status : $status" );

	# services
	my $services = $tracker->get_services(0);
	ok( ref $services, scalar( keys %{$services} ) ." tacker services" );
}

