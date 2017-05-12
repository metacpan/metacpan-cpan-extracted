#!/usr/bin/perl -w

use strict;
use warnings;
use t::lib::XSP::Test tests => 2;

run_diff xsp_stdout => 'expected';

__DATA__

=== Reference in argument
--- xsp_stdout
%module{Foo};

class Foo
{
    void foo( Foo& a );
};
--- expected
# XSP preamble


MODULE=Foo

MODULE=Foo PACKAGE=Foo

void
Foo::foo( Foo* a )
  CODE:
    try {
      THIS->foo( *( a ) );
    }
    catch (std::exception& e) {
      croak("Caught C++ exception of type or derived from 'std::exception': %s", e.what());
    }
    catch (...) {
      croak("Caught C++ exception of unknown type");
    }

=== Reference in return value
--- xsp_stdout
%module{Foo};

class Foo
{
    Foo& foo();
};
--- expected
# XSP preamble


MODULE=Foo

MODULE=Foo PACKAGE=Foo

Foo*
Foo::foo()
  CODE:
    try {
      RETVAL = new Foo( THIS->foo() );
    }
    catch (std::exception& e) {
      croak("Caught C++ exception of type or derived from 'std::exception': %s", e.what());
    }
    catch (...) {
      croak("Caught C++ exception of unknown type");
    }
  OUTPUT: RETVAL

