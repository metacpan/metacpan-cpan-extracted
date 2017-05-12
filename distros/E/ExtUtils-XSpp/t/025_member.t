#!/usr/bin/perl -w

use strict;
use warnings;
use t::lib::XSP::Test tests => 4;

run_diff xsp_stdout => 'expected';

__DATA__

=== Basic accessors
--- xsp_stdout
%module{Foo};

class Foo
{
    int foo %get %set;
};
--- expected
# XSP preamble


MODULE=Foo

MODULE=Foo PACKAGE=Foo

int
Foo::get_foo()
  CODE:
    RETVAL = THIS->foo;
  OUTPUT: RETVAL

void
Foo::set_foo( int value )
  CODE:
    THIS->foo = value;


=== Only getter/setter
--- xsp_stdout
%module{Foo};

class Foo
{
    int foo %get;
    int bar %set;
};
--- expected
# XSP preamble


MODULE=Foo

MODULE=Foo PACKAGE=Foo

int
Foo::get_foo()
  CODE:
    RETVAL = THIS->foo;
  OUTPUT: RETVAL

void
Foo::set_bar( int value )
  CODE:
    THIS->bar = value;


=== Getter/setter name
--- xsp_stdout
%module{Foo};

class Foo
{
    int foo %get{readFoo} %set{writeFoo};
};
--- expected
# XSP preamble


MODULE=Foo

MODULE=Foo PACKAGE=Foo

int
Foo::readFoo()
  CODE:
    RETVAL = THIS->foo;
  OUTPUT: RETVAL

void
Foo::writeFoo( int value )
  CODE:
    THIS->foo = value;


=== Getter/setter style
--- xsp_stdout
%module{Foo};

class Foo1
{
    %accessors{
        %get_style{underscore};
        %set_style{underscore};
    };

    %name{bar} int foo %get %set;
};

class Foo2
{
    %accessors{
        %get_style{no_prefix};
        %set_style{camelcase};
    };

    %name{bar} int foo %get %set;
};

class Foo3
{
    %accessors{
        %get_style{no_prefix};
        %set_style{underscore};
    };

    %name{bar} int foo %get %set;
};

class Foo4
{
    %accessors{
        %get_style{uppercase};
        %set_style{uppercase};
    };

    %name{bar} int foo %get %set;
};

class Foo5
{
    %accessors{
        %get_style{no_prefix};
        %set_style{uppercase};
    };

    %name{bar} int foo %get %set;
};

class Foo6
{
    %accessors{
        %get_style{camelcase};
        %set_style{camelcase};
    };

    %name{bar} int foo %get %set;
};
--- expected
# XSP preamble


MODULE=Foo

MODULE=Foo PACKAGE=Foo1

int
Foo1::get_bar()
  CODE:
    RETVAL = THIS->foo;
  OUTPUT: RETVAL

void
Foo1::set_bar( int value )
  CODE:
    THIS->foo = value;


MODULE=Foo PACKAGE=Foo2

int
Foo2::bar()
  CODE:
    RETVAL = THIS->foo;
  OUTPUT: RETVAL

void
Foo2::setBar( int value )
  CODE:
    THIS->foo = value;


MODULE=Foo PACKAGE=Foo3

int
Foo3::bar()
  CODE:
    RETVAL = THIS->foo;
  OUTPUT: RETVAL

void
Foo3::set_bar( int value )
  CODE:
    THIS->foo = value;


MODULE=Foo PACKAGE=Foo4

int
Foo4::GetBar()
  CODE:
    RETVAL = THIS->foo;
  OUTPUT: RETVAL

void
Foo4::SetBar( int value )
  CODE:
    THIS->foo = value;


MODULE=Foo PACKAGE=Foo5

int
Foo5::bar()
  CODE:
    RETVAL = THIS->foo;
  OUTPUT: RETVAL

void
Foo5::SetBar( int value )
  CODE:
    THIS->foo = value;


MODULE=Foo PACKAGE=Foo6

int
Foo6::getBar()
  CODE:
    RETVAL = THIS->foo;
  OUTPUT: RETVAL

void
Foo6::setBar( int value )
  CODE:
    THIS->foo = value;
