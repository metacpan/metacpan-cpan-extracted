#!/usr/bin/perl -w

use strict;
use warnings;
use t::lib::XSP::Test tests => 1;

run_diff xsp_stdout => 'expected';

__DATA__

=== Simple include files
--- xsp_stdout
%module{Foo};
%package{Foo};

%include{t/files/typemap.xsp};
%include{t/files/include.xsp};
int bar(int y);
--- expected
# XSP preamble


MODULE=Foo

MODULE=Foo PACKAGE=Foo

# trivial typemap


int
foo( int x )
  CODE:
    try {
      RETVAL = foo( x );
    }
    catch (std::exception& e) {
      croak("Caught C++ exception of type or derived from 'std::exception': %s", e.what());
    }
    catch (...) {
      croak("Caught C++ exception of unknown type");
    }
  OUTPUT: RETVAL

int
bar( int y )
  CODE:
    try {
      RETVAL = bar( y );
    }
    catch (std::exception& e) {
      croak("Caught C++ exception of type or derived from 'std::exception': %s", e.what());
    }
    catch (...) {
      croak("Caught C++ exception of unknown type");
    }
  OUTPUT: RETVAL
