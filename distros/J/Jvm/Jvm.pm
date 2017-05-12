#!/usr/bin/perl -w
# Copyright (c) 2000 Ye, wei. 
# All rights reserved. 
# This program is free software; you can redistribute it and/or 
# modify it under the same terms as Perl itself. 
#
# Ident = $Id: Jvm.pm,v 1.20 2001/09/08 07:03:37 yw Exp $

#############################
package jobject;
#############################

use strict;
use vars qw($AUTOLOAD);


#invoke an object's method.
sub invoke {
    my($obj, $methodName, $methodSig, @args) = @_;

    if(! $methodName) {
	die "Error: missing method!";
    }
    if(! $methodSig) {
	die "Error: missing methodSignature!";
    }

    my $cls = $obj->getObjectClass();
    if(! $cls) {
	die "Failed to getObjectClass()!";
    }
    Jvm::DEBUG("CLS: $cls");

    my $mid = $cls->getMethodID($methodName, $methodSig);
    if(! $mid) {
	die "Failed to get instance methodID for '$methodName($methodSig)'!";
    }
    Jvm::DEBUG("Method: $mid");

    my(@sig) = Jvm::_parseSig($methodSig);

    # Take out the return type.
    my($returnType) = pop(@sig);

    if(scalar(@sig) != scalar(@args)) {
	die "Error: The count of Signatures doesn't match that of Arguments!";
    }

    #Convert Perl args to Java args.
    my $_args = Jvm::_createArgs(\@sig, \@args);

    #Jvm::DEBUG("Args:$_args") if defined $_args;

    my $ret = undef;
    if($returnType eq "Z") {
	$ret = $obj->callBooleanMethod($mid, $_args);
    } elsif($returnType eq "B") {
	$ret = $obj->callByteMethod($mid, $_args);
    } elsif($returnType eq "C") {
	$ret = $obj->callCharMethod($mid, $_args);
    } elsif($returnType eq "S") {
	$ret = $obj->callShortMethod($mid, $_args);
    } elsif($returnType eq "I") {
	$ret = $obj->callIntMethod($mid, $_args);
    } elsif($returnType eq "J") {
	$ret = $obj->callLongMethod($mid, $_args);
    } elsif($returnType eq "F") {
	$ret = $obj->callFloatMethod($mid, $_args);
    } elsif($returnType eq "D") {
	$ret = $obj->callDoubleMethod($mid, $_args);
    } elsif($returnType eq "V") {
	$obj->callVoidMethod($mid, $_args);
    } elsif($returnType =~/^L/) {
	$ret = $obj->callObjectMethod($mid, $_args);

	if($returnType eq 'Ljava/lang/String;') {

	    ##########################################
	    # Now that the return string is 'jstring',
	    # we FORCE it('jobject') to 'jstring'.
	    ##########################################
	    bless $ret, "jstring";

	    $ret = $ret->getString();
	    Jvm::DEBUG("Return a string:$ret");
	}
    } elsif($returnType=~/^\[/) {
	$ret = $obj->callObjectMethod($mid, $_args);
	bless $ret, "jobject";
	# convert jobjectArray to Perl Array 
	$ret = Jvm::returnArray($returnType, $ret);
	return (@{$ret});
    } else {
	die "unknown return Type: '$returnType'";
    }

    return $ret;
}

sub AUTOLOAD {
    my($obj, @args) = @_;

    my $api = $AUTOLOAD;
    $api =~s/.*:://;

    if($api!~/DESTROY/) {
	Jvm::DEBUG("API: $api");
	invoke($obj, $api, @args);
    }
}

##############################
package Jvm;
##############################

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $DEBUG $CLASSPATH $LIBPATH);

require Exporter;
require DynaLoader;
require AutoLoader;

$DEBUG = 0;
$CLASSPATH = "."; #just to get rid of "-w" warnings.
$LIBPATH   = ".";

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = '0.9.2';

bootstrap Jvm $VERSION;

# Preloaded methods go here.

sub new {
    my($pkg, $className, $methodSig, @args) = @_;

    #Jvm::DEBUG("PKG: $pkg, CLASSNAME: $className, METHOD: $methodSig");

    if(_initJVM() < 0) {
	croak("Init Jvm() failed!");
    }

    if($className) {
	if(! $methodSig) {
	    die "Error: missing constructor signature!";
	}

	my(@sig) = _parseSig($methodSig);

	my($returnType) = pop(@sig);
	my $_args = _createArgs(\@sig, \@args);
	
	my $cls = findClass($className);
	if(! $cls) {
	    die "Failed to find class '$className'";
	}

	my $mid = $cls->getMethodID("<init>", $methodSig);
	if(! $mid) {
	    die "Failed to get method ID for '$methodSig'!";
	}
	return $cls->newObject($mid, $_args);
    } 

}


sub call {
    my($className, $methodName, $methodsig, @args) = @_;

    if(! $className) {
	die "Error: missing class name!";
    }
    if(! $methodName) {
	die "Error: missing method name!";
    }
    if(! $methodsig) {
	die "Error: missing method signature!";
    }


    my $class = findClass($className);
    if(! $class) {
	die "find class failed";
    }
    Jvm::DEBUG("Cls: $class");

    my $mid = $class->getStaticMethodID($methodName, $methodsig);
    if(! $mid) {
	die "find static methodID failed";
    }
    Jvm::DEBUG("Method: $mid");

    my(@sig) = _parseSig($methodsig);

    my($returnType) = pop(@sig);

    if(scalar(@sig) != scalar(@args)) {
	die "Error: The count of Signatures doesn't match that of Arguments!";
    }

    my $_args = _createArgs(\@sig, \@args);

    Jvm::DEBUG("args: $_args");

    my $ret = undef;
    if($returnType eq "Z") {
	$ret = $class->callStaticBooleanMethod($mid, $_args);
    } elsif($returnType eq "B") {
	$ret = $class->callStaticByteMethod($mid, $_args);
    } elsif($returnType eq "C") {
	$ret = $class->callStaticCharMethod($mid, $_args);
    } elsif($returnType eq "S") {
	$ret = $class->callStaticShortMethod($mid, $_args);
    } elsif($returnType eq "I") {
	$ret = $class->callStaticIntMethod($mid, $_args);
    } elsif($returnType eq "J") {
	$ret = $class->callStaticLongMethod($mid, $_args);
    } elsif($returnType eq "F") {
	$ret = $class->callStaticFloatMethod($mid, $_args);
    } elsif($returnType eq "D") {
	$ret = $class->callStaticDoubleMethod($mid, $_args);
    } elsif($returnType eq "V") {
	$ret = $class->callStaticVoidMethod($mid, $_args);
    } elsif($returnType =~/^L/) {
	$ret = $class->callStaticObjectMethod($mid, $_args);
	if($returnType eq 'Ljava/lang/String;') {
	    bless $ret, "jstring";
	    $ret = $ret->getString();
	} else {
	    # return the java object.
	}
    } elsif($returnType=~/\[/) {
	$ret = $class->callStaticObjectMethod($mid, $_args);
	bless $ret, "jobject";
	# convert jobjectArray to Perl Array 
	$ret = Jvm::returnArray($returnType, $ret);
	return (@{$ret});
    } else {
	die "unknown return Type: '$returnType'";
    }

    return $ret;
}

# Input       : "(ILjava/lang/String;)V"
# Return Array: ("I", "Ljava/lang/String;", "V")
#               The last one is return type.
sub _parseSig {
    my($sig) = @_;
    my(@in, $out);
    if($sig=~/^\((.*)\)(.+)$/) {
	@in    = _parseTypes($1);
	($out) = _parseTypes($2);
    } else {
	die "unrecorgnized sig '$sig'";
    }
    return (@in, $out);
}

sub _parseTypes {
    my($sig) = @_;
    my @arg;

    # This type is only available for return type.
    # means 'void'
    if($sig eq "V") { 
	return $sig;
    }

    while($sig) {
	if($sig=~/^((\[)?([ZBCSIJFD]|L[^;]+;))(.*)/) {
	    $sig = $4;

	    #no warnings;
	    #push(@arg, "$2$3");

	    #my $s = "";
	    #if(defined $2) { $s .= $2; }
	    #if(defined $3) { $s .= $3; }

	    push (@arg, $1);
	} else {
	    die "un-recorgnized sig: $sig\n";
	}
    }
    return @arg;
}

sub getProperty {
    my($className, $fieldName, $sig) = @_;

    if(! $sig) {
	die "Error: missing signature!";
    }

    my $cls = Jvm::findClass($className);
    if(! $cls) {
	die "Failed to get class '$className'!";
    }

    my $fld = $cls->getStaticFieldID($fieldName, $sig);
    if(! $fld) {
	die "Failed to get static Field ID '$fieldName($sig)'!";
    }

    my $ret;
    if($sig eq "Z") {
	$ret = $cls->getStaticBooleanField($fld);
    } elsif($sig eq "B") {
	$ret = $cls->getStaticByteField($fld);
    } elsif($sig eq "C") {
	$ret = $cls->getStaticCharField($fld);
    } elsif($sig eq "S") {
	$ret = $cls->getStaticShortField($fld);
    } elsif($sig eq "I") {
	$ret = $cls->getStaticIntField($fld);
    } elsif($sig eq "J") {
	$ret = $cls->getStaticLongField($fld);
    } elsif($sig eq "F") {
	$ret = $cls->getStaticFloatField($fld);
    } elsif($sig eq "D") {
	$ret = $cls->getStaticDoubleField($fld);
    } elsif($sig eq "V") {
	die "Error: couldn't get a *Void* field!";
    } elsif($sig =~/^L/) {
	$ret = $cls->getStaticObjectField($fld);
	if($sig eq 'Ljava/lang/String;') {
	    bless $ret, "jstring";
	    $ret=$ret->getString();
	}
    } else {
	die "unknown sig '$sig'";
    }

    return $ret;
}

sub setProperty {
    my($className, $fieldName, $sig, $value) = @_;

    if(! $sig) {
	die "Error: missing signature!";
    }
    if(! defined $value) {
	die "Error: missing value!";
    }

    my $cls = Jvm::findClass($className);
    if(! $cls) {
	die "Failed to find class '$className'!";
    }
    Jvm::DEBUG("Cls: $cls");
   
    my $fld = $cls->getStaticFieldID($fieldName, $sig);
    if(! $fld) {
	die "Failed to find static field ID for '$fieldName($sig)'!";
    }
    Jvm::DEBUG("FLD: $fld");

    if($sig eq "Z") {
	$cls->setStaticBooleanField($fld, $value);
    } elsif($sig eq "B") {
	$cls->setStaticByteField($fld, $value);
    } elsif($sig eq "C") {
	$cls->setStaticCharField($fld, $value);
    } elsif($sig eq "S") {
	$cls->setStaticShortField($fld, $value);
    } elsif($sig eq "I") {
	$cls->setStaticIntField($fld, $value);
    } elsif($sig eq "J") {
	$cls->setStaticLongField($fld, $value);
    } elsif($sig eq "F") {
	$cls->setStaticFloatField($fld, $value);
    } elsif($sig eq "D") {
	$cls->setStaticDoubleField($fld, $value);
    } elsif($sig eq "V") {
	die "Error: couldn't set a *Void* field!";
    } elsif($sig =~/^L/) {
	if($sig eq 'Ljava/lang/String;') {
	    $value=newStringUTF($value);
	    bless $value, "jobject";
	}
	$cls->setStaticObjectField($fld, $value);
    } else {
	die "unknown sig '$sig'";
    }

}

# invoke Java method: System.out.println($obj) to dump a java object.
sub dump {
    my($obj) = @_;
    my $out=Jvm::getProperty("java.lang.System","out","Ljava/io/PrintStream;");
    Jvm::DEBUG("field: $out");
    $out->println("(Ljava/lang/Object;)V", $obj);
}

sub DEBUG {
    my($msg) = @_;
    print "$msg\n" if $DEBUG;
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Jvm - Perl extension for Java VM invocation

=head1 SYNOPSIS

  use Jvm;

  # Initialize the JVM
  new Jvm();

  ###################################
  #invoke static method of Java class
  ###################################
  #Equivalent Java code:
  #   Thread.sleep(1000);
  Jvm::call("java.lang.Thread", "sleep", "(J)V", 1000);

  ##########################
  #Java instance manipulate
  ##########################
  #Equivalent Java code:
  # Integer obj = new Integer(99);
  # String s = i.toString();
  $obj = new Jvm("java.lang.Integer", "(I)V", 99);
  $s = $obj->toString("()Ljava/lang/String;");

  #######################
  #get/set static member
  #######################
  #Equivalent Java code:
  # System.out.println("Hello world!");
  $out = Jvm::getProperty("java.lang.System", "out", "Ljava/io/PrintStream;");
  $out->println("(Ljava/lang/String;)V", "Hello world!");


=head1 DESCRIPTION

This package allows you to invoke Java API in Perl.
You can invoke java methods of the standard Java classes as well as your own Java program.

=head1 Java Signature

You have to specify Java method signature when call Java API. This is because
a java class may have more than 1 methods which share the same method name. 
Consider the following example:

    public class Foo {
	public static void test(int i) {}
	public static void test(byte b) {}
    };

B<Foo> class has 2 methods which share the same method name B<test>. You have to 
use method signature to specify which method you are going to call. Here is a 
sample to invoke them respectively:

 Jvm::call("Foo","test","(I)V", 1234567);   #(I)V: means input 'Integer', output 'Void'
 Jvm::call("Foo","test","(B)V", 22);        #(B)V: means input 'Byte', output 'Void'

Java Signature rule is simple, mapping table between signature and method is available at 
http://java.sun.com/j2se/1.3/docs/guide/jni/spec/types.doc.html#16432

If you don't want to learn the signature mapping table, you can use 'javap' tool comes 
with JDK to print out all the signatures in your class, usage is 

 javap -s Your_java_class

Here is an example: 

  [root@yw Jvm]# javac Foo.java
  [root@yw Jvm]# javap -s Foo
  Compiled from Foo.java
  public class Foo extends java.lang.Object {
      public static void test(int);
  	/*   (I)V   */
      public static void test(byte);
  	/*   (B)V   */
      public Foo();
	/*   ()V   */
  }
  [root@yw Jvm]# 


=head1 Function List

=over 4

=item new Jvm();

Initialize JVM.

=item $obj = new Jvm($class, $constructorMethodSig, @args);

create a Java object, whose class name is $class, constructor 
has $constructorMethodSig signature, and @args are arguments for 
constructor. Then later you can invoke method XXX of this instance: 
   $result = $obj->XXX($methodSignature, @args);

=item $ret = call($class, $method, $methodSignature, @args);

Invoke B<static> method $method which has the signature $methodSignature of class $class.

=item $ver = getVersion();

return current JVM version.

=item $value = getProperty($class, $member, $memberSignature);

return value of B<static> member $member of class $class.

=item setProperty($class, $member, $memberSignature, $value);

set B<static> member of class $class to $value.

=item dump($obj)

This function invokes "System.out.println($obj)" to dump the java object $obj.

=head1 Global variables

The global variables below are optional.

=item CLASSPATH

The path(s) where the Java VM searches for java class files

$Jvm::CLASSPATH = "/home/java/classes";

=item LIBPATH

The path(s) where the Java VM searches for JNI libraries

$Jvm::LIBPATH = "/home/java/classes/native";

=head1 AUTHOR

Ye, Wei      w_e_i_y_e@yahoo.com

=head1 CREDITS

Claes Jacobsson (claes@contiller.se) - $Jvm::CLASSPATH and $Jvm::LIBPATH

=head1 SEE ALSO

B<perl>(1).

B<Java JNI Specification>
 http://java.sun.com/j2se/1.3/docs/guide/jni/

B<JPL>
 JPL is a package, which allows you to invoke
 Java in Perl as well as embed Perl in java. It's
 bundled with Perl5.6, you can get it at:
 http://users.ids.net/~bjepson/jpl/cvs.html
 Compare to Jvm, it's more complex.

=cut
