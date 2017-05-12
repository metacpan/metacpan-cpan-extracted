# -*- perl -*-

# Attribute inheritance processing.

use strict;
use warnings;
use Test;
use Games::Object qw(ATTR_STATIC ATTR_NO_INHERIT FLAG_NO_INHERIT);
use Games::Object::Manager;

BEGIN { $| = 1; plan tests => 46 }

# Create two objects and parent one to the other.
my $man = Games::Object::Manager->new();
my $pobj = Games::Object->new(-id => "ParentObject");
ok( $pobj );
my $cobj = Games::Object->new(-id => "ChildObject");
ok( $cobj );
$man->add($pobj);
$man->add($cobj);
eval('$man->inherit($pobj, $cobj)');
ok( $@ eq '' );
print "# DEBUG: \$@ = $@" if ($@);
my $test = $man->inheriting_from($cobj);
ok( ref($test) eq 'Games::Object' && $test->id() eq $pobj->id() );

# Create some attributes and flags on the parent.
eval('$pobj->new_attr(
	-name	=> "FeelFree",
	-type	=> "int",
	-value	=> 10)');
ok( $@ eq '' );
eval('$pobj->new_flag(
	-name	=> "FlagFeelFree",
	-value	=> 1)');
ok( $@ eq '' );
print "# DEBUG: \$@ = $@" if ($@);
eval('$pobj->new_attr(
	-name	=> "CantTouchThis",
	-type	=> "int",
	-flags	=> ATTR_STATIC,
	-value	=> 20)');
ok( $@ eq '' );
print "# DEBUG: \$@ = $@" if ($@);
eval('$pobj->new_attr(
	-name	=> "MineMineMine",
	-type	=> "int",
	-flags	=> ATTR_NO_INHERIT,
	-value	=> 30)');
ok( $@ eq '' );
print "# DEBUG: \$@ = $@" if ($@);
eval('$pobj->new_attr(
	-name	=> "FlagMineMineMine",
	-flags	=> FLAG_NO_INHERIT,
	-value	=> 1)');
ok( $@ eq '' );
print "# DEBUG: \$@ = $@" if ($@);

# All but the last should appear to exist on the child.
ok( $cobj->attr_exists("FeelFree") );
ok( $cobj->attr_exists("CantTouchThis") );
ok( !$cobj->attr_exists("MineMineMine") );

# Should be able to see the first flag but not the second
ok( $cobj->is("FlagFeelFree") );
ok( !$cobj->is("FlagMineMineMine") );

# And they should report proper values from the child.
ok( $cobj->attr("FeelFree") == 10 );
ok( $cobj->attr("CantTouchThis") == 20 );
ok( !defined($cobj->attr("MineMineMine")) );

# And none should be shown to actually physically exist on the child.
ok( !$cobj->attr_exists_here("FeelFree") );
ok( !$cobj->attr_exists_here("CantTouchThis") );
ok( !$cobj->attr_exists_here("MineMineMine") );

# Clear flag on parent. Child should now report it cleared.
eval('$pobj->clear("FlagFeelFree")');
ok( $@ eq '' );
print "# DEBUG: \$@ = $@" if ($@);
ok( !$cobj->is("FlagFeelFree") );

# Put a modifier on one of the attributes for the parent and process it. We
# should see the new value from the child. It should still exist only
# "superficially" on the child.
eval('$pobj->mod_attr(
	-name	=> "FeelFree",
	-modify	=> 1,
	-incremental => 1,
	-persist_as => "FeelFreeMod")');
ok( $@ eq '' );
print "# DEBUG: \$@ = $@" if ($@);
$pobj->process();
ok( $cobj->attr("FeelFree") == 11 );
ok( $cobj->attr_exists("FeelFree") );
ok( !$cobj->attr_exists_here("FeelFree") );

# Modify the same attribute on the child. We should see the new value on the
# child and continue to see the old value on the parent. It should now REALLY
# exist on the child.
eval('$cobj->mod_attr(
	-name	=> "FeelFree",
	-modify	=> 5)');
ok( $@ eq '' );
print "# DEBUG: \$@ = $@" if ($@);
ok( $cobj->attr("FeelFree") == 16 );
ok( $pobj->attr("FeelFree") == 11 );
ok( $cobj->attr_exists("FeelFree") );
ok( $cobj->attr_exists_here("FeelFree") );

# Process the parent object. It should change, child attribute should not.
$pobj->process();
ok( $cobj->attr("FeelFree") == 16 );
ok( $pobj->attr("FeelFree") == 12 );

# Create a third object, make it the child of the child. It should see
# FeelFree from the child, CantTouchThis from the parent, and MineMineMine
# not at all.
my $gobj = Games::Object->new(-id => "GrandChildObject");
$man->add($gobj);
ok( $gobj );
eval('$man->inherit($cobj, $gobj)');
ok( $@ eq '' );
print "# DEBUG: \$@ = $@" if ($@);
ok( $gobj->attr("FeelFree") == 16 );
ok( $gobj->attr("CantTouchThis") == 20 );
ok( !defined($gobj->attr("MineMineMine")) );

# Delete the attribute from the child. We should again see the parent attribute.
eval('$cobj->del_attr("FeelFree")');
ok( $@ eq '' );
print "# DEBUG: \$@ = $@" if ($@);
ok( $cobj->attr("FeelFree") == 12 );
ok( $cobj->attr_exists("FeelFree") );
ok( !$cobj->attr_exists_here("FeelFree") );

# And the grandchild should see it too.
ok( $gobj->attr("FeelFree") == 12 );

# An attempt to set the static, inherited attribute should fail.
eval('$cobj->mod_attr(
	-name	=> "CantTouchThis",
	-modify	=> 5)');
ok( $@ =~ /attempt to modify static/i );
eval('$gobj->mod_attr(
	-name	=> "CantTouchThis",
	-modify	=> 5)');
ok( $@ =~ /attempt to modify static/i );

# Save this test for last, since if it fails, other tests may cause
# infinite loops. Make sure we can't incur a circular parent list.
eval('$man->inherit($gobj, $pobj)');
ok( $@ =~ /Relating ParentObject to GrandChildObject in manner inherit would create a circular relationship/i );

