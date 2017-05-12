#!/usr/local/bin/perl
use strict;
use lib '..';
no strict 'subs';
use Java;

my $java = new Java();

#my $obj = $java->create_object("thot.Test","mark");
#print $obj->get->get_value;
#exit;
my $class = $java->java_lang_Class("forName","com.zzo.javaserver.Test2");
my $constructors = $class->getConstructors();
#my $v = $constructors->name;
my $test_obj = $class->newInstance();
my $val = $test_obj->get->get_value;
my $v;
print "GOT: $v $val\n";

# use new 'call' method
my $val2 = $test_obj->call("get_string")->get_value;
print "GOT: $val2\n";

# use new 'smart' Autoloading  - note function name has '_' in it!
my $val4 = $test_obj->get_string->get_value;
print "GOT: $val4\n";

my $val5 = $test_obj->getPTEST;
print $val5->next->get_value, "\n";

