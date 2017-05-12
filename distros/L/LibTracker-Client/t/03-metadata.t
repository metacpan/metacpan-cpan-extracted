use Test::More;
use LibTracker::Client qw(:all);

if( !defined $ENV{LTC_TRACKER_RUNNING} ) {
	plan skip_all => "LTC_TRACKER_RUNNING not set";
}
else {
	plan tests => 12;
}

my $tracker = LibTracker::Client->get_instance();

SKIP: {
	skip "LTC_TEST_PATH not set", 5 unless defined $ENV{LTC_TEST_PATH};

	my $path = $ENV{LTC_TEST_PATH};
	my $field = $ENV{LTC_META_FIELD} || "File:Other";
	my $test_value = "XXX_LTCMETA_XXX";

	# try to set metadata
	my $metadata = { $field => $test_value };
	my $num_changes = $tracker->set_metadata(SERVICE_FILES, $path, $metadata);
	is( $num_changes, 1, "number of fields changed" );

	# get metadata
	$metadata = $tracker->get_metadata(SERVICE_FILES, $path, [ $field ]);
	is( $metadata->{$field}, $test_value, "metadata" );

	# search metadata
	my $results = $tracker->search_metadata(SERVICE_FILES, $field, $test_value, 0, 100);
	ok( $results, "search results" );
	is( ref $results, "ARRAY", "search results return type" );
	TODO: {
		local $TODO = "metadata search has problems";
		ok( contains( $results, $path ), "test file in results" );
	}
}

# register metadata type

$tracker->register_metadata_type("Doc:Text", DATA_STRING_INDEXABLE);
pass("register metadata type");		# if it reaches this - it passed.

my $arrayref = $tracker->get_registered_metadata_classes();
ok( $arrayref, "metadata_classes return value" );
is( ref $arrayref, "ARRAY", "metadata_classes return value type" );

my $types = $tracker->get_registered_metadata_types($arrayref->[0]);
ok( $types, "metadata_types return value" );
is( ref $types, "ARRAY", "metadata_types return value type" );

my $wt = $tracker->get_writeable_metadata_types($arrayref->[0]);
ok( $wt, "writeable_metadata_types return value" );
is( ref $wt, "ARRAY", "writeable_metadata_types return value type" );


sub contains
{
	my $aref = shift;
	my $value = shift;

	foreach my $elem ( @{$aref} ) {
		return 1 if ($elem eq $value);
	}

	return 0;
}

