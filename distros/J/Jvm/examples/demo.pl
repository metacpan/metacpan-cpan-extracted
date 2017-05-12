#!/usr/bin/perl -w
#Ident = $Id: demo.pl,v 1.4 2001/09/08 06:34:28 yw Exp $

use ExtUtils::testlib;
use strict;
use Jvm;
#specify the CLASSPATH if .class is not in current directory
#$Jvm::CLASSPATH="./"; 

new Jvm();
print sprintf("version:%x\n\n", Jvm::getVersion());

ts_obj();
ts_return_array();
ts_sleep();
ts_getProperty();
ts_setProperty();
ts_string();
ts_static_method();
ts_static_method2();
ts_static_method3();
ts_create_object();
ts_manipulate_Vector();
ts_static_member();
ts_pass_array();
ts_static_return_array();

print "\nComplete!\n";

sub ts_obj {
    print "Testing Object ...\n";
    my $obj = new Jvm("Prog","(ILjava/lang/String;)V", 1122, "Test Object!");
    #print "got: $obj\n";
    my $ret=$obj->test_obj_boolean("(ILjava/lang/String;)Z", 8899, "Test Object Boolean!");
    print "got: $ret\n\n";
}

sub ts_return_array {
    print "Invoking Prog::retArray2() to return an java.lang.String arrray ...\n";
    my $obj2=new Jvm("Prog", "()V");
    my @s=$obj2->retStrArray("()[Ljava/lang/String;");
    print "got:", join(",", @s), "\n\n";
}

sub ts_sleep {
    print "Testing java.lang.Thread.sleep() ...\n";
  Jvm::call("java.lang.Thread", "sleep", "(J)V", 1000);
    print "done\n\n";
}

sub ts_getProperty {
    print "Testing get property...\n";
    my $obj=Jvm::getProperty("java.lang.System","out","Ljava/io/PrintStream;");
    #print "field: $obj\n";
    $obj->println("(Ljava/lang/Object;)V", Jvm::newStringUTF("Hello world!"));
    print "done\n\n";
}

sub ts_setProperty {
    print "Testing set property...\n";
    #my $t=new Jvm("Prog","(ILjava/lang/String;)V", 100, "Hello");
  Jvm::setProperty("Prog", "s_bID", "B", 10);
    print "got: ", Jvm::getProperty("Prog", "s_bID", "B"), "\n\n";
}

sub ts_string {
    print "Testing string...\n";
    my $jstr = Jvm::newStringUTF("From Perl!");
    #print "str: $jstr\n";
    print "got: ". $jstr->getString() ."\n\n";
}

sub ts_static_method {
    print "Test java.lang.String.parseInt() ...\n";
    my $i = Jvm::call("java.lang.Integer", "parseInt", "(Ljava/lang/String;)I", "88999");
    print "got: $i\n\n";
}


sub ts_static_method2 {
    print "Testing static member call...\n";
    my $ret=Jvm::call("Prog", "test_boolean", '(ZILjava/lang/String;)Z', 1, "9988", "Hello boolean!");
    print "got: $ret\n\n";
}


sub ts_static_method3 {
    print "Testing static method ...\n";
    my $obj = new Jvm("Prog", "()V");
    #print "obj: $obj\n";
    print $obj->toString("()Ljava/lang/String;"), "\n";
    print Jvm::call("Prog", "s_toString", "()Ljava/lang/String;"), "\n";
    print "done\n\n";
}

sub ts_static_member {
    print "Testing set/get static member ...\n";
  Jvm::setProperty("Prog", "s_id", "Ljava/lang/String;", "Test Static Member!");
    print "got: ", Jvm::getProperty("Prog", "s_id", "Ljava/lang/String;"), "\n\n";
}

sub ts_create_object {
    print "Testing create Objects ...\n";
    my $obj = new Jvm("Prog", "(ILjava/lang/String;)V", 12345, "Create Object!");
    print "got obj 1: $obj\n";

    my $obj2 = new Jvm("Prog", "(LProg;)V", $obj);
    print "got obj 2: $obj2\n\n";
}

sub ts_manipulate_Vector {
    print "Testing manipulate Vector ...\n";
    my $vec = new Jvm("java.util.Vector", "()V");
    #print "$vec\n";
    my $b1 = $vec->add("(Ljava/lang/Object;)Z", new Jvm("java.lang.Integer", "(I)V","88"));
    print "vec: $vec\n";
    my $b2 = $vec->add("(Ljava/lang/Object;)Z", new Jvm("java.lang.Integer", "(I)V", "99"));
    my $b3 = $vec->add("(Ljava/lang/Object;)Z", Jvm::newStringUTF("Hello world!"));
    #print "$b1\n";
    #print "$b2\n";
    
  Jvm::dump($vec);
    print "done\n\n";
}


# test pass boolean ARRAY
sub ts_pass_array {
    print "Testing pass an array ...\n";
    Jvm::call("Prog", "getArray", "([Ljava/lang/String;)V",[0,9.98,7,0,1,"Hello"]);
    print "done\n\n";
}

sub ts_static_return_array {
    print "Testing return an array ...\n";
    print "got: ", join(",", Jvm::call("Prog", "staticRetStrArray", "()[Ljava/lang/String;")), "\n\n";
}
