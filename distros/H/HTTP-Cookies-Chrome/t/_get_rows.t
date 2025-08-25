use lib qw(t/lib);
use Test::More;
use TestUtils;

my $method = '_get_rows';

sanity_subtest;

my $cookies = class()->new(
	chrome_safe_storage_password => test_passphrase(),
	ignore_discard               => 1,
	);
isa_ok $cookies, class();
can_ok $cookies, $method;

my $rows = $cookies->$method( test_database_path() );
isa_ok $rows, ref [], "$method returns an array reference";
is scalar @$rows, 23, "$method returns 14 rows";

foreach my $row ( @$rows ) {
	isa_ok $row, 'HTTP::Cookies::Chrome::Record';
	}

done_testing();
