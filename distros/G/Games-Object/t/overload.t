# -*- perl -*-

# Overloaded operators

use strict;
use warnings;
use Test;

BEGIN { $| = 1; plan tests => 58 }

use Games::Object::Manager;
use Games::Object;

my ($rc, $obj1, $obj2, $obj1_other, $obj2_other);

sub try_this
{
	my $expr = shift;
	eval($expr);
	ok( $@ eq '' );
	print "# eval() failure: $@\n" if ($@);
	ok( $rc );
}

# Create two objects for testing purposes.
$obj1 = Games::Object->new(-id => "TestObject1");
$obj1->priority(10);
$obj2 = Games::Object->new(-id => "TestObject2");
$obj2->priority(5);
ok( defined($obj1) );
ok( defined($obj2) );
my $man = Games::Object::Manager->new();
$man->add($obj1);
$man->add($obj2);

# Obtain new references for these.
$obj1_other = $man->find("TestObject1");
$obj2_other = $man->find("TestObject2");
ok( defined($obj1_other) );
ok( defined($obj2_other) );

# Perform object-object tests
try_this('$rc = ( $obj1 eq $obj1_other )');
try_this('$rc = ( $obj2 eq $obj2_other )');
try_this('$rc = ( $obj1 ne $obj2_other )');
try_this('$rc = ( $obj2 ne $obj1_other )');
try_this('$rc = ( $obj2 gt $obj1_other )');

# Perform tests between objects and strings
try_this('$rc = ( $obj1 eq "TestObject1" )');
try_this('$rc = ( $obj2 eq "TestObject2" )');
try_this('$rc = ( $obj1 ne "TestObject2" )');
try_this('$rc = ( $obj2 ne "TestObject1" )');
try_this('$rc = ( $obj2 gt "TestObject1" )');

# Now the same, but reversed, to make sure args get re-swapped properly
try_this('$rc = ( "TestObject1" eq $obj1 )');
try_this('$rc = ( "TestObject2" eq $obj2 )');
try_this('$rc = ( "TestObject2" ne $obj1 )');
try_this('$rc = ( "TestObject1" ne $obj2 )');
try_this('$rc = ( "TestObject1" lt $obj2 )');

# Now do the numeric tests.
try_this('$rc = ( $obj1 == $obj1_other )');
try_this('$rc = ( $obj1 != $obj2_other )');
try_this('$rc = ( $obj1 > $obj2_other )');
try_this('$rc = ( $obj2 < $obj1_other )');
try_this('$rc = ( $obj1 == 10 )');
try_this('$rc = ( $obj1 != 5 )');
try_this('$rc = ( $obj1 > 5 )');
try_this('$rc = ( $obj2 < 10 )');
try_this('$rc = ( 10 == $obj1 )');
try_this('$rc = ( 5 != $obj1 )');
try_this('$rc = ( 5 < $obj1 )');
try_this('$rc = ( 10 > $obj2 )');


