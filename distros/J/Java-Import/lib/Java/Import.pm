use GCJ::Cni;
use Java::Wrapper;
use Java::ClassProxy;
#use threads;

package Java::Import;
require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(jstring);

our $vm_initted = 0;
#our %threads;

sub import {
	my $package = shift;
	my @classes = @_;
	map make_namespace($_), @classes;

	{ 
		#lock $vm_initted;
		if ( not $vm_initted ) {
			GCJ::Cni::JvCreateJavaVM(undef);
			#my $thread = GCJ::Cni::JvAttachCurrentThread("PERLTHREAD:" . threads->tid(), undef);
			my $thread = GCJ::Cni::JvAttachCurrentThread("PERLTHREAD:", undef);
			$vm_initted = 1;
		}
	}
	
	Java::Import->export_to_level(1, @EXPORT);
}

sub make_namespace {
	my $java_class = shift;
	$java_class =~ s/\./::/g;
	eval "package $java_class; push \@ISA, 'Java::Import::ClassProxy'; 1;";
}

sub jstring {
	Java::Import::ClassProxy::_wrap_java_object( 
		Java::Wrapper::ObjectWrapper::wrapString($_[0]) 
	);
}

sub jint {
	Java::Import::ClassProxy::_wrap_java_object( 
		Java::Wrapper::ObjectWrapper::wrapInt($_[0])
	);
}

sub jchar {
	Java::Import::ClassProxy::_wrap_java_object(
		Java::Wrapper::ObjectWrapper::wrapChar($_[0])
	);
}

sub jboolean {
        Java::Import::ClassProxy::_wrap_java_object(
                Java::Wrapper::ObjectWrapper::wrapBoolean($_[0])
        );
}

sub jbyte {
        Java::Import::ClassProxy::_wrap_java_object(
                Java::Wrapper::ObjectWrapper::wrapByte($_[0])
        );
}

sub jshort {
        Java::Import::ClassProxy::_wrap_java_object(
                Java::Wrapper::ObjectWrapper::wrapShort($_[0])
        );
}

sub jlong {
        Java::Import::ClassProxy::_wrap_java_object(
                Java::Wrapper::ObjectWrapper::wrapLong($_[0])
        );
}

sub jdouble {
        Java::Import::ClassProxy::_wrap_java_object(
                Java::Wrapper::ObjectWrapper::wrapDouble($_[0])
        );
}

sub jfloat {
        Java::Import::ClassProxy::_wrap_java_object(
                Java::Wrapper::ObjectWrapper::wrapFloat($_[0])
        );
}

sub newJavaArray {
	my $array = new Java::Wrapper::ArrayWrapper(shift, shift);
	$array->DISOWN();
	my @parray;
	tie @parray, 'Java::Import::TieJavaArray', $array;
	return \@parray;
}

sub END {
	GCJ::Cni::JvDetachCurrentThread();
}

1;

__END__

=head1 NAME

Java::Import - Use Java classes in Perl

=head1 SYNOPSIS

   use Java::Import qw(
      some.package.SomeClass
   );

   my $instance = new some.package.SomeClass();
   $instance->someMethod();

   my $ret_val = some::package::SomeClass::someStaticMethod();
   $ret_val->someMethod();

   $ret_val2 = $instance->someOtherMethod($ret_val);
   $ret_val2->someMethod();

   my $java_array_ref $instance->someMethod2();
   foreach my $obj ( @$java_array_ref ) {
      $obj->someMethod();
   }

=head1 DESCRIPTION

The purpose of this module is to provide a simple method for using Java classes from a Perl program while using the latest in Open Source Java Technology.  Thus, this module makes great use of the GNU Compiler Tools for Java in it's implimentation.

=head1 CALLING JAVA CLASSES FROM PERL

The main goal of this module is to make it very easy and transparent to call Java classes from Perl.  This is handled through the use of the Java Reflection API, directly.  This is done through the use of the GCJ::Cni(3) interface.

=head2 Importing Java Classes

Importing a Java class for use in your Perl program is very easy

   use Java::Import qw(
      java.lang.StringBuffer
   );

This simply sets up a namespace corresposding to the requested Java class and facilitates any future calls to this class or any of its' instances.  You can import as many Java classes as you desire.  All java classes are translated into Perl namespaces by simply replacing '.' with '::'.  In the above example "java.lang.StringBuffer" will correspond to the "java::lang::StringBuffer" namespace in Perl.

=head2 Constructing Class Instances

Once a Java class has been 'imported' and it's namespace has been setup it can be instantiated with the new operator/method.

   use Java::Import qw(
      java.lang.StringBuffer
   );
   
   my $sb = new java::lang::StringBuffer();

Since Java Reflection is being used behind the scenes, a call to construct a class without a public Constructor or with the wrong types/amount of parameters will throw a NoSuchMethodException. More information on catching exceptions may be found below.

=head2 Calling Object Methods

Calling Methods on a Java object in Perl is no different than calling methods on a regular Perl Object.

   use Java::Import qw(
      java.lang.StringBuffer()
   );
   
   my $sb = new java::lang::StringBuffer();
   $sb->append(jstring("java String"));

The method call is intercepted by Perl along with its' arguments and invoked on the appropriate object instance.  If a return value is expected it will also be a Java object of the appropriate type.

=head2 Calling Static Methods

Static methods are handled as part of the namespace setup by the use statement and are called through the customary Perl convention, for instance:

   use Java::Import qw(
      java.lang.Class
   );

   my $class_object = java::lang::Class->forName(jstring("java.lang.StringBuffer"));

=head2 Handling Return Values

All values returned from a Java method are themselves Java classes.  This means that even primitive Java types are treated as Java objects this is done by wrapping them in their equivilant "java.lang" object.  The only exception to this rule is Strings.  For instance, a return type of Java 'int' will be returned to Perl as type "java.lang.Integer".  To convert a Primitive type to a Perl type you may access it as a string.

=head2 Handling Method Arguments

All arguments to methods of a Java Object must themselves be Java Objects.  This means that primitives must first be wrapped in their Object equivilant before being passed to a Java Method.  You can find information on wrapping Java primitive types below.  This piece of functionality is quite annoying and will change in the future.

=head2 Dealing with Java Arrays

When a Java Method returns an array of objects, it is automatically tied to a Perl Class which will give it Perl-like array functionailty.

   use Java::Import qw(
      some.package.SomeClass
   );
   
   my $array_ref = some::package::SomeClass::giveMeAnArray();
   foreach my $obj ( @$array_ref ) {
      $obj->someMethod();
   }


=head2 Dealing with Primitive Types

To use primitive types in Java Method calls they must first be wrapped in their Object equivilant.  The following functions are made available through the Java::Import namespace for this purpose.

   jint
   jboolean
   jshort
   jlong
   jchar
   jbyte
   jfloat
   jdouble
   jstring

These functions are not exported by default and must be accessed through the Java::Import namespace.

=head2 Exception Handling

Exception handling is handled the same way as Perl exception handling:

   use Java::Import qw(
      some.package.SomeClass
   );
   
   eval {
      my $class_instance = new some::package::SomeClass();
      $class_instance->someMethod();
   };
   
   if ( $@ ) {
      if ( $@->isa('some::package::SomeException') ) {
         $@->printStackTrace();
      } else {
         print "Caught Unhandled Exception\";
      }
   }

Note that the $@ variable holds an instance of the Exception thrown.  Even though Java Reflection is being used this is not of type InvocationTargetException, instead the wrapped Exception is thrown.

=head2 isa

You can ask questions about an object's inheritence hierarchy through the isa method.  This is mostly useful when handling Exceptions.

   use Java::Import qw(
      java.lang.Class
   }
   
   eval {
      my $sb_class = java::lang::Class->forName(jstring("java.lang.StringBuffer"));
      my $sb_obj = $sb_class->newInstance();
   };
   
   if ( $@ ) {
      if ( $@->isa("java::lang::ClassNotFoundException") ) {
         print "Cannot find Class\n";
      } elsif ( $@->isa("java::lang::InstantiationException") ) {
         print "Instantiation Exception\n";
      } elsif ( $@->isa("java::lang::IllegalAccessException") ) {
         print "IllegalAccesException\n";
      } elsif ( $@->isa("java::lang::SecurityException") ) {
         print "SecurityException\n";
      }
   }

=head2 can

You can also ask a Java Object whether it has the capability to perform a certain action through the can method.

   use Java::Import qw(
      java.lang.StringBuffer
   );
   
   my $sb = new java::lang::StringBuffer(jstring("hi there"));
   if ( $sb->can("toString") ) {
      print $sb->toString() . "\n";
   }


=head2 Converting Java Objects to Strings

When using a Java Object in a String Context the toString method will automatically be invoked therefore the following piece of code will have the desired result:

   use Java::Import qw(
      java.lang.StringBuffer
   );
   
   my $sb = new java::lang::StringBuffer(jstring("hi there"));
   print "$sb\n";


=head2 Inheriting from a Java Class

Very simply, add the appropriate Java Class to the ISA array.

   use Java::Import qw( java.lang.StringBuffer );
   
   package BetterBuffer;
   our @ISA = qw(java::lang::StringBuffer);
   
   sub new {
      bless new java::lang::StringBuffer(@_), shift;
   }
   
   sub append {
      my $self = shift;
      $self->SUPER::append(@_);
      print "The Capacity of the Buffer is: " . $self->capacity() . "\n";
   }

   1;

   package main;
   
   my $bb = new BetterBuffer(jstring("better buffer!"));
   $bb->append(jstring(" woo hoo? "));
   print "$bb\n";

At the moment you cannot use this inherited class as a replacement for StringBuffer in other Java Calls.  In addition, Inheriting from Abstract classes and Interfaces will not currently work.  These features are something I hope to see in the future.

=head1 TODO

- Add Support for Java Fields.

- Inheritence does not work as expected.

- Allow inherited classes to be passed as Java Objects.

=head1 REQUIREMENTS

This module requires gcc-java >= 4.0 to build and run. A patch for 3.x is in the works.

=head1 ACKNOWLEDGEMENTS

A special thanks to Google and the Perl Foundation for sponsoring this project through their first ever Summer of Code Program.

=head1 AUTHOR

David Rusek, rusekd@cpan.org

=head1 SEE ALSO 

perl(1), Inline::Java(3), GCJ::Cni(3), GCJ (http://gnu.gcc.org/java)

=cut
