#!/usr/bin/perl -w

use strict;
use warnings;
use t::lib::XSP::Test tests => 2;

# monkeypatch Enum/EnumValue just to test that they were parsed correctly
no warnings 'redefine';

sub ExtUtils::XSpp::Node::Enum::print {
    return join "\n", '// ' . ( $_[0]->name || '<anonymous>' ),
                      map $_->print, @{$_[0]->elements};
}

sub ExtUtils::XSpp::Node::EnumValue::print {
    return '//     ' . $_[0]->name;
}

run_diff xsp_stdout => 'expected';

__DATA__

=== Parse and ignore named enums
--- xsp_stdout
%module{Foo};

enum Values
{
    ONE = 1,
    TWO,
    THREE,
};
--- expected
# XSP preamble


MODULE=Foo
// Values
//     ONE
//     TWO
//     THREE

=== Parse and ignore anonymout enums
--- xsp_stdout
%module{Foo};

enum
{
    ONE,
    TWO,
    THREE
};
--- expected
# XSP preamble


MODULE=Foo
// <anonymous>
//     ONE
//     TWO
//     THREE

