# -*- perl -*-

# Events

package GOTM;

# GOTM = Games Object Test Module

use strict;
use warnings;
use Exporter;
use vars qw(@ISA @EXPORT);

use Games::Object;

@ISA = qw(Games::Object Exporter);
@EXPORT = qw(@RESULTS %RETCODE);

use vars qw(@RESULTS %RETCODE);

@RESULTS = ();
%RETCODE = ();

sub new
{
	my $class = shift;
	my $obj = $class->SUPER::new(@_);
	bless $obj, $class;
	$obj;
}

sub initialize
{
	@RESULTS = ();
	%RETCODE = (
	    attr1a_changed		=> 1,
	    attr1b_changed		=> 1,
	    attr1_changed_by_me		=> 1,
	    attr1_changed_by_other	=> 1,
	    attr1_maxed			=> 1,
	    attr1_minned		=> 1,
	    attr2_changed		=> 1,
	    attr2_changed_by_other	=> 1,
	    attr2_maxed			=> 1,
	    bop				=> 1,
	    boop			=> 1,
	    bif				=> 1,
	    zot				=> 1,
	);
}

sub attr1a_changed
{
	my ($obj, $name, $action, $old, $new, @uargs) = @_;
	push @RESULTS, [ $obj->id(), 'attr1a_changed', $name, $action, $old, $new, @uargs ];
	$RETCODE{attr1a_changed};
}

sub attr1b_changed
{
	my ($obj, $name, $action, $old, $new, @uargs) = @_;
	push @RESULTS, [ $obj->id(), 'attr1b_changed', $name, $action, $old, $new, @uargs ];
	$RETCODE{attr1b_changed};
}

sub attr1b_failed
{
	my ($obj, $name, $action, $old, $new, @uargs) = @_;
	push @RESULTS, [ $obj->id(), 'attr1b_failed', $name, $action, $old, $new, @uargs ];
	1;
}

sub attr1_changed_by_me
{
	my ($obj, $name, $action, $old, $new, @uargs) = @_;
	push @RESULTS, [ $obj->id(), 'attr1_changed_by_me', $name, $action, $old, $new, @uargs ];
	$RETCODE{attr1_changed_by_me};
}

sub attr1_changed_by_other
{
	my ($obj, $name, $action, $old, $new, @uargs) = @_;
	push @RESULTS, [ $obj->id(), 'attr1_changed_by_other', $name, $action, $old, $new, @uargs ];
	$RETCODE{attr1_changed_by_other};
}

sub attr1_maxed
{
	my ($obj, $name, $action, $old, $new, @uargs) = @_;
	push @RESULTS, [ $obj->id(), 'attr1_maxed', $name, $action, $old, $new, @uargs ];
	$RETCODE{attr1_maxed};
}

sub attr1_minned
{
	my ($obj, $name, $action, $old, $new, @uargs) = @_;
	push @RESULTS, [ $obj->id(), 'attr1_minned', $name, $action, $old, $new, @uargs ];
	$RETCODE{attr1_minned};
}

sub attr2_changed
{
	my ($obj, $name, $action, $old, $new, @uargs) = @_;
	push @RESULTS, [ $obj->id(), 'attr2_changed', $name, $action, $old, $new, @uargs ];
	$RETCODE{attr2_changed};
}

sub attr2_changed_by_other
{
	my ($obj, $name, $action, $old, $new, @uargs) = @_;
	push @RESULTS, [ $obj->id(), 'attr2_changed_by_other', $name, $action, $old, $new, @uargs ];
	$RETCODE{attr2_changed_by_other};
}

sub attr2_maxed
{
	my ($obj, $name, $action, $old, $new, @uargs) = @_;
	push @RESULTS, [ $obj->id(), 'attr2_maxed', $name, $action, $old, $new, @uargs ];
	$RETCODE{attr2_maxed};
}

sub simple_test
{
	my ($self, $other, $object, $arg) = @_;
	push @RESULTS, [ $self, $other, $object, $arg ];
}

sub bop_func
{
	my ($obj, $other, @args) = @_;
	push @RESULTS, [ $obj->id(), 'bop', $other, @args ];
	$RETCODE{bop};
}

sub boop_func
{
	my ($obj, $other, @args) = @_;
	push @RESULTS, [ $obj->id(), 'boop', $other, @args ];
	$RETCODE{bop};
}

sub bif_func
{
	my ($obj, $other, @args) = @_;
	push @RESULTS, [ $obj->id(), 'bif', $other, @args ];
	$RETCODE{bif};
}

sub zot_func
{
	my ($obj, $other, @args) = @_;
	push @RESULTS, [ $obj->id(), 'zot', $other, @args ];
	$RETCODE{zot};
}

package main;

use strict;
use warnings;
use Test;
use Games::Object::Manager;
use Games::Object qw($CompareFunction ACT_MISSING_OK);
use IO::File;

BEGIN { $| = 1; plan tests => 39 }

sub Attr2Changed
{
	my ($name, $action, $old, $new, @uargs) = @_;
	push @GOTM::RESULTS,
	  [ 'NONE', 'Attr2Changed', $name, $action, $old, $new, @uargs ];
	1;
}

# Create three objects from the subclassed test module and add to manager.
my $man = Games::Object::Manager->new();
my $obj1 = GOTM->new(id => "Object1");
my $obj2 = GOTM->new(id => "Object2");
my $obj3 = GOTM->new(id => "Object3");
ok( defined($obj1) && $obj1->isa('Games::Object')
 && defined($obj2) && $obj2->isa('Games::Object')
 && defined($obj3) && $obj3->isa('Games::Object') );
$man->add($obj1);
$man->add($obj2);
$man->add($obj3);

# Create two attributes on the first object.
$obj1->new_attr(
    -name	=> "attr1",
    -type	=> "int",
    -value	=> 50,
    -minimum	=> 0,
    -maximum	=> 100,
    -on_change	=> [
	[ 'O:self', 'attr1a_changed', 'A:action', 'A:name', 'A:old', 'A:new',
	  'foo', 'bar' ],
	[ 'O:self', 'attr1b_changed', 'A:action', 'A:name', 'A:old', 'A:new',
	  'baz', 'fud' ],
	FAIL => [ 'O:self', 'attr1b_failed', 'A:action', 'A:name',
		  'A:old', 'A:new', 'oopsie', 'daisy' ],
	[ 'O:other', 'attr1_changed_by_me', 'A:action', 'A:name',
	  'A:old', 'A:new', 'goof' ],
    ],
    -on_maximum	=> [ 'O:self', 'attr1_maxed', 'A:action', 'A:name',
		     'A:old', 'A:new', 'A:excess', 'dud' ],
    -on_minimum => [ 'O:self', 'attr1_minned', 'A:action', 'A:name',
		     'A:old', 'A:new', 'A:excess', 'doof' ],
);
$obj1->new_attr(
    -name	=> "attr2",
    -type	=> "int",
    -value	=> 25,
    -minimum	=> 0,
    -maximum	=> 50,
    -on_change 	=> [
	[ 'O:self', 'attr2_changed', 'A:action', 'A:name', 'A:old', 'A:new',
	  'bif','bop' ],
	[ 'O:Object3', 'attr2_changed_by_other', 'A:action', 'A:name',
	  'A:old', 'A:new', 'gloop' ],
	[ 'main::Attr2Changed', 'A:action', 'A:name', 'A:old', 'A:new',
	  'barf', 'bork' ],
    ],
    -on_maximum	=> [ 'O:self', 'attr2_maxed', 'A:action', 'A:name',
		     'A:old', 'A:new', 'bip', 'boop', 'bonk' ],
);

# Add persistent modifiers to both, make sure no actions called yet.
GOTM->initialize();
eval('$obj1->mod_attr(
    -name	=> "attr1",
    -modify	=> 30,
    -persist_as	=> "Object1_attr1_modifier",
    -incremental => 1,
    -other	=> $obj2,
);');
ok( $@ eq '' );
print "# \$@ = $@" if ($@);
eval('$obj1->mod_attr(
    -name	=> "attr2",
    -modify	=> 10,
    -persist_as	=> "Object1_attr2_modifier",
    -incremental => 1,
    -other	=> $obj2,
);');
ok( $@ eq '' );
print "# \$@ = $@" if ($@);
ok( @GOTM::RESULTS == 0 );

# Process modifiers, check that all actions were called with proper args. This
# is a VERY extensive test, meant to insure that EVERY datum is present in
# a typical set of action triggers. Subsequent tests will test a subset of
# these.
$man->process();
ok( @GOTM::RESULTS == 6 );
print "# RESULTS has " . scalar(@GOTM::RESULTS) . " items (should have 6)\n"
  if (@GOTM::RESULTS != 6);
# Callback #1
ok(
# Object ID parameter
    $GOTM::RESULTS[0][0] eq 'Object1'
# Method name
 && $GOTM::RESULTS[0][1] eq 'attr1a_changed'
# Callback args
 && $GOTM::RESULTS[0][2] eq 'attr:attr1:on_change'
 && $GOTM::RESULTS[0][3] eq 'attr1'
 && $GOTM::RESULTS[0][4] == 50
 && $GOTM::RESULTS[0][5] == 80
 && $GOTM::RESULTS[0][6] eq 'foo'
 && $GOTM::RESULTS[0][7] eq 'bar' );
# Callback #2
ok(
# Object ID parameter
    $GOTM::RESULTS[1][0] eq 'Object1'
# Method name
 && $GOTM::RESULTS[1][1] eq 'attr1b_changed'
# Callback args
 && $GOTM::RESULTS[1][2] eq 'attr:attr1:on_change'
 && $GOTM::RESULTS[1][3] eq 'attr1'
 && $GOTM::RESULTS[1][4] == 50
 && $GOTM::RESULTS[1][5] == 80
 && $GOTM::RESULTS[1][6] eq 'baz'
 && $GOTM::RESULTS[1][7] eq 'fud' );
# Callback #3
ok(
# Object ID parameter
    $GOTM::RESULTS[2][0] eq 'Object2'
# Method name
 && $GOTM::RESULTS[2][1] eq 'attr1_changed_by_me'
# Callback args
 && $GOTM::RESULTS[2][2] eq 'attr:attr1:on_change'
 && $GOTM::RESULTS[2][3] eq 'attr1'
 && $GOTM::RESULTS[2][4] == 50
 && $GOTM::RESULTS[2][5] == 80
 && $GOTM::RESULTS[2][6] eq 'goof' );
# Callback #4
ok(
# Object ID parameter
    $GOTM::RESULTS[3][0] eq 'Object1'
# Method name
 && $GOTM::RESULTS[3][1] eq 'attr2_changed'
# Callback args
 && $GOTM::RESULTS[3][2] eq 'attr:attr2:on_change'
 && $GOTM::RESULTS[3][3] eq 'attr2'
 && $GOTM::RESULTS[3][4] == 25
 && $GOTM::RESULTS[3][5] == 35
 && $GOTM::RESULTS[3][6] eq 'bif'
 && $GOTM::RESULTS[3][7] eq 'bop' );
# Callback #5
ok(
# Object ID parameter
    $GOTM::RESULTS[4][0] eq 'Object3'
# Method name
 && $GOTM::RESULTS[4][1] eq 'attr2_changed_by_other'
# Callback args
 && $GOTM::RESULTS[4][2] eq 'attr:attr2:on_change'
 && $GOTM::RESULTS[4][3] eq 'attr2'
 && $GOTM::RESULTS[4][4] == 25
 && $GOTM::RESULTS[4][5] == 35
 && $GOTM::RESULTS[4][6] eq 'gloop' );
# Callback #6
ok(
# Object ID parameter
    $GOTM::RESULTS[5][0] eq 'NONE'
# Method name
 && $GOTM::RESULTS[5][1] eq 'Attr2Changed'
# Callback args
 && $GOTM::RESULTS[5][2] eq 'attr:attr2:on_change'
 && $GOTM::RESULTS[5][3] eq 'attr2'
 && $GOTM::RESULTS[5][4] == 25
 && $GOTM::RESULTS[5][5] == 35
 && $GOTM::RESULTS[5][6] eq 'barf'
 && $GOTM::RESULTS[5][7] eq 'bork' );

# Now process again. This time we should see 7 actions, as one attribute
# hits its maximum and triggers the extra callback.
GOTM->initialize();
$man->process();
ok( @GOTM::RESULTS == 7 );
print "# RESULTS has " . scalar(@GOTM::RESULTS) . " items (should have 7)\n"
  if (@GOTM::RESULTS != 7);
# Check that the actions got in the queue in the right order.
ok( $GOTM::RESULTS[0][0] eq 'Object1'
 && $GOTM::RESULTS[0][2] eq 'attr:attr1:on_change'
 && $GOTM::RESULTS[1][0] eq 'Object1'
 && $GOTM::RESULTS[1][2] eq 'attr:attr1:on_change'
 && $GOTM::RESULTS[2][0] eq 'Object2'
 && $GOTM::RESULTS[2][2] eq 'attr:attr1:on_change'
 && $GOTM::RESULTS[3][0] eq 'Object1'
 && $GOTM::RESULTS[3][2] eq 'attr:attr1:on_maximum'
 && $GOTM::RESULTS[4][0] eq 'Object1'
 && $GOTM::RESULTS[4][2] eq 'attr:attr2:on_change'
 && $GOTM::RESULTS[5][0] eq 'Object3'
 && $GOTM::RESULTS[5][2] eq 'attr:attr2:on_change'
 && $GOTM::RESULTS[6][0] eq 'NONE'
 && $GOTM::RESULTS[6][2] eq 'attr:attr2:on_change' );
# Now check that EVERY datum for an on_maximum is present.
ok(
# Object ID parameter
    $GOTM::RESULTS[3][0] eq 'Object1'
# Method name
 && $GOTM::RESULTS[3][1] eq 'attr1_maxed'
# Callback args
 && $GOTM::RESULTS[3][2] eq 'attr:attr1:on_maximum'
 && $GOTM::RESULTS[3][3] eq 'attr1'
 && $GOTM::RESULTS[3][4] == 80
 && $GOTM::RESULTS[3][5] == 100
 && $GOTM::RESULTS[3][6] == 10
 && $GOTM::RESULTS[3][7] eq 'dud' );

# Process again. We should see 4 items. We will not see anything
# from attr1, since it cannot change once at max. attr2 should see mod
# events, plus the max-out callback.
GOTM->initialize();
$man->process();
ok( @GOTM::RESULTS == 4 );
print "# RESULTS has " . scalar(@GOTM::RESULTS) . " items (should have 4)\n"
  if (@GOTM::RESULTS != 4);
# Check that the actions got in the queue in the right order.
ok( $GOTM::RESULTS[0][0] eq 'Object1'
 && $GOTM::RESULTS[0][2] eq 'attr:attr2:on_change'
 && $GOTM::RESULTS[1][0] eq 'Object3'
 && $GOTM::RESULTS[1][2] eq 'attr:attr2:on_change'
 && $GOTM::RESULTS[2][0] eq 'NONE'
 && $GOTM::RESULTS[2][2] eq 'attr:attr2:on_change'
 && $GOTM::RESULTS[3][0] eq 'Object1'
 && $GOTM::RESULTS[3][2] eq 'attr:attr2:on_maximum' );

# Process one more time. NO events should be generated.
GOTM->initialize();
$man->process();
ok( @GOTM::RESULTS == 0 );
print "# RESULTS has " . scalar(@GOTM::RESULTS) . " items (should have 0)\n"
  if (@GOTM::RESULTS != 0);

# Attempt to reset the first attribute to 0 without specifying an other object.
# This first attempt should fail.
GOTM->initialize();
eval('$obj1->mod_attr(-name => "attr1", -value => 0);');
ok( $@ && $@ =~ /Object 'O:other' not found/ );

# Set attr1 back to some non-0 value, since the attribute has been modified
# when the error above is encountered.
$obj1->mod_attr(-name => "attr1", -value => 10, -other => $obj2);

# Add the ACT_MISSING_OK flag to the first attribute and now try to set both
# attributes to minimum. We should see 6 events (2 for attr1 modification,
# skipping the one that references O:other, 3 for attr2 modification, and 1
# for attr1 reaching minimum)
GOTM->initialize();
$obj1->mod_attr(-name => 'attr1', -flags => ACT_MISSING_OK);
$obj1->mod_attr(-name => 'attr1', -value => 0);
$obj1->mod_attr(-name => 'attr2', -value => 0);
ok( @GOTM::RESULTS == 6 );
print "# RESULTS has " . scalar(@GOTM::RESULTS) . " items (should have 6)\n"
  if (@GOTM::RESULTS != 6);
# Check that the actions got in the queue in the right order.
ok( $GOTM::RESULTS[0][0] eq 'Object1'
 && $GOTM::RESULTS[0][2] eq 'attr:attr1:on_change'
 && $GOTM::RESULTS[1][0] eq 'Object1'
 && $GOTM::RESULTS[1][2] eq 'attr:attr1:on_change'
 && $GOTM::RESULTS[2][0] eq 'Object1'
 && $GOTM::RESULTS[2][2] eq 'attr:attr1:on_minimum'
 && $GOTM::RESULTS[3][0] eq 'Object1'
 && $GOTM::RESULTS[3][2] eq 'attr:attr2:on_change'
 && $GOTM::RESULTS[4][0] eq 'Object3'
 && $GOTM::RESULTS[4][2] eq 'attr:attr2:on_change'
 && $GOTM::RESULTS[5][0] eq 'NONE'
 && $GOTM::RESULTS[5][2] eq 'attr:attr2:on_change' );

# Now test the ability of the return code of a callback to abort the execution
# of a sequence of callbacks and invoke the failure callback.
GOTM->initialize();
$GOTM::RETCODE{attr1b_changed} = 0;
$GOTM::RETCODE{attr2_changed} = 0;
$obj1->process();
ok( @GOTM::RESULTS == 4 );
print "# RESULTS has " . scalar(@GOTM::RESULTS) . " items (should have 4)\n"
  if (@GOTM::RESULTS != 4);
ok( $GOTM::RESULTS[0][0] eq 'Object1'
# Callbacks for attr1 stop at attr1b_changed
 && $GOTM::RESULTS[0][1] eq 'attr1a_changed'
 && $GOTM::RESULTS[0][2] eq 'attr:attr1:on_change'
 && $GOTM::RESULTS[1][0] eq 'Object1'
 && $GOTM::RESULTS[1][1] eq 'attr1b_changed'
 && $GOTM::RESULTS[1][2] eq 'attr:attr1:on_change'
# But the failure callback should be invoked
 && $GOTM::RESULTS[2][0] eq 'Object1'
 && $GOTM::RESULTS[2][1] eq 'attr1b_failed'
 && $GOTM::RESULTS[2][2] eq 'attr:attr1:on_change'
# While they stop for attr2_changed on attr2
 && $GOTM::RESULTS[3][0] eq 'Object1'
 && $GOTM::RESULTS[3][1] eq 'attr2_changed'
 && $GOTM::RESULTS[3][2] eq 'attr:attr2:on_change' );

# As a final test of attribute actions, create a new attribute with accessors
# turn on and make sure we can pass in objects and arguments correctly.
GOTM->initialize();
$Games::Object::AccessorMethod = 1;
$obj1->new_attr(
    -name	=> "simple",
    -type	=> "int",
    -value	=> 10,
    -on_change	=> [ 'O:self', 'simple_test', 'O:other', 'O:object', 'A:new' ],
);
eval('$obj1->simple(9);');
ok( $@ eq '' );
print "# DEBUG: \$@ = $@" if ($@);
eval('$obj1->simple(8, $obj2);');
ok( $@ eq '' );
print "# DEBUG: \$@ = $@" if ($@);
eval('$obj1->simple(7, $obj2, $obj3);');
ok( $@ eq '' );
print "# DEBUG: \$@ = $@" if ($@);
eval('$obj1->mod_simple(1);');
ok( $@ eq '' );
print "# DEBUG: \$@ = $@" if ($@);
eval('$obj1->mod_simple(1, $obj2);');
ok( $@ eq '' );
print "# DEBUG: \$@ = $@" if ($@);
eval('$obj1->mod_simple(1, $obj2, $obj3);');
ok( $@ eq '' );
print "# DEBUG: \$@ = $@" if ($@);
ok( @GOTM::RESULTS == 6
 && defined($GOTM::RESULTS[0][0]) && $GOTM::RESULTS[0][0] eq $obj1
 && !defined($GOTM::RESULTS[0][1]) && !defined($GOTM::RESULTS[0][2])
 && $GOTM::RESULTS[0][3] == 9
 && defined($GOTM::RESULTS[1][0]) && $GOTM::RESULTS[1][0] eq $obj1
 && defined($GOTM::RESULTS[1][1]) && $GOTM::RESULTS[1][1] eq $obj2
 && !defined($GOTM::RESULTS[1][2])
 && $GOTM::RESULTS[1][3] == 8
 && defined($GOTM::RESULTS[2][0]) && $GOTM::RESULTS[2][0] eq $obj1
 && defined($GOTM::RESULTS[2][1]) && $GOTM::RESULTS[2][1] eq $obj2
 && defined($GOTM::RESULTS[2][2]) && $GOTM::RESULTS[2][2] eq $obj3
 && $GOTM::RESULTS[2][3] == 7
 && defined($GOTM::RESULTS[3][0]) && $GOTM::RESULTS[3][0] eq $obj1
 && !defined($GOTM::RESULTS[3][1]) && !defined($GOTM::RESULTS[3][2])
 && $GOTM::RESULTS[3][3] == 8
 && defined($GOTM::RESULTS[4][0]) && $GOTM::RESULTS[4][0] eq $obj1
 && defined($GOTM::RESULTS[4][1]) && $GOTM::RESULTS[4][1] eq $obj2
 && !defined($GOTM::RESULTS[4][2])
 && $GOTM::RESULTS[4][3] == 9
 && defined($GOTM::RESULTS[5][0]) && $GOTM::RESULTS[5][0] eq $obj1
 && defined($GOTM::RESULTS[5][1]) && $GOTM::RESULTS[5][1] eq $obj2
 && defined($GOTM::RESULTS[5][2]) && $GOTM::RESULTS[5][2] eq $obj3
 && $GOTM::RESULTS[5][3] == 10 );

# Finally, we test arbitrary object actions. Turn on accessor creation so
# we can eventually test this as well.
$Games::Object::ActionMethod = 1;
my $obj4 = GOTM->new(
    -id		=> "Object4",
    -on_bop	=> [ 
	[ 'O:self', 'bop_func', 'O:other', 'bork', 'A:bup' ],
	[ 'O:self', 'boop_func', 'O:other', 'berk', 'bonk' ],
    ],
    -on_bif	=> [
	[ 'O:self', 'bif_func', 'O:other', 'baff', 'A:bix' ],
	[ 'O:other', 'bif_func', 'O:self', 'boffo', 'borf', 'A:buff' ],
    ],
    -on_zot	=> [ 'O:self', 'zot_func', 'O:other', 'A:zog' ],
);
ok( defined($obj4) );
$man->add($obj4);

# Call actions using the action() method.
GOTM->initialize();
$obj4->action(
    other => $obj3,
    action => 'object:on_bop',
    args => { bup => 'gronk' },
);
$obj4->action(
    other => $obj3,
    action => 'object:on_bif',
    args => { bix => 'grook', buff => 'gag' },
);
$obj4->action(
    other => $obj3,
    action => 'object:on_zot',
    args => { zog => 'yes' },
);
ok( @GOTM::RESULTS == 5
# Action on_bop, callback #1
 && $GOTM::RESULTS[0][0] eq 'Object4'
 && $GOTM::RESULTS[0][1] eq 'bop'
 && $man->id($GOTM::RESULTS[0][2]) eq 'Object3'
 && $GOTM::RESULTS[0][3] eq 'bork'
 && $GOTM::RESULTS[0][4] eq 'gronk'
# Action on_bop, callback #2
 && $GOTM::RESULTS[1][0] eq 'Object4'
 && $GOTM::RESULTS[1][1] eq 'boop'
 && $man->id($GOTM::RESULTS[1][2]) eq 'Object3'
 && $GOTM::RESULTS[1][3] eq 'berk'
 && $GOTM::RESULTS[1][4] eq 'bonk'
# Action on_bif, callback #1
 && $GOTM::RESULTS[2][0] eq 'Object4'
 && $GOTM::RESULTS[2][1] eq 'bif'
 && $man->id($GOTM::RESULTS[2][2]) eq 'Object3'
 && $GOTM::RESULTS[2][3] eq 'baff'
 && $GOTM::RESULTS[2][4] eq 'grook'
# Action on_bif, callback #2
 && $GOTM::RESULTS[3][0] eq 'Object3'
 && $GOTM::RESULTS[3][1] eq 'bif'
 && $man->id($GOTM::RESULTS[3][2]) eq 'Object4'
 && $GOTM::RESULTS[3][3] eq 'boffo'
 && $GOTM::RESULTS[3][4] eq 'borf'
 && $GOTM::RESULTS[3][5] eq 'gag'
# Action on_zot
 && $GOTM::RESULTS[4][0] eq 'Object4'
 && $GOTM::RESULTS[4][1] eq 'zot'
 && $man->id($GOTM::RESULTS[4][2]) eq 'Object3'
 && $GOTM::RESULTS[4][3] eq 'yes' );

# Now do the same, but use the action methods. Use eval() in case something
# went wrong and the methods were not defined.
GOTM->initialize();
eval('$obj4->on_bop($obj3, { bup => "gronk" } );');
ok( $@ eq '' );
print "# DEBUG: \$@ = $@" if ($@);
eval('$obj4->on_bif($obj3, { bix => "grook", buff => "gag" } );');
ok( $@ eq '' );
print "# DEBUG: \$@ = $@" if ($@);
eval('$obj4->on_zot($obj3, { zog => "yes" } );');
ok( $@ eq '' );
print "# DEBUG: \$@ = $@" if ($@);
ok( @GOTM::RESULTS == 5
# Action on_bop, callback #1
 && $GOTM::RESULTS[0][0] eq 'Object4'
 && $GOTM::RESULTS[0][1] eq 'bop'
 && $man->id($GOTM::RESULTS[0][2]) eq 'Object3'
 && $GOTM::RESULTS[0][3] eq 'bork'
 && $GOTM::RESULTS[0][4] eq 'gronk'
# Action on_bop, callback #2
 && $GOTM::RESULTS[1][0] eq 'Object4'
 && $GOTM::RESULTS[1][1] eq 'boop'
 && $man->id($GOTM::RESULTS[1][2]) eq 'Object3'
 && $GOTM::RESULTS[1][3] eq 'berk'
 && $GOTM::RESULTS[1][4] eq 'bonk'
# Action on_bif, callback #1
 && $GOTM::RESULTS[2][0] eq 'Object4'
 && $GOTM::RESULTS[2][1] eq 'bif'
 && $man->id($GOTM::RESULTS[2][2]) eq 'Object3'
 && $GOTM::RESULTS[2][3] eq 'baff'
 && $GOTM::RESULTS[2][4] eq 'grook'
# Action on_bif, callback #2
 && $GOTM::RESULTS[3][0] eq 'Object3'
 && $GOTM::RESULTS[3][1] eq 'bif'
 && $man->id($GOTM::RESULTS[3][2]) eq 'Object4'
 && $GOTM::RESULTS[3][3] eq 'boffo'
 && $GOTM::RESULTS[3][4] eq 'borf'
 && $GOTM::RESULTS[3][5] eq 'gag'
# Action on_zot
 && $GOTM::RESULTS[4][0] eq 'Object4'
 && $GOTM::RESULTS[4][1] eq 'zot'
 && $man->id($GOTM::RESULTS[4][2]) eq 'Object3'
 && $GOTM::RESULTS[4][3] eq 'yes' );
print "# DEBUG: RESULTS = " . scalar(@GOTM::RESULTS) . " (expected 5)\n"
  if (@GOTM::RESULTS != 5);

# Now do the same in the "active" sense, which means using the "verb" form
# on other instead of self.
GOTM->initialize();
eval('$obj3->bop($obj4, { bup => "gronk" } );');
ok( $@ eq '' );
print "# DEBUG: \$@ = $@" if ($@);
eval('$obj3->bif($obj4, { bix => "grook", buff => "gag" } );');
ok( $@ eq '' );
print "# DEBUG: \$@ = $@" if ($@);
eval('$obj3->zot($obj4, { zog => "yes" } );');
ok( $@ eq '' );
print "# DEBUG: \$@ = $@" if ($@);
ok( @GOTM::RESULTS == 5
# Action on_bop, callback #1
 && $GOTM::RESULTS[0][0] eq 'Object4'
 && $GOTM::RESULTS[0][1] eq 'bop'
 && $man->id($GOTM::RESULTS[0][2]) eq 'Object3'
 && $GOTM::RESULTS[0][3] eq 'bork'
 && $GOTM::RESULTS[0][4] eq 'gronk'
# Action on_bop, callback #2
 && $GOTM::RESULTS[1][0] eq 'Object4'
 && $GOTM::RESULTS[1][1] eq 'boop'
 && $man->id($GOTM::RESULTS[1][2]) eq 'Object3'
 && $GOTM::RESULTS[1][3] eq 'berk'
 && $GOTM::RESULTS[1][4] eq 'bonk'
# Action on_bif, callback #1
 && $GOTM::RESULTS[2][0] eq 'Object4'
 && $GOTM::RESULTS[2][1] eq 'bif'
 && $man->id($GOTM::RESULTS[2][2]) eq 'Object3'
 && $GOTM::RESULTS[2][3] eq 'baff'
 && $GOTM::RESULTS[2][4] eq 'grook'
# Action on_bif, callback #2
 && $GOTM::RESULTS[3][0] eq 'Object3'
 && $GOTM::RESULTS[3][1] eq 'bif'
 && $man->id($GOTM::RESULTS[3][2]) eq 'Object4'
 && $GOTM::RESULTS[3][3] eq 'boffo'
 && $GOTM::RESULTS[3][4] eq 'borf'
 && $GOTM::RESULTS[3][5] eq 'gag'
# Action on_zot
 && $GOTM::RESULTS[4][0] eq 'Object4'
 && $GOTM::RESULTS[4][1] eq 'zot'
 && $man->id($GOTM::RESULTS[4][2]) eq 'Object3'
 && $GOTM::RESULTS[4][3] eq 'yes' );
print "# DEBUG: RESULTS = " . scalar(@GOTM::RESULTS) . " (expected 5)\n"
  if (@GOTM::RESULTS != 5);

exit(0);
