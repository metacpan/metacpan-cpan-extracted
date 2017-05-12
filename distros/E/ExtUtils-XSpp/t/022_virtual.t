#!/usr/bin/perl -w

use strict;
use warnings;
use t::lib::XSP::Test tests => 3;

run_diff xsp_stdout => 'expected';

__DATA__

=== Virtual method
--- xsp_stdout
%module{Foo};

class Foo
{
    virtual int foo(int a)
        %code{%dummy%};
    %name{bar} virtual int foo(int a) const
        %code{%dummy%};
};
--- expected
# XSP preamble


MODULE=Foo

MODULE=Foo PACKAGE=Foo

int
Foo::foo( int a )
  CODE:
    dummy
  OUTPUT: RETVAL

int
Foo::bar( int a )
  CODE:
    dummy
  OUTPUT: RETVAL

=== Virtual destructor
--- xsp_stdout
%module{Foo};

class Foo
{
    virtual ~Foo()
        %code{%dummy%};
};
--- expected
# XSP preamble


MODULE=Foo

MODULE=Foo PACKAGE=Foo

void
Foo::DESTROY()
  CODE:
    dummy

=== Pure-virtual method
--- xsp_stdout
%module{Foo};

class Foo
{
    virtual int foo(int a) = 0
        %code{%dummy%};
    %name{bar} virtual int foo(int a) const = 0
        %code{%dummy%};
};
--- expected
# XSP preamble


MODULE=Foo

MODULE=Foo PACKAGE=Foo

int
Foo::foo( int a )
  CODE:
    dummy
  OUTPUT: RETVAL

int
Foo::bar( int a )
  CODE:
    dummy
  OUTPUT: RETVAL
