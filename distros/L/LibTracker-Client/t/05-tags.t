use Test::More;
use LibTracker::Client qw(:services);

if( defined $ENV{LTC_TRACKER_RUNNING} ) {
	plan tests => 20;
}
else {
	plan skip_all => "LTC_TRACKER_RUNNING is not set";
}

SKIP: {
	skip "LTC_TEST_PATH is not set", 20 unless defined $ENV{LTC_TEST_PATH};

	my $file = $ENV{LTC_TEST_PATH};
	my $tag1 = "XXX_LTCTAG1_XXX";
	my $tag2 = "XXX_LTCTAG2_XXX";

	my $tracker = LibTracker::Client->get_instance();

	# add a tag
	my $num = $tracker->add_keywords(SERVICE_FILES, $file, [ $tag1, $tag2 ]);
	is( $num, 2, "number of tags added" );

	# get tags
	my $tags = $tracker->get_keywords(SERVICE_FILES, $file);
	ok( $tags, "get_keywords return value" );
	is( ref $tags, "ARRAY", "get_keywords return value type" );
	ok( contains( $tags, $tag1 ), "recently added tag1 for file" );
	ok( contains( $tags, $tag2 ), "recently added tag2 for file" );

	# get all tags
	$tags = $tracker->get_all_keywords(SERVICE_FILES);
	ok( $tags, "all_keywords return value" );
	is( ref $tags, "ARRAY", "all_keywords return value type" );
	ok( contains( $tags, $tag1 ), "recently added tag1 in all tags" );
	ok( contains( $tags, $tag2 ), "recently added tag2 in all tags" );

	# remove tags
	$num = $tracker->remove_keywords(SERVICE_FILES, $file, [ $tag2 ]);
	is( $num, 1, "number of tags removed" );

	# check if tags were removed
	$tags = $tracker->get_keywords(SERVICE_FILES, $file);
	is( ref $tags, "ARRAY", "get keywords return type" );
	ok( contains( $tags, $tag1 ), "still contains tag1" );
	ok( !contains( $tags, $tag2 ), "does not contain tag2" );

	# search tags
	my $results = $tracker->search_keywords(0, SERVICE_FILES, [ $tag1 ], 0, 100);
	ok( $results, "results returned" );
	is( ref $results, "ARRAY", "results type check" );
	ok( contains( $results, $file ), "results include test file" );

	# remove all tags
	my $success = $tracker->remove_all_keywords(SERVICE_FILES, $file);
	ok( $success, "remove all tags" );

	# verify
	$results = $tracker->get_keywords(SERVICE_FILES, $file);
	ok( $results, "results resturned after removing all tags" );
	is( ref $results, "ARRAY", "no results type check" );
	cmp_ok( scalar @{$results}, '==', 0, "zero results" );
}

sub contains
{
	my $aref = shift;
	my $value = shift;

	foreach my $elem ( @{$aref} ) {
		return 1 if ($elem eq $value);
	}

	return 0;
}

