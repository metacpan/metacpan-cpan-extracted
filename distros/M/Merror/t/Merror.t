# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Merror.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More;
BEGIN { 
	use_ok('strict');
	use_ok('warnings');
	use_ok('Merror');
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
ok(Merror->new(),   'construct Merror object');
ok(Merror->new(stackdepth => 128), 'construct Merror object with defined stackdepth');
ok(Merror->new(errorfile => '/etc/test'), 'construct Merror object with defined errorfile');
ok(Merror->new(ramusage => 1), 'construct Merror object with defined ramusage');
subtest 'Example' => sub {
		my $errfile = '/errorfile';
		my $obj = Merror->new(stackdepth => 50, errorfile => '/etc/hosts', ramusage => 0);
		
		$obj->error(1);
		is($obj->error, 1,  'checking error state');
		
		$obj->ec(90);
		is($obj->ec, 90, 'checking errorcode');
		
		$obj->et('Test description');
		is($obj->et, 'Test description', 'checking error description');
		
		done_testing($number_of_tests);
};
done_testing($number_of_tests);
