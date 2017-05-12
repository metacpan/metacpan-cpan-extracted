#!/usr/bin/perl -w

use strict;
use warnings;
use t::lib::XSP::Test tests => 2;

run_diff xsp_stdout => 'expected';

__DATA__

=== Basic plugin functionality
--- xsp_stdout
%module{Foo};
%package{Foo};
%loadplugin{t::lib::XSP::Plugin};
%loadplugin{t::lib::XSP::Plugin};

int foo(int y);

class Y
{
    void bar();
};
--- expected
# XSP preamble


MODULE=Foo

MODULE=Foo PACKAGE=Foo

int
foo_perl( int y )
  CODE:
    try {
      RETVAL = foo( y );
    }
    catch (std::exception& e) {
      croak("Caught C++ exception of type or derived from 'std::exception': %s", e.what());
    }
    catch (...) {
      croak("Caught C++ exception of unknown type");
    }
  OUTPUT: RETVAL


MODULE=Foo PACKAGE=Y

void
Y::bar()
  CODE:
    try {
      THIS->bar();
    }
    catch (std::exception& e) {
      croak("Caught C++ exception of type or derived from 'std::exception': %s", e.what());
    }
    catch (...) {
      croak("Caught C++ exception of unknown type");
    }

=== Plugin loading from the plugin namespace
--- xsp_stdout
%module{Foo};
%package{Foo};
%loadplugin{TestPlugin};

int foo(int y);

class Y
{
    void bar();
};
--- expected
# XSP preamble


MODULE=Foo

MODULE=Foo PACKAGE=Foo

int
foo_perl2( int y )
  CODE:
    try {
      RETVAL = foo( y );
    }
    catch (std::exception& e) {
      croak("Caught C++ exception of type or derived from 'std::exception': %s", e.what());
    }
    catch (...) {
      croak("Caught C++ exception of unknown type");
    }
  OUTPUT: RETVAL


MODULE=Foo PACKAGE=Y

void
Y::bar()
  CODE:
    try {
      THIS->bar();
    }
    catch (std::exception& e) {
      croak("Caught C++ exception of type or derived from 'std::exception': %s", e.what());
    }
    catch (...) {
      croak("Caught C++ exception of unknown type");
    }
