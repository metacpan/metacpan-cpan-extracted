use Test::More tests => 17;
BEGIN { use_ok('LibTracker::Client') };


for( my $i = 0; $i < 16; $i++ ) {
	my $name = LibTracker::Client->service_name($i);
	my $type = LibTracker::Client->service_type($name);

	is( $type, $i, "name - type : $name - $type" );
}

