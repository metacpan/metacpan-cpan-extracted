#!/usr/bin/perl -w

use strict;
use warnings;
use t::lib::XSP::Test tests => 4;

run_diff xsp_stdout => 'expected';

__DATA__

=== Handle class/method/function annotations
--- xsp_stdout
%module{Foo};
%package{Foo};
%loadplugin{TestParserPlugin};
%loadplugin{TestNewNodesPlugin};

int foo(int y) %MyFuncRename{Foo} %MyComment;

class klass
{
    %MyClassRename{Klass};
    %MyComment;

    klass() %MyMethodRename{newKlass} %MyComment;

    void bar() %MyMethodRename{Bar} %MyComment;
};
--- expected
# XSP preamble


MODULE=Foo

MODULE=Foo PACKAGE=Foo

int
Foo( int y )
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

// function foo



MODULE=Foo PACKAGE=Klass

#undef  xsp_constructor_class
#define xsp_constructor_class(c) (CLASS)

static klass*
klass::newKlass()
  CODE:
    try {
      RETVAL = new klass();
    }
    catch (std::exception& e) {
      croak("Caught C++ exception of type or derived from 'std::exception': %s", e.what());
    }
    catch (...) {
      croak("Caught C++ exception of unknown type");
    }
  OUTPUT: RETVAL

#undef  xsp_constructor_class
#define xsp_constructor_class(c) (c)

void
klass::Bar()
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

// method klass::klass


// method klass::bar


// class klass

=== Handle top level directives
--- xsp_stdout
%module{Foo};
%package{Foo};
%loadplugin{TestParserPlugin};
%loadplugin{TestNewNodesPlugin};

%MyDirective{Foo};
%MyComment;

--- expected
# XSP preamble


MODULE=Foo

MODULE=Foo PACKAGE=Foo

// directive MyComment


// Foo

=== Handle argument annotations
--- xsp_stdout
%module{Foo};

%loadplugin{TestArgumentPlugin};

class klass
{
    int bar(int bar, int foo %MyWrap) %MyWrap;
};
--- expected
# XSP preamble


MODULE=Foo

MODULE=Foo PACKAGE=klass

int
klass::bar( int bar, int foo )
  CODE:
    try {
      // wrapped typemap 1;
      RETVAL = THIS->bar( bar, foo );
    }
    catch (std::exception& e) {
      croak("Caught C++ exception of type or derived from 'std::exception': %s", e.what());
    }
    catch (...) {
      croak("Caught C++ exception of unknown type");
    }
  OUTPUT: RETVAL
  CLEANUP:
    // wrapped typemap ret;

=== Handle member annotations
--- xsp_stdout
%module{Foo};

class klass
{
    int foo;
    %name{baz} int bar;
};
--- expected
# XSP preamble


MODULE=Foo

MODULE=Foo PACKAGE=klass
