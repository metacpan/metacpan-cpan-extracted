# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl IO-Simple.t'

#########################

use Test::More tests => 10;
#use Test::More qw(no_plan);
BEGIN { use_ok('IO::Simple', qw/file slurp/) };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

{
	#insure our test file doesn't exist before we start
	unlink 't/test.dat';
	ok( !-e 't/test.dat'    , 'Test File not here yet.');
}

{
	#create a simple test.dat file for writing.
	my $t = file('t/test.dat','w');
	isa_ok($t, 'IO::Simple', 'File object created.');
	$t->print("TEST");
	$t->close;
	ok( -e 't/test.dat'    , 'File Created Successfully');
}

{
	my $line = file('t/test.dat', 'r')->slurp();
	is($line, 'TEST', 'TEST printed to and slurped from file.');	

	unlink 't/test.dat';
	ok( !-e 't/test.dat'    , 'Test File removed.');
}

{
	my $data  = file('t/data2');
	my $line1 = $data->slurp('|');
	$data->close();
	is($line1, 'this|is|a|test', 'Slurped  with $/ set to |');
}

{
	my $data  = file('t/data2');
	my $line1 = $data->readline('|');
	$data->close();
	is($line1, 'this'  , 'Readline with $/ set to |');
}

{
	my $data   = file('t/data2');
	my @lines  = $data->slurp('|');
	$data->close();
	is_deeply(\@lines, ['this','is', 'a','test'], 'Slurped in array context (OO)');
}


{
	my @lines = slurp('t/data2', '|');
	is_deeply(\@lines, ['this','is','a','test'], 'Slurped in array context (functional)');
}


