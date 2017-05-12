#!/usr/bin/perl -w

use strict;
use warnings;
use t::lib::XSP::Test tests => 5;

run_diff xsp_stdout => 'expected';

__DATA__

=== Pointer/const pointer type
--- xsp_stdout
%module{Foo};
%package{Foo};

%typemap{int*}{simple};
%typemap{const int*}{simple};

int* foo();
int* boo(const int* a);
--- expected
# XSP preamble


MODULE=Foo

MODULE=Foo PACKAGE=Foo

int*
foo()
  CODE:
    try {
      RETVAL = foo();
    }
    catch (std::exception& e) {
      croak("Caught C++ exception of type or derived from 'std::exception': %s", e.what());
    }
    catch (...) {
      croak("Caught C++ exception of unknown type");
    }
  OUTPUT: RETVAL

int*
boo( const int* a )
  CODE:
    try {
      RETVAL = boo( a );
    }
    catch (std::exception& e) {
      croak("Caught C++ exception of type or derived from 'std::exception': %s", e.what());
    }
    catch (...) {
      croak("Caught C++ exception of unknown type");
    }
  OUTPUT: RETVAL

=== Const value/const reference type
--- xsp_stdout
%module{Foo};
%package{Foo};

%typemap{const std::string}{simple};
%typemap{const std::string&}{reference};

void foo(const std::string a);
void boo(const std::string& a);
--- expected
# XSP preamble


MODULE=Foo

MODULE=Foo PACKAGE=Foo

void
foo( const std::string a )
  CODE:
    try {
      foo( a );
    }
    catch (std::exception& e) {
      croak("Caught C++ exception of type or derived from 'std::exception': %s", e.what());
    }
    catch (...) {
      croak("Caught C++ exception of unknown type");
    }

void
boo( std::string* a )
  CODE:
    try {
      boo( *( a ) );
    }
    catch (std::exception& e) {
      croak("Caught C++ exception of type or derived from 'std::exception': %s", e.what());
    }
    catch (...) {
      croak("Caught C++ exception of unknown type");
    }

=== Const value/const reference type via shortcut
--- xsp_stdout
%module{Foo};
%package{Foo};

%typemap{const std::string};
%typemap{std::vector<double>};

void foo(const std::string a);
void boo(const std::string& a);
void foo2(std::vector<double> a, std::vector<double>& b);
--- expected
# XSP preamble


MODULE=Foo

MODULE=Foo PACKAGE=Foo

void
foo( const std::string a )
  CODE:
    try {
      foo( a );
    }
    catch (std::exception& e) {
      croak("Caught C++ exception of type or derived from 'std::exception': %s", e.what());
    }
    catch (...) {
      croak("Caught C++ exception of unknown type");
    }

void
boo( std::string* a )
  CODE:
    try {
      boo( *( a ) );
    }
    catch (std::exception& e) {
      croak("Caught C++ exception of type or derived from 'std::exception': %s", e.what());
    }
    catch (...) {
      croak("Caught C++ exception of unknown type");
    }

void
foo2( std::vector< double > a, std::vector< double >* b )
  CODE:
    try {
      foo2( a, *( b ) );
    }
    catch (std::exception& e) {
      croak("Caught C++ exception of type or derived from 'std::exception': %s", e.what());
    }
    catch (...) {
      croak("Caught C++ exception of unknown type");
    }


=== Template type
--- xsp_stdout
%module{Foo};
%package{Foo};

%typemap{const std::vector<int>&}{simple};
%typemap{const std::map<int, std::string>}{simple};
%typemap{const std::vector&}{reference}; // check type equality

void foo(const std::vector<int>& a);
void boo(const std::map<int, std::string> a);
--- expected
# XSP preamble


MODULE=Foo

MODULE=Foo PACKAGE=Foo


void
foo( const std::vector< int >& a )
  CODE:
    try {
      foo( a );
    }
    catch (std::exception& e) {
      croak("Caught C++ exception of type or derived from 'std::exception': %s", e.what());
    }
    catch (...) {
      croak("Caught C++ exception of unknown type");
    }

void
boo( const std::map< int, std::string > a )
  CODE:
    try {
      boo( a );
    }
    catch (std::exception& e) {
      croak("Caught C++ exception of type or derived from 'std::exception': %s", e.what());
    }
    catch (...) {
      croak("Caught C++ exception of unknown type");
    }
=== Template argument transformed to pointer
--- xsp_stdout
%module{Foo};
%package{Foo};

%typemap{const std::vector<double>&}{reference}; // check type equality

void foo(const std::vector<double>& a);
--- expected
# XSP preamble


MODULE=Foo

MODULE=Foo PACKAGE=Foo


void
foo( std::vector< double >* a )
  CODE:
    try {
      foo( *( a ) );
    }
    catch (std::exception& e) {
      croak("Caught C++ exception of type or derived from 'std::exception': %s", e.what());
    }
    catch (...) {
      croak("Caught C++ exception of unknown type");
    }
