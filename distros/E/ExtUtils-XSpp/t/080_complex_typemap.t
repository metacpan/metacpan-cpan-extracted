#!/usr/bin/perl -w

use strict;
use warnings;
use t::lib::XSP::Test tests => 6;

run_diff xsp_stdout => 'expected';

__DATA__

=== Complex typemap, type rename
--- xsp_stdout
%module{Foo};

%typemap{int}{parsed}{
    %cpp_type{foobar};
};

%typemap{funnyvoid}{parsed}{
    %cpp_type{%void*%};
};

class Foo
{
    int foo( int a, funnyvoid b );
};
--- expected
# XSP preamble


MODULE=Foo

MODULE=Foo PACKAGE=Foo

foobar
Foo::foo( foobar a, void* b )
  CODE:
    try {
      RETVAL = THIS->foo( a, b );
    }
    catch (std::exception& e) {
      croak("Caught C++ exception of type or derived from 'std::exception': %s", e.what());
    }
    catch (...) {
      croak("Caught C++ exception of unknown type");
    }
  OUTPUT: RETVAL

=== Complex typemap, custom return value conversion
--- xsp_stdout
%module{Foo};

%typemap{int}{parsed}{
    %call_function_code{% $CVar = fancy_conversion( $Call ) %};
};

class Foo
{
    int foo( int a, int b );
};
--- expected
# XSP preamble


MODULE=Foo

MODULE=Foo PACKAGE=Foo

int
Foo::foo( int a, int b )
  CODE:
    try {
       RETVAL = fancy_conversion( THIS->foo( a, b ) ) ;
    }
    catch (std::exception& e) {
      croak("Caught C++ exception of type or derived from 'std::exception': %s", e.what());
    }
    catch (...) {
      croak("Caught C++ exception of unknown type");
    }
  OUTPUT: RETVAL

=== Complex typemap, output code
--- xsp_stdout
%module{Foo};

%typemap{int}{parsed}{
    %output_code{% $PerlVar = custom_code( $CVar ) %};
};

class Foo
{
    int foo( int a, int b );
};
--- expected
# XSP preamble


MODULE=Foo

MODULE=Foo PACKAGE=Foo

int
Foo::foo( int a, int b )
  CODE:
    try {
      RETVAL = THIS->foo( a, b );
       ST(0) = custom_code( RETVAL ) ;
    }
    catch (std::exception& e) {
      croak("Caught C++ exception of type or derived from 'std::exception': %s", e.what());
    }
    catch (...) {
      croak("Caught C++ exception of unknown type");
    }
  OUTPUT: RETVAL

=== Complex typemap, cleanup code
--- xsp_stdout
%module{Foo};

%typemap{int}{parsed}{
    %cleanup_code{% custom_code( $PerlVar, $CVar ) %};
};

class Foo
{
    int foo( int a, int b );
};
--- expected
# XSP preamble


MODULE=Foo

MODULE=Foo PACKAGE=Foo

int
Foo::foo( int a, int b )
  CODE:
    try {
      RETVAL = THIS->foo( a, b );
    }
    catch (std::exception& e) {
      croak("Caught C++ exception of type or derived from 'std::exception': %s", e.what());
    }
    catch (...) {
      croak("Caught C++ exception of unknown type");
    }
  OUTPUT: RETVAL
  CLEANUP:
     custom_code( ST(0), RETVAL ) ;

=== Complex typemap, pre-call code
--- xsp_stdout
%module{Foo};

%typemap{int}{parsed}{
    %precall_code{% custom_code( $PerlVar, $CVar ) %};
};

class Foo
{
    int foo( int a, int b );
};
--- expected
# XSP preamble


MODULE=Foo

MODULE=Foo PACKAGE=Foo

int
Foo::foo( int a, int b )
  CODE:
    try {
       custom_code( ST(1), a ) ;
 custom_code( ST(2), b ) ;
      RETVAL = THIS->foo( a, b );
    }
    catch (std::exception& e) {
      croak("Caught C++ exception of type or derived from 'std::exception': %s", e.what());
    }
    catch (...) {
      croak("Caught C++ exception of unknown type");
    }
  OUTPUT: RETVAL

=== Complex typemap, output list code
--- xsp_stdout
%module{Foo};

%typemap{int}{parsed}{
    %output_list{% PUTBACK; XPUSHi( $CVar ); SPAGAIN %};
};

class Foo
{
    int foo( int a, int b );
};
--- expected
# XSP preamble


MODULE=Foo

MODULE=Foo PACKAGE=Foo

int
Foo::foo( int a, int b )
  PPCODE:
    try {
      RETVAL = THIS->foo( a, b );
       PUTBACK; XPUSHi( RETVAL ); SPAGAIN ;
    }
    catch (std::exception& e) {
      croak("Caught C++ exception of type or derived from 'std::exception': %s", e.what());
    }
    catch (...) {
      croak("Caught C++ exception of unknown type");
    }
