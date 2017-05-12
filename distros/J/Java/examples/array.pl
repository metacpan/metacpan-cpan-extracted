#!/home/markt/bin/perl -w
use strict;
no strict 'subs';
use lib '..';
use Java;

#
# Using NEW array interface!!
#

my $java = new Java(use_tied_arrays=>1,
#			event_port=>'-1',
#			authfile=>"secret"
			);
#my $java = new Java;

my $array = $java->create_array("java.lang.String",5);
my $ll = $#{$array};
my $l2 = scalar(@$array);
print "$ll\t$l2\n";
$array->[3] = "Mark Rulez";
$array->[0] = "This sux";
my $len = @$array;
my $vv =  $array->[3]->get_value;
my $vvv =  $array->[0]->get_value;
print "ARRAY: 3 $vv 0 $vvv $len\n";
$array->[3] = undef;
print "Array 3 is NULL\n" if (!$array->[3]);

my $char_array = $java->create_array("java.lang.Integer",100);
for (my $i = 0; $i < @$char_array; $i++)
{
        $char_array->[$i] = $java->create_object("java.lang.Integer",$i);
}

my $class = $java->java_lang_Class("forName","com.zzo.javaserver.Test");
my $constructor_array = $class->getConstructors();
for (my $i = 0; $i < @$constructor_array; $i++)
{
	my $cons = $constructor_array->[$i]->get_value;
	print "Constructor $i: $cons\n";
}

$array->[0] = "Item 1";
$array->[1] = "Item 2";
$array->[2] = "Item 3";
$array->[3] = "Item 4";
$array->[4] = "Item 5";
my $list = $java->java_util_Arrays("asList",$array);
print $list->get_value,"\n";
my $ln= $java->java_util_Arrays("asList",$char_array);
print $ln->get_value,"\n";


## Primitive array
my $prim_array = $java->create_array("int",3);
$prim_array->[2] = 0;

my @tied_array;
my $test_obj = $java->create_object("com.zzo.javaserver.Test","Mark Rox");
print "Created Test object ",$test_obj->get->get_value,"\n";
my $arr = $test_obj->getArr;
for (my $i = 0; $i < @$arr; $i++)
{
	print "Val is ",$arr->[$i]->get_value,"\n";
}



# NEW [Ljava.lang.reflect.Constructor;(5 (,34,2,3,2))
# GET [Ljava.lang.reflect.Constructor;^3#2
# SET [Ljava.lang.reflect.Constructor;^3#(<object>)
# GET [Ljava.lang.reflect.Constructor;^3#len	== get length
