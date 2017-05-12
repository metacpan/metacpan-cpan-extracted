#!/usr/bin/perl
use strict;
no strict 'subs';
use lib '..';
use Java;

my $java = new Java();

my $obj = $java->create_object("com.zzo.javaserver.Test","mark");
my $frame = $java->create_object("java.awt.Frame","Frame #1");
$frame->setSize(200,300);

my $val =  $obj->get->get_value;
print "VAL: $val\n";
my $obj2 = $java->create_object("com.zzo.javaserver.Test",undef);
my $val2 =  $obj2->get;
print "VAL2 is NULL\n" if (!defined $val2);
my $obj3 = $java->create_object("com.zzo.javaserver.Test");
my $val3 =  $obj3->get->get_value;
print "VAL3: $val3\n";
#exit;
#my $class = $java->java_lang_Class("forName","Test");
#my $constructors = $class->getConstructors();
#my $v = $constructors->{name};
#my $test_obj = $class->newInstance();
#my $val = $test_obj->get->get_value;
#print "GOT: $obj $val\n";

