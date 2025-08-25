package # hide from PAUSE
	TestUtils;

use Exporter qw(import);
use File::Spec::Functions qw(catfile);
use Test::More;

our @EXPORT = qw(
	class
	new_jar
	sanity_subtest
	test_database_path
	test_passphrase
	);

sub class { 'HTTP::Cookies::Chrome' };

sub new_jar {
	my $jar = class()->new(
		chrome_safe_storage_password => test_passphrase(),
		file                         => test_database_path(),
		);
	}

sub sanity_subtest {
	subtest 'sanity' => sub {
		use_ok class();
		ok -e test_database_path(), 'database path exists';
		};
	}

sub test_database_path { catfile( qw( test-corpus cookies-v24.db ) ) }
sub test_passphrase    { '1fFTtVFyMq/J03CMJvPLDg==' }

1;
