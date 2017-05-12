#!/usr/bin/perl -w

use strict;
use warnings;
use t::lib::XSP::Test tests => 14;

run_diff xsp_stdout => 'expected';

__DATA__

=== Basic class
--- xsp_stdout
%module{Foo};

class Foo
{
    int foo( int a, int b, int c );
};
--- expected
# XSP preamble


MODULE=Foo

MODULE=Foo PACKAGE=Foo

int
Foo::foo( int a, int b, int c )
  CODE:
    try {
      RETVAL = THIS->foo( a, b, c );
    }
    catch (std::exception& e) {
      croak("Caught C++ exception of type or derived from 'std::exception': %s", e.what());
    }
    catch (...) {
      croak("Caught C++ exception of unknown type");
    }
  OUTPUT: RETVAL

=== Empty class
--- xsp_stdout
%module{Foo};

class Foo
{
};
--- expected
# XSP preamble


MODULE=Foo

MODULE=Foo PACKAGE=Foo

=== Basic function
--- xsp_stdout
%module{Foo};
%package{Foo::Bar};

int foo( int a );
--- expected
# XSP preamble


MODULE=Foo

MODULE=Foo PACKAGE=Foo::Bar

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

=== Default arguments
--- xsp_stdout
%module{Foo};

class Foo
{
    int foo( int a = 1, int b = 0x1, int c = 1|2 );
};
--- expected
# XSP preamble


MODULE=Foo

MODULE=Foo PACKAGE=Foo

int
Foo::foo( int a = 1, int b = 0x1, int c = 1 | 2 )
  CODE:
    try {
      RETVAL = THIS->foo( a, b, c );
    }
    catch (std::exception& e) {
      croak("Caught C++ exception of type or derived from 'std::exception': %s", e.what());
    }
    catch (...) {
      croak("Caught C++ exception of unknown type");
    }
  OUTPUT: RETVAL

=== Constructor
--- xsp_stdout
%module{Foo};

class Foo
{
    Foo( int a = 1 );
};
--- expected
# XSP preamble


MODULE=Foo

MODULE=Foo PACKAGE=Foo

#undef  xsp_constructor_class
#define xsp_constructor_class(c) (CLASS)

Foo*
Foo::new( int a = 1 )
  CODE:
    try {
      RETVAL = new Foo( a );
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

=== Destructor
--- xsp_stdout
%module{Foo};

class Foo
{
    ~Foo();
};
--- expected
# XSP preamble


MODULE=Foo

MODULE=Foo PACKAGE=Foo

void
Foo::DESTROY()
  CODE:
    try {
      delete THIS;
    }
    catch (std::exception& e) {
      croak("Caught C++ exception of type or derived from 'std::exception': %s", e.what());
    }
    catch (...) {
      croak("Caught C++ exception of unknown type");
    }

=== Void function
--- xsp_stdout
%module{Foo};

class Foo
{
    void foo( int a );
};
--- expected
# XSP preamble


MODULE=Foo

MODULE=Foo PACKAGE=Foo

void
Foo::foo( int a )
  CODE:
    try {
      THIS->foo( a );
    }
    catch (std::exception& e) {
      croak("Caught C++ exception of type or derived from 'std::exception': %s", e.what());
    }
    catch (...) {
      croak("Caught C++ exception of unknown type");
    }

=== No parameters
--- xsp_stdout
%module{Foo};

class Foo
{
    void foo();
    void bar(void);
};
--- expected
# XSP preamble


MODULE=Foo

MODULE=Foo PACKAGE=Foo

void
Foo::foo()
  CODE:
    try {
      THIS->foo();
    }
    catch (std::exception& e) {
      croak("Caught C++ exception of type or derived from 'std::exception': %s", e.what());
    }
    catch (...) {
      croak("Caught C++ exception of unknown type");
    }

void
Foo::bar()
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

=== Comments and raw blocks
--- xsp_stdout
// comment before %module
## comment before %module

%module{Foo};

## comment after %module
// comment after %module

{%
  Passed through verbatim
  as written in sources
%}

# simple typemaps
%typemap{int}{simple};

# before class
class Foo
{
    ## before method
    int foo( int a, int b, int c );
    # after method
};
/* long comment
 * right after
 * class
 */
--- expected
# XSP preamble



## comment before %module


MODULE=Foo
## comment after %module




  Passed through verbatim
  as written in sources


# simple typemaps


# before class



MODULE=Foo PACKAGE=Foo

## before method


int
Foo::foo( int a, int b, int c )
  CODE:
    try {
      RETVAL = THIS->foo( a, b, c );
    }
    catch (std::exception& e) {
      croak("Caught C++ exception of type or derived from 'std::exception': %s", e.what());
    }
    catch (...) {
      croak("Caught C++ exception of unknown type");
    }
  OUTPUT: RETVAL

# after method

=== %length and ANSI style
--- xsp_stdout
%module{Foo};

%package{Bar};

unsigned int
bar( char* line, unsigned long %length{line} );
--- expected
# XSP preamble


MODULE=Foo

MODULE=Foo PACKAGE=Bar

unsigned int
bar( char* line, unsigned long length(line) )
  CODE:
    try {
      RETVAL = bar( line, XSauto_length_of_line );
    }
    catch (std::exception& e) {
      croak("Caught C++ exception of type or derived from 'std::exception': %s", e.what());
    }
    catch (...) {
      croak("Caught C++ exception of unknown type");
    }
  OUTPUT: RETVAL

=== %length and %code
--- xsp_stdout
%module{Foo};

%package{Bar};

unsigned int
bar( char* line, unsigned long %length{line} )
  %code{%RETVAL = bar(length(line)*2);%};
--- expected
# XSP preamble


MODULE=Foo

MODULE=Foo PACKAGE=Bar

unsigned int
bar( char* line, unsigned long length(line) )
  CODE:
    RETVAL = bar(XSauto_length_of_line*2);
  OUTPUT: RETVAL

=== %length and %postcall, %cleanup
--- xsp_stdout
%module{Foo};

%package{Bar};

unsigned int
bar( char* line, unsigned long %length{line} )
  %postcall{% cout << length(line) << endl;%}
  %cleanup{% cout << 2*length(line) << endl;%};
--- expected
# XSP preamble


MODULE=Foo

MODULE=Foo PACKAGE=Bar

unsigned int
bar( char* line, unsigned long length(line) )
  CODE:
    try {
      RETVAL = bar( line, XSauto_length_of_line );
    }
    catch (std::exception& e) {
      croak("Caught C++ exception of type or derived from 'std::exception': %s", e.what());
    }
    catch (...) {
      croak("Caught C++ exception of unknown type");
    }
  POSTCALL:
     cout << XSauto_length_of_line << endl;
  OUTPUT: RETVAL
  CLEANUP:
     cout << 2*XSauto_length_of_line << endl;

=== various integer types
--- xsp_stdout
%module{Foo};

%package{Bar};

short int
bar( short a, unsigned short int b, unsigned c, unsigned int d, int e, unsigned short f, long int g, unsigned long int h );
--- expected
# XSP preamble


MODULE=Foo

MODULE=Foo PACKAGE=Bar

short
bar( short a, unsigned short b, unsigned int c, unsigned int d, int e, unsigned short f, long g, unsigned long h )
  CODE:
    try {
      RETVAL = bar( a, b, c, d, e, f, g, h );
    }
    catch (std::exception& e) {
      croak("Caught C++ exception of type or derived from 'std::exception': %s", e.what());
    }
    catch (...) {
      croak("Caught C++ exception of unknown type");
    }
  OUTPUT: RETVAL
=== verbatim code blocks for xsubs
--- xsp_stdout
%module{Wx};

%typemap{wxRichTextCtrl}{simple};
%name{Wx::RichTextCtrl} class wxRichTextCtrl
{
    %name{newDefault} wxRichTextCtrl()
        %code{% RETVAL = new wxRichTextCtrl();
                wxPli_create_evthandler( aTHX_ RETVAL, CLASS );
             %};
};
--- expected
# XSP preamble


MODULE=Wx

MODULE=Wx PACKAGE=Wx::RichTextCtrl

#undef  xsp_constructor_class
#define xsp_constructor_class(c) (CLASS)

static wxRichTextCtrl*
wxRichTextCtrl::newDefault()
  CODE:
     RETVAL = new wxRichTextCtrl();
                wxPli_create_evthandler( aTHX_ RETVAL, CLASS );
  OUTPUT: RETVAL

#undef  xsp_constructor_class
#define xsp_constructor_class(c) (c)
