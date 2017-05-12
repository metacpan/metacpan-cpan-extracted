# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Heap-MinMax.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 17;
BEGIN { use_ok('Heap::MinMax') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# create a tree with default constructor
my $mm_heap;
my @vals = (2, 1, 3, 7, 9, 5, 8);

ok( $mm_heap = Heap::MinMax->new(), 'min-max heap created');

eval{
	foreach my $val (@vals){    
	    $mm_heap->insert($val);
	}
};
is( $@, '', '$@ is not set after inserting values' );


is( my $min = $mm_heap->pop_min(), 1, 'minimum value popped was 1' );

is( my $max = $mm_heap->pop_max(), 9, 'maximum value popped was 9' );

is( $min = $mm_heap->min(), 2, 'minimum value is 2' );


$mm_heap = Heap::MinMax->new();
my @vals2 = (19, 16, 17);

eval{
	$mm_heap->insert(@vals2);
	$mm_heap->insert(20);
};
is( $@, '', '$@ is not set after inserting values' );

is( $mm_heap->max(), 20, 'max is 20' );


my @vals3 = (20.111111, 20.111112, 20.111113, 15.99999);
eval{
	$mm_heap->insert(@vals3);
};
is( $@, '', '$@ is not set after inserting values' );


is( $mm_heap->min, 15.99999, 'min was 15.99999' );



my $elt1 = { _name => "Bob",
	     _phone => "444-4444",};
my $elt2 = { _name => "Amy",
	     _phone => "555-5555",};
my $elt3 = { _name => "Sara",
	     _phone => "666-6666",}; 


ok(
  $mm_heap = Heap::MinMax->new(
    fcompare => sub{ my ($o1, $o2) = @_;
		     if($o1->{_name} gt $o2->{_name}){ return 1}
		     elsif($o1->{_name} lt $o2->{_name}){ return -1}
		     return 0;},
    feval     => sub{ my($obj) = @_;
		       return $obj->{_name} . ", " . $obj->{_phone};},   
    ),
    'min-max heap created successfully' );

eval{
   $mm_heap->insert($elt1);
};
is( $@, '', '$@ is not set after inserting object' );

eval{
   $mm_heap->insert($elt2);
};
is( $@, '', '$@ is not set after inserting object' );

eval{
   $mm_heap->insert($elt3);
};
is( $@, '', '$@ is not set after inserting object' );


ok( $mm_heap->min(), 'found min object');

ok( $mm_heap->max(), 'found max object');

my $obj = $mm_heap->pop_min();

is( $obj->{_name}, 'Amy', 'popped min object from heap');
