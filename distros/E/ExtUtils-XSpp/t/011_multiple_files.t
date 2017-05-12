#!/usr/bin/perl -w

use strict;
use warnings;
use t::lib::XSP::Test tests => 3;

run_diff process => 'expected';

__DATA__

=== Basic file - stdout
--- process xsp_stdout
%module{Foo};
%package{Foo};

%file{foo.h};
{%
Some verbatim
text
%}
%file{-};

int foo( int a, int b, int c );
--- expected
# XSP preamble


MODULE=Foo

MODULE=Foo PACKAGE=Foo

int
foo( int a, int b, int c )
  CODE:
    try {
      RETVAL = foo( a, b, c );
    }
    catch (std::exception& e) {
      croak("Caught C++ exception of type or derived from 'std::exception': %s", e.what());
    }
    catch (...) {
      croak("Caught C++ exception of unknown type");
    }
  OUTPUT: RETVAL

=== Basic file - external file
--- process xsp_file=foo.h
%module{Foo};
%package{Foo};

%file{foo.h};
%{
Some verbatim
text
%}
%file{-};

int foo( int a, int b, int c );
--- expected
# XSP preamble



Some verbatim
text

=== Basic file - processed external file
--- process xsp_file=foo.h
%module{Foo};
%package{Foo};

%file{foo.h};
int bar( int x );
%file{-};

int foo( int a, int b, int c );
--- expected
# XSP preamble


int
bar( int x )
  CODE:
    try {
      RETVAL = bar( x );
    }
    catch (std::exception& e) {
      croak("Caught C++ exception of type or derived from 'std::exception': %s", e.what());
    }
    catch (...) {
      croak("Caught C++ exception of unknown type");
    }
  OUTPUT: RETVAL
