# -*- perl -*-

# Basic object creation tests

use strict;
use warnings;
use Test;
use Games::Object;
use Games::Object::Manager;

BEGIN { $| = 1; plan tests => 25 }

# Create manager.
my $man = Games::Object::Manager->new();
ok( defined($man) );

# Basic object creation with specific IDs
my $obj1 = Games::Object->new(-id => "ThisObject");
ok( defined($obj1) && $man->add($obj1) );
my $obj2 = Games::Object->new(-id => "ThatObject");
ok( defined($obj2) && $man->add($obj2) );
ok( $obj1->id() eq 'ThisObject' && $obj2->id() eq 'ThatObject' );

# Using the manager id() method.
ok( $man->id('ThisObject') eq 'ThisObject'
 && $man->id('ThatObject') eq 'ThatObject' );
ok( !defined($man->id('NoObject')) );

# id() method with assertion
ok( $man->id('ThisObject', 1) eq 'ThisObject' );
eval('$man->id("NoObject", 1);');
ok( $@ =~ /Assertion failed: 'NoObject' is not a valid\/managed object/ );

# The manager find() method
my $find1 = $man->find('ThisObject');
ok( defined($find1) && ref($find1) eq 'Games::Object'
	&& $find1->id() eq 'ThisObject' );
my $find2 = $man->find('ThatObject');
ok( defined($find2) && ref($find2) eq 'Games::Object'
	&& $find2->id() eq 'ThatObject' );
ok ( !$man->find('BogusObject') );

# The manager find() method with assertion
my $find3;
ok( !defined(eval('$find3 = $man->find("BogusObject", 1);')) );
ok( $@ =~ /Assertion failed: 'BogusObject' is not a valid\/managed object ID/ );

# Basic object creation with derived IDs.
my $obj3 = Games::Object->new();
ok( defined($obj3) && defined($man->add($obj3)) );
my $obj4 = Games::Object->new();
ok( defined($obj4) && defined($man->add($obj4)) );
ok( defined($obj3->id())
 && defined($obj4->id())
 && $obj3->id() ne $obj4->id() );

# Defining object IDs at time of add.
my $obj5 = Games::Object->new();
my $obj6 = Games::Object->new();
eval('$man->add($obj5, "DefineOnAdd1");');
ok( $@ eq '' );
print "# DEBUG: \$@ = $@" if ($@);
eval('$man->add($obj6, "DefineOnAdd2");');
ok( $@ eq '' );
print "# DEBUG: \$@ = $@" if ($@);
ok( $obj5->id() eq 'DefineOnAdd1' && $obj6->id() eq 'DefineOnAdd2' );

# Override object IDs already defined on object when added.
my $obj7 = Games::Object->new(-id => "MyId1");
my $obj8 = Games::Object->new(-id => "MyId2");
ok( $obj7 && $obj7->id() eq 'MyId1' && $obj8 && $obj8->id() eq 'MyId2' );
eval('$man->add($obj7, "NewId1");');
ok( $@ eq '' );
print "# DEBUG: \$@ = $@" if ($@);
eval('$man->add($obj8, "NewId2");');
ok( $@ eq '' );
print "# DEBUG: \$@ = $@" if ($@);
ok( $obj7->id() eq 'NewId1' && $obj8->id() eq 'NewId2' );

# Final test of add(): Make sure we can find all objects added (and not find
# the ones that we didn't or overrided)
ok( defined($man->find('DefineOnAdd1'))
 && $man->find('DefineOnAdd1')->id() eq 'DefineOnAdd1'
 && defined($man->find('DefineOnAdd2'))
 && $man->find('DefineOnAdd2')->id() eq 'DefineOnAdd2'
 && defined($man->find('NewId1'))
 && $man->find('NewId1')->id() eq 'NewId1'
 && defined($man->find('NewId2'))
 && $man->find('NewId2')->id() eq 'NewId2'
 && !defined($man->find('MyId1'))
 && !defined($man->find('MyId2')) );

# Error check: Duplicate IDs.
my $obj9 = Games::Object->new(-id => "ThatObject");
eval('$man->add($obj9, "ThatObject");');
ok ( $@ =~ /Attempt to add duplicate object/ );

exit (0);
