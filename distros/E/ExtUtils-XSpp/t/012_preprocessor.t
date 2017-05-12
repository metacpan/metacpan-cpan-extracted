#!/usr/bin/perl -w

use strict;
use warnings;
use t::lib::XSP::Test tests => 6;

# monkeypatch print methods to test conditionals are parsed correctly
no warnings 'redefine';

sub ExtUtils::XSpp::Node::Enum::print {
    return "enum " . $_[0]->name . " " . $_[0]->condition . "\n" .
      join '', map $_->print, @{$_[0]->elements};
}

sub ExtUtils::XSpp::Node::EnumValue::print {
    return "    " . $_[0]->name . " " . $_[0]->condition . "\n";;
}

sub ExtUtils::XSpp::Node::Class::print {
    return "class " . $_[0]->cpp_name . " " . $_[0]->condition . "\n" .
      join '', map $_->print, @{$_[0]->methods};
}

sub ExtUtils::XSpp::Node::Function::print {
    return "    " . $_[0]->cpp_name . " " . $_[0]->condition . "\n";;
}

sub ExtUtils::XSpp::Node::Method::print {
    return "    " . $_[0]->cpp_name . " " . $_[0]->condition . "\n";;
}

run_diff process => 'expected';

__DATA__

=== if, else, endif
--- process xsp_stdout
#include "foo.h"

#if SIZEOF_INT > 4
#error 1
#else
#error 2
#endif
--- expected
# XSP preamble


#include "foo.h"


#if SIZEOF_INT > 4
#define XSpp_zzzzzzzz_017082

#error 1


#else
#define XSpp_zzzzzzzz_074990

#error 2


#endif

=== if, elif, endif
--- process xsp_stdout
#include "foo.h"

#if SIZEOF_INT > 4
#error 1
#elif SIZEOF_INT > 2
#error 2
#endif
--- expected
# XSP preamble


#include "foo.h"


#if SIZEOF_INT > 4
#define XSpp_zzzzzzzz_017082

#error 1


#elif SIZEOF_INT > 2
#define XSpp_zzzzzzzz_074990

#error 2


#endif

=== ifdef, ifndef
--- process xsp_stdout
#include "foo.h"

#ifdef SIZEOF_INT
#error 1
#endif

#ifndef SIZEOF_INT
#error 2
#endif
--- expected
# XSP preamble


#include "foo.h"


#ifdef SIZEOF_INT
#define XSpp_zzzzzzzz_017082

#error 1


#endif

#ifndef SIZEOF_INT
#define XSpp_zzzzzzzz_074990

#error 2


#endif

=== functions
--- process xsp_stdout
%module{Foo};

#if ONE

#if TWO
int foo();
#endif
int bar();

#endif
--- expected
# XSP preamble


MODULE=Foo
#if ONE
#define XSpp_zzzzzzzz_017082

#if TWO
#define XSpp_zzzzzzzz_074990

    foo XSpp_zzzzzzzz_074990
#endif

    bar XSpp_zzzzzzzz_017082
#endif

=== enums
--- process xsp_stdout
%module{Foo};

#if ONE

enum Foo
{
#if TWO
  SOME = 1,
#endif
  NONE = 2,
};

#endif
--- expected
# XSP preamble


MODULE=Foo
#if ONE
#define XSpp_zzzzzzzz_017082

enum Foo XSpp_zzzzzzzz_017082
#if TWO
#define XSpp_zzzzzzzz_074990

    SOME XSpp_zzzzzzzz_074990
#endif

    NONE XSpp_zzzzzzzz_017082
#endif

=== classes/methods
--- process xsp_stdout
%module{Foo};

#if ONE

class Foo
{
#if TWO
    int foo();
#endif
    int bar();
};

#endif
--- expected
# XSP preamble


MODULE=Foo
#if ONE
#define XSpp_zzzzzzzz_017082

class Foo XSpp_zzzzzzzz_017082
#if TWO
#define XSpp_zzzzzzzz_074990

    foo XSpp_zzzzzzzz_074990
#endif

    bar XSpp_zzzzzzzz_017082
#endif
