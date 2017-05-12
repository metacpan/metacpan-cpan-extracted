# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl HTML-Persistent_1.t'

#########################

use Test::More tests => 3032;
BEGIN { use_ok('HTML::Persistent') };
my $want_cleanup = 1;                        # Cancel cleanup for port-mortem data inspection.

#########################

use File::Temp qw(tempdir);
my $dir;
if( $want_cleanup )
{
	$dir = tempdir( CLEANUP => $want_cleanup );
}
else
{
	$dir = '/tmp/test-html-persistent';
	system( "/bin/rm -rf '$dir'" );
	system( "mkdir '$dir'" );
	diag( "Data will be left behind in directory $dir" );
}

my $db = HTML::Persistent->new({ dir => $dir, max => 10000 });
isa_ok( $db, 'HTML::Persistent', 'Basic starting database' );

# ========================================================

my $node1 = $db->{test_one};
isa_ok( $node1, 'HTML::Persistent::hash', 'Can make a hash node' );
is( $node1->sha1(), 'fec15ba21680332b25ff77be77d3e6172a3f7ad5', 'Check sha1 of hash (first level)' );

my $node2 = $node1->{test_two};
isa_ok( $node1, 'HTML::Persistent::hash', 'Can make a hash node from a hash node' );
is( $node2->sha1(), 'b12deb3608ed601849c5a68ab5d91b5e183c1fe1', 'Check sha1 of hash (second level)' );

# ========================================================

my $node3 = $db->[12];
isa_ok( $node3, 'HTML::Persistent::array', 'Can make an array node' );
is( $node3->sha1(), 'aa15079a4f284251b8569bd843b1ed196385ed00', 'Check sha1 of array (first level)' );

my $node4 = $node3->[21];
isa_ok( $node4, 'HTML::Persistent::array', 'Can make an array node from an array node' );
is( $node4->sha1(), '767d0338c27526bd03528c7a044424f4806b1b53', 'Check sha1 of array (second level)' );

# ========================================================
# Double-up a node as both array and hash, also freform chain of arrays and hashes.

my $node5 = $db->{test_three}[55]{55};
isa_ok( $node5, 'HTML::Persistent::hash', 'Freeform chain, hash/array/hash' );
is( $node5->sha1(), 'ec168e957c136dba736506cc4e0267623836a136', 'Check sha1 of freeform chain, hash/array/hash' );

my $node6 = $db->{test_three}{55}[55];
isa_ok( $node6, 'HTML::Persistent::array', 'Freeform chain, hash/hash/array' );

is( $node6->sha1(), '8b22993cd3e136b656cc27580186f577b883cb53', 'Check sha1 of freeform chain, hash/hash/array' );

# ========================================================
# Check default names of nodes

is( $node1->name(), 'test_one', 'Name of a hash node' );
is( $node2->name(), 'test_two', 'Name of a hash node' );
is( $node3->name(), undef, 'Array node has no name by default' );
is( $node4->name(), undef, 'Array node has no name by default' );

# ========================================================
# Now we start loading up some actual data into the tree.

my $val1 = 'This is a test for node1, some value loaded here';
my $val2 = [ 'using', 'array', 'value' ];
my $val3 = 0.00001;
my $val4 = { test => 1, hash => 2, value => 3 };

$node1->set_val( $val1 );
$node2->set_val( $val2 );
$node3->set_val( $val3 );
$node4->set_val( $val4 );
$db->sync();

is( scalar( @$node1 ),  0, "scalar #1" );
is( scalar( @$node2 ),  0, "scalar #2" );
is( scalar( @$node3 ), 22, "scalar #3" );
is( scalar( @$node4 ),  0, "scalar #4" );

# ========================================================
# Throw away the existing db object, and start a new one.
# Try to read those values back again.

$db->sync(); # Always sync before throwing away!
$db = undef;

ok( -f "$dir/b4613f8681b1e26686a2e88299525a4dc89c46d5.data", "Prove that root file exists" );
$db = HTML::Persistent->new({ dir => $dir, max => 10000 });
isa_ok( $db, 'HTML::Persistent', 'Re-open database' );

$node1 = $db->{test_one};
$node2 = $node1->{test_two};
$node3 = $db->[12];
$node4 = $node3->[21];

is( $node1->val(), $val1, "Test string value" );
is_deeply( $node2->val(), $val2, "Test array value" );
is( $node3->val(), $val3, "Test number value" );
is_deeply( $node4->val(), $val4, "Test hash value" );

# ========================================================
# Should be in read-only mode, so edit some values and see
# it change to write mode, then load up a large number of
# values to make it split.

$val1 = "Totally different value to force write mode";
$db->{test_one} = $val1;
$db->sync();

$node1 = $db->{test_one};
is( $node1->val(), $val1, 'Changed value of hash node' );

# Change the name of some array nodes
$node3->name( 'array-node-1' );
$node4->name( 'array-node-2' );

$db->sync();

# Start from fresh again, make it read back

$db = undef;
$db = HTML::Persistent->new({ dir => $dir, max => 10000 });
$node3 = $db->[12];
$node4 = $node3->[21];

is( $node3->name(), 'array-node-1', 'Changed the name of array node #1' );
is( $node4->name(), 'array-node-2', 'Changed the name of array node #2' );

# ========================================================
# Create large volume of data, with random tree structure
# in order to force splits, etc. Store the data two different
# ways so we can check one against the other.

my @names = ( 'one', 'two', 'three', 'four', 'five' );
my $data = {}; # Gets used later

for( my $i = 0; $i < 1000; ++$i )
{
	my $j1 = $names[ int( rand( 5 ))];
	my $j2 = $names[ int( rand( 5 ))];
	my $j3 = int( rand( 10 ));          # NOTE: tests array key
	my $j4 = $names[ int( rand( 5 ))];
	my $j5 = $names[ int( rand( 5 ))];
	my $j6 = $names[ int( rand( 5 ))];

	# diag( "KEY: {$j1}{$j2}[$j3]{$j4}{$j5}{$j6}" );

	my $n1 = $db->{$j1}{$j2}[$j3]{$j4}{$j5}{$j6}; # NOTE: $j3 is array
	my $n2 = $db->{$j6}{$j5}{$j4}[$j3]{$j2}{$j1}; #	NOTE: $j3 is array

	# We do mostly a lot of read testing
	$val1 = $n1->val();
	$val2 = $n2->val();
	is( $val1, $val2, "Big hash test $i" );

	# With occasional write to a pair of values
	if( rand() < 0.20 )
	{
		$val3 = rand();
		$n1->set_val( $val3 );
		$n2->set_val( $val3 );
		my $key = "{$j1}{$j2}[$j3]{$j4}{$j5}{$j6}";
		$data->{$key} = $val3; # Store in memory for later
	}

	# And also flush out the cache at random now and then.
	if( rand() < 0.05 ) { $db->sync(); }
}

$db->sync();

# ========================================================
# Test the system where an existing split node gets modified

$val1 = 'Extra node, modified';
$db->{extra}[10] = $val1;
$db->sync();
$node1 = $db->{extra}[10];
is( $node1->val(), $val1, 'Check late addition to root node' );

# ========================================================
# Loop like above but purely in read-only mode.
# Should contain data from previous efforts.

for( my $i = 0; $i < 1000; ++$i )
{
	my $j1 = $names[ int( rand( 5 ))];
	my $j2 = $names[ int( rand( 5 ))];
	my $j3 = int( rand( 10 ));          # NOTE: tests array key
	my $j4 = $names[ int( rand( 5 ))];
	my $j5 = $names[ int( rand( 5 ))];
	my $j6 = $names[ int( rand( 5 ))];

	my $n1 = $db->{$j1}{$j2}[$j3]{$j4}{$j5}{$j6}; # NOTE: $j3 is array
	my $n2 = $db->{$j6}{$j5}{$j4}[$j3]{$j2}{$j1}; #	NOTE: $j3 is array

	$val1 = $n1->val();
	$val2 = $n2->val();
	is( $val1, $val2, "Big hash read test $i" );
	# In read mode, sync() just empties out cache contents and drops locks.
	if( rand() < 0.05 ) { $db->sync(); }
}

# ========================================================
# Back to read-write mode with a different name thrown in
# to encourage expansion of existing nodes. Also compare against
# perl memory data as an altgernative way to prove consistency

@names = ( 'one', 'two', 'three', 'four', 'five', 'six' );

for( my $i = 0; $i < 1000; ++$i )
{
	my $j1 = $names[ int( rand( 6 ))];
	my $j2 = $names[ int( rand( 6 ))];
	my $j3 = int( rand( 10 ));          # NOTE: tests array key
	my $j4 = $names[ int( rand( 6 ))];
	my $j5 = $names[ int( rand( 6 ))];
	my $j6 = $names[ int( rand( 6 ))];

	my $key = "{$j1}{$j2}[$j3]{$j4}{$j5}{$j6}"; # String key for memory
	my $n1 = $db->{$j1}{$j2}[$j3]{$j4}{$j5}{$j6}; # NOTE: $j3 is array

	$val1 = $n1->val();
	$val2 = $data->{$key};
	is( $val1, $val2, "Big hash second test $i" );

	if( rand() < 0.50 )
	{
		$val3 = rand();
		$n1->set_val( $val3 );
		$data->{$key} = $val3; # Store in memory
	}

	if( rand() < 0.10 ) { $db->sync(); }
}

$db->sync();

use Data::Dumper; warn( Dumper( $db->stats()));

