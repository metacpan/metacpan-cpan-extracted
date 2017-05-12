#!/usr/bin/perl -w

use strict;
use warnings;
use t::lib::XSP::Test tests => 1;

run_diff xsp_stdout => 'expected';

__DATA__

=== Method decorated with package_static
--- xsp_stdout
%module{Foo};

class Foo
{
    package_static int foo(int a);
};
--- expected
# XSP preamble


MODULE=Foo

MODULE=Foo PACKAGE=Foo

int
foo( int a )
  CODE:
    try {
      RETVAL = Foo::foo( a );
    }
    catch (std::exception& e) {
      croak("Caught C++ exception of type or derived from 'std::exception': %s", e.what());
    }
    catch (...) {
      croak("Caught C++ exception of unknown type");
    }
  OUTPUT: RETVAL
