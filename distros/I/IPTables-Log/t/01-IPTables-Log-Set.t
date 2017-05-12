# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl IPTables-Log.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 23;
BEGIN { use_ok('IPTables::Log') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# Create new IPTables::Log object
my $l = IPTables::Log->new;
# Check it's of the correct type
ok(ref($l) eq "IPTables::Log",								"Object is of type IPTables::Log");

# Create a new IPTables::Log::Set object
my $s = $l->create_set;
# Check it's of the correct type
ok(ref($s) eq "IPTables::Log::Set",							"Object is of type IPTables::Log::Set");

# Load in example syslog
ok($s->load_file('example-data/syslog'),					"Loaded example-data/syslog");
# Test get_by
foreach my $field (qw(guid date time hostname prefix in out mac src dst proto spt dpt id len ttl df window syn))
{
	#diag($field);
	ok($s->get_by($field),									"Sorting by ".$field);
}
