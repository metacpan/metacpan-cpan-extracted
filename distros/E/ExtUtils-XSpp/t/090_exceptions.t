#!/usr/bin/perl -w

use strict;
use warnings;
use t::lib::XSP::Test tests => 9;

run_diff xsp_stdout => 'expected';

__DATA__

=== Basic exception declaration
--- xsp_stdout
%module{Foo};

%exception{myException}{std::exception}{stdmessage};

int foo(int a);

--- expected
# XSP preamble


MODULE=Foo
int
foo( int a )
  CODE:
    try {
      RETVAL = foo( a );
    }
    catch (std::exception& e) {
      croak("Caught C++ exception of type or derived from 'std::exception': %s", e.what());
    }
    catch (...) {
      croak("Caught C++ exception of unknown type");
    }
  OUTPUT: RETVAL
=== Basic exception declaration and catch
--- xsp_stdout
%module{Foo};

%exception{myException}{SomeException}{stdmessage};

int foo(int a)
  %catch{myException};

--- expected
# XSP preamble


MODULE=Foo
int
foo( int a )
  CODE:
    try {
      RETVAL = foo( a );
    }
    catch (SomeException& e) {
      croak("Caught C++ exception of type or derived from 'SomeException': %s", e.what());
    }
    catch (...) {
      croak("Caught C++ exception of unknown type");
    }
  OUTPUT: RETVAL

=== Multiple exception declaration and catch
--- xsp_stdout
%module{Foo};

%exception{myException}{SomeException}{stdmessage};
%exception{myException2}{SomeException2}{simple};
%exception{myException3}{SomeException3}{simple};

int foo(int a)
  %catch{myException};

class Foo {
  int bar(int a)
    %catch{myException}
    %catch{myException2};

  int baz(int a)
    %catch{myException3, myException}
    %catch{myException2};

  int buz(int a)
    %catch{myException3};
};

--- expected
# XSP preamble


MODULE=Foo
int
foo( int a )
  CODE:
    try {
      RETVAL = foo( a );
    }
    catch (SomeException& e) {
      croak("Caught C++ exception of type or derived from 'SomeException': %s", e.what());
    }
    catch (...) {
      croak("Caught C++ exception of unknown type");
    }
  OUTPUT: RETVAL


MODULE=Foo PACKAGE=Foo

int
Foo::bar( int a )
  CODE:
    try {
      RETVAL = THIS->bar( a );
    }
    catch (SomeException& e) {
      croak("Caught C++ exception of type or derived from 'SomeException': %s", e.what());
    }
    catch (SomeException2& e) {
      croak("Caught C++ exception of type 'SomeException2'");
    }
    catch (...) {
      croak("Caught C++ exception of unknown type");
    }
  OUTPUT: RETVAL

int
Foo::baz( int a )
  CODE:
    try {
      RETVAL = THIS->baz( a );
    }
    catch (SomeException3& e) {
      croak("Caught C++ exception of type 'SomeException3'");
    }
    catch (SomeException& e) {
      croak("Caught C++ exception of type or derived from 'SomeException': %s", e.what());
    }
    catch (SomeException2& e) {
      croak("Caught C++ exception of type 'SomeException2'");
    }
    catch (...) {
      croak("Caught C++ exception of unknown type");
    }
  OUTPUT: RETVAL

int
Foo::buz( int a )
  CODE:
    try {
      RETVAL = THIS->buz( a );
    }
    catch (SomeException3& e) {
      croak("Caught C++ exception of type 'SomeException3'");
    }
    catch (...) {
      croak("Caught C++ exception of unknown type");
    }
  OUTPUT: RETVAL

=== 'code' exception
--- xsp_stdout
%module{Foo};

%exception{myException}{SomeException}{code}{% croak(e.what()); %};

int foo(int a)
  %catch{myException};

--- expected
# XSP preamble


MODULE=Foo
int
foo( int a )
  CODE:
    try {
      RETVAL = foo( a );
    }
    catch (SomeException& e) {
      croak(e.what());
    }
    catch (...) {
      croak("Caught C++ exception of unknown type");
    }
  OUTPUT: RETVAL

=== 'object' exception
--- xsp_stdout
%module{Foo};

%exception{myException}{SomeException}{object}{PerlClass};

int foo(int a)
  %catch{myException};

--- expected
# XSP preamble


MODULE=Foo
int
foo( int a )
  CODE:
    try {
      RETVAL = foo( a );
    }
    catch (SomeException& e) {
      SV* errsv;
      SV* objsv;
      objsv = eval_pv("PerlClass->new()", 1);
      errsv = get_sv("@", TRUE);
      sv_setsv(errsv, exception_object);
      croak(NULL);
    }
    catch (...) {
      croak("Caught C++ exception of unknown type");
    }
  OUTPUT: RETVAL

=== 'perlcode' exception
--- xsp_stdout
%module{Foo};

%exception{myException}{SomeException}{perlcode}{%some
perl
code%};

int foo(int a)
  %catch{myException};

--- expected
# XSP preamble


MODULE=Foo
int
foo( int a )
  CODE:
    try {
      RETVAL = foo( a );
    }
    catch (SomeException& e) {
      SV* errsv;
      SV* excsv;
      excsv = eval_pv(
        "some"
        "perl"
        "code",
        1
      );
      errsv = get_sv("@", TRUE);
      sv_setsv(errsv, excsv);
      croak(NULL);
    }
    catch (...) {
      croak("Caught C++ exception of unknown type");
    }
  OUTPUT: RETVAL

=== Class-wide catch with precedence test
--- xsp_stdout
%module{Foo};

%exception{myException}{SomeException}{stdmessage};
%exception{myException2}{SomeException2}{stdmessage};
%exception{myException3}{SomeException3}{stdmessage};

class Foo %catch{myException, myException3} {
  int foo(int a)
    %catch{myException3, myException2};
};

--- expected
# XSP preamble


MODULE=Foo

MODULE=Foo PACKAGE=Foo

int
Foo::foo( int a )
  CODE:
    try {
      RETVAL = THIS->foo( a );
    }
    catch (SomeException3& e) {
      croak("Caught C++ exception of type or derived from 'SomeException3': %s", e.what());
    }
    catch (SomeException2& e) {
      croak("Caught C++ exception of type or derived from 'SomeException2': %s", e.what());
    }
    catch (SomeException& e) {
      croak("Caught C++ exception of type or derived from 'SomeException': %s", e.what());
    }
    catch (...) {
      croak("Caught C++ exception of unknown type");
    }
  OUTPUT: RETVAL

=== Catch nothing
--- xsp_stdout
%module{Foo};

%exception{myException}{SomeException}{stdmessage};
%exception{myException3}{SomeException3}{stdmessage};

class Foo %catch{myException, myException3} {
  int foo(int a);
  int bar(int a)
    %catch{nothing};
};

--- expected
# XSP preamble


MODULE=Foo

MODULE=Foo PACKAGE=Foo

int
Foo::foo( int a )
  CODE:
    try {
      RETVAL = THIS->foo( a );
    }
    catch (SomeException& e) {
      croak("Caught C++ exception of type or derived from 'SomeException': %s", e.what());
    }
    catch (SomeException3& e) {
      croak("Caught C++ exception of type or derived from 'SomeException3': %s", e.what());
    }
    catch (...) {
      croak("Caught C++ exception of unknown type");
    }
  OUTPUT: RETVAL

int
Foo::bar( int a )
  CODE:
    try {
      RETVAL = THIS->bar( a );
    }
    catch (...) {
      croak("Caught C++ exception of unknown type");
    }
  OUTPUT: RETVAL

=== Catch nothing (via class)
--- xsp_stdout
%module{Foo};

%exception{myException}{SomeException}{stdmessage};

class Foo %catch{nothing} {
  int foo(int a)
    %catch{myException};
  int bar(int a)
    %catch{nothing};
  int buz(int a);
};

--- expected
# XSP preamble


MODULE=Foo

MODULE=Foo PACKAGE=Foo

int
Foo::foo( int a )
  CODE:
    try {
      RETVAL = THIS->foo( a );
    }
    catch (SomeException& e) {
      croak("Caught C++ exception of type or derived from 'SomeException': %s", e.what());
    }
    catch (...) {
      croak("Caught C++ exception of unknown type");
    }
  OUTPUT: RETVAL

int
Foo::bar( int a )
  CODE:
    try {
      RETVAL = THIS->bar( a );
    }
    catch (...) {
      croak("Caught C++ exception of unknown type");
    }
  OUTPUT: RETVAL

int
Foo::buz( int a )
  CODE:
    try {
      RETVAL = THIS->buz( a );
    }
    catch (...) {
      croak("Caught C++ exception of unknown type");
    }
  OUTPUT: RETVAL
