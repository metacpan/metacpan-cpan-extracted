# -*- perl -*-

# Priority processing.

package GOTM;

use strict;
use warnings;
use Exporter;
use Games::Object;
use vars qw(@ISA @EXPORT @RESULTS);

@ISA = qw(Games::Object Exporter);
@EXPORT = qw(@RESULTS);

@RESULTS = ();

sub initialize { @RESULTS = (); }

sub new
{
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $obj = Games::Object->new(@_);

	bless $obj, $class;
	$obj;
}

# arbitrary action method to be queued.

sub arbitrary_action
{
	my ($obj, $action, @uargs) = @_;
	push @RESULTS, [ $obj->id(), $action, @uargs ];
}

# Basic attribute modify event to test pmod and tend_to priorities

sub modifier_event
{
	my ($obj, $aname, @uargs) = @_;
	push @RESULTS, [ $obj->id(), $aname, @uargs ];
	1;
}

package main;

use strict;
use warnings;
use Test;
use Games::Object::Manager;
use Games::Object;

BEGIN { $| = 1; plan tests => 8 }

# Create two objects and give them different priorities.
my $man = Games::Object::Manager->new();
my $subobj1 = GOTM->new(
    -id => "TestObject1",
    -on_arbitrary => [ 'O:self', 'arbitrary_action', 'A:action','foo','A:bip' ],
);
ok( $subobj1 && ref($subobj1) eq 'GOTM' );
my $subobj2 = GOTM->new(
    -id => "TestObject2",
    -on_arbitrary => [ 'O:self', 'arbitrary_action', 'A:action','bar','A:bip' ],
);
ok( $subobj2 && ref($subobj2) eq 'GOTM' );
$man->add($subobj1);
$man->add($subobj2);
$subobj1->priority(1);
$subobj2->priority(2);

# Queue up actions for each in reverse order of priorities.
$subobj1->queue('action',
    action => 'object:on_arbitrary',
    args => { bip => 'baz' },
);
$subobj2->queue('action',
    action => 'object:on_arbitrary',
    args => { bip => 'fud' },
);

# Process all objects
GOTM->initialize();
$man->process();

# Check that the actions were performed in the right order.
ok( @GOTM::RESULTS == 2
# First subobj2
 && $GOTM::RESULTS[0][0] eq 'TestObject2'
 && $GOTM::RESULTS[0][1] eq 'object:on_arbitrary'
 && $GOTM::RESULTS[0][2] eq 'bar'
 && $GOTM::RESULTS[0][3] eq 'fud'
# Then subobj1
 && $GOTM::RESULTS[1][0] eq 'TestObject1'
 && $GOTM::RESULTS[1][1] eq 'object:on_arbitrary'
 && $GOTM::RESULTS[1][2] eq 'foo'
 && $GOTM::RESULTS[1][3] eq 'baz' );

# Clear the results array, change priorities, and try again.
GOTM->initialize();
$subobj1->priority(10);
$subobj1->queue('action',
    action => 'object:on_arbitrary',
    args => { bip => 'baz' },
);
$subobj2->queue('action',
    action => 'object:on_arbitrary',
    args => { bip => 'fud' },
);
$man->process();
ok( @GOTM::RESULTS == 2
# First subobj1 this time
 && $GOTM::RESULTS[0][0] eq 'TestObject1'
 && $GOTM::RESULTS[0][1] eq 'object:on_arbitrary'
 && $GOTM::RESULTS[0][2] eq 'foo'
 && $GOTM::RESULTS[0][3] eq 'baz'
# Then subobj2
 && $GOTM::RESULTS[1][0] eq 'TestObject2'
 && $GOTM::RESULTS[1][1] eq 'object:on_arbitrary'
 && $GOTM::RESULTS[1][2] eq 'bar'
 && $GOTM::RESULTS[1][3] eq 'fud' );

# Now to test tend-to priorities. First set things up by adding some event
# bindings and attributes.
$subobj1->new_attr(
    -name => "obj1attr1",
    -type => 'int',
    -value => 50,
    -real_value => 100,
    -tend_to_rate => 1,
    -priority => 2,
    -on_change => [ 'O:self', 'modifier_event', 'A:name', 'boop' ],
);
$subobj1->new_attr(
    -name => "obj1attr2",
    -type => 'int',
    -value => 50,
    -real_value => 100,
    -tend_to_rate => 1,
    -priority => 4,
    -on_change => [ 'O:self', 'modifier_event', 'A:name', 'boop' ],
);
$subobj2->new_attr(
    -name => "obj2attr1",
    -type => 'int',
    -value => 50,
    -real_value => 100,
    -tend_to_rate => 1,
    -priority => 3,
    -on_change => [ 'O:self', 'modifier_event', 'A:name', 'boop' ],
);
$subobj2->new_attr(
    -name => "obj2attr2",
    -type => 'int',
    -value => 50,
    -real_value => 100,
    -tend_to_rate => 1,
    -priority => 1,
    -on_change => [ 'O:self', 'modifier_event', 'A:name', 'boop' ],
);

# Process these and check the results by seeing what order the attributes
# were updated, which we can check by seeing what order the events were
# triggered.
GOTM->initialize();
$man->process();
ok( @GOTM::RESULTS == 4
 && $GOTM::RESULTS[0][0] eq 'TestObject1'
 && $GOTM::RESULTS[0][1] eq 'obj1attr2'
 && $GOTM::RESULTS[1][0] eq 'TestObject1'
 && $GOTM::RESULTS[1][1] eq 'obj1attr1'
 && $GOTM::RESULTS[2][0] eq 'TestObject2'
 && $GOTM::RESULTS[2][1] eq 'obj2attr1'
 && $GOTM::RESULTS[3][0] eq 'TestObject2'
 && $GOTM::RESULTS[3][1] eq 'obj2attr2' );
print "# DEBUG: RESULTS = " . scalar(@GOTM::RESULTS) . " (expected 4)\n"
  if (@GOTM::RESULTS != 4);

# Change the priority of the objects themselves. This should only affect
# the order of the objects, not the tend-tos within the objects.
GOTM->initialize();
$subobj1->priority(5);
$subobj2->priority(7);
$man->process();
ok( @GOTM::RESULTS == 4
 && $GOTM::RESULTS[0][0] eq 'TestObject2'
 && $GOTM::RESULTS[0][1] eq 'obj2attr1'
 && $GOTM::RESULTS[1][0] eq 'TestObject2'
 && $GOTM::RESULTS[1][1] eq 'obj2attr2'
 && $GOTM::RESULTS[2][0] eq 'TestObject1'
 && $GOTM::RESULTS[2][1] eq 'obj1attr2'
 && $GOTM::RESULTS[3][0] eq 'TestObject1'
 && $GOTM::RESULTS[3][1] eq 'obj1attr1' );
print "# DEBUG: RESULTS = " . scalar(@GOTM::RESULTS) . " (expected 4)\n"
  if (@GOTM::RESULTS != 4);

# Now switch the priorities of the attributes in the second object and
# see that it works.
GOTM->initialize();
$subobj2->mod_attr(-name => 'obj2attr2', -priority => 10);
$man->process();
ok( @GOTM::RESULTS == 4
 && $GOTM::RESULTS[0][0] eq 'TestObject2'
 && $GOTM::RESULTS[0][1] eq 'obj2attr2'
 && $GOTM::RESULTS[1][0] eq 'TestObject2'
 && $GOTM::RESULTS[1][1] eq 'obj2attr1'
 && $GOTM::RESULTS[2][0] eq 'TestObject1'
 && $GOTM::RESULTS[2][1] eq 'obj1attr2'
 && $GOTM::RESULTS[3][0] eq 'TestObject1'
 && $GOTM::RESULTS[3][1] eq 'obj1attr1' );
print "# DEBUG: RESULTS = " . scalar(@GOTM::RESULTS) . " (expected 4)\n"
  if (@GOTM::RESULTS != 4);

# Add a third attribute to the first object with a priority that is in the
# middle of the existing ones and try that.
$subobj1->new_attr(
    -name => "obj1attr3",
    -type => 'int',
    -value => 50,
    -real_value => 100,
    -tend_to_rate => 1,
    -priority => 3,
    -on_change => [ 'O:self', 'modifier_event', 'A:name', 'boop' ],
);
GOTM->initialize();
$man->process();
ok( @GOTM::RESULTS == 5
 && $GOTM::RESULTS[0][0] eq 'TestObject2'
 && $GOTM::RESULTS[0][1] eq 'obj2attr2'
 && $GOTM::RESULTS[1][0] eq 'TestObject2'
 && $GOTM::RESULTS[1][1] eq 'obj2attr1'
 && $GOTM::RESULTS[2][0] eq 'TestObject1'
 && $GOTM::RESULTS[2][1] eq 'obj1attr2'
 && $GOTM::RESULTS[3][0] eq 'TestObject1'
 && $GOTM::RESULTS[3][1] eq 'obj1attr3'
 && $GOTM::RESULTS[4][0] eq 'TestObject1'
 && $GOTM::RESULTS[4][1] eq 'obj1attr1' );
print "# DEBUG: RESULTS = " . scalar(@GOTM::RESULTS) . " (expected 5)\n"
  if (@GOTM::RESULTS != 5);

exit (0);
