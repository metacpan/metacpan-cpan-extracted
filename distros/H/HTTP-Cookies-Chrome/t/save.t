use lib qw(t/lib);
use Test::More;
use TestUtils;

sanity_subtest();

my $new_file = test_database_path() . '.save';
END { unlink $new_file };

my $jar;
subtest 'first jar' => sub {
	$jar = new_jar();
	isa_ok $jar, class();
	can_ok $jar, 'save';
	$jar->save( $new_file );
	};

my $jar2;
subtest 'new jar' => sub {
	$jar2 = class()->new(
		chrome_safe_storage_password => test_passphrase(),
		file                         => $new_file
		);
	isa_ok $jar2, class();
	};

done_testing();


