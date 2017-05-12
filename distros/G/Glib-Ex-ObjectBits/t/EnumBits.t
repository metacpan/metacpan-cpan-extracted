#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012 Kevin Ryde

# This file is part of Glib-Ex-ObjectBits.
#
# Glib-Ex-ObjectBits is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Glib-Ex-ObjectBits is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Glib-Ex-ObjectBits.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use Test::More tests => 34;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Glib::Ex::EnumBits;

{
  my $want_version = 16;
  is ($Glib::Ex::EnumBits::VERSION, $want_version, 'VERSION variable');
  is (Glib::Ex::EnumBits->VERSION,  $want_version, 'VERSION class method');
  ok (eval { Glib::Ex::EnumBits->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Glib::Ex::EnumBits->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}

#-----------------------------------------------------------------------------
# to_display_default()

foreach my $elem (['foo', 'Foo'],
                  ['foo-bar', 'Foo Bar'],
                  ['foo_bar', 'Foo Bar'],
                  ['foo1', 'Foo 1'],
                  ['foo1bar', 'Foo 1 Bar'],
                  ['foo12bar', 'Foo 12 Bar'],
                  ['foo123bar4', 'Foo 123 Bar 4'],
                  ['FooBar', 'Foo Bar'],
                  ['Foo2Bar', 'Foo 2 Bar'],
                  
                  # think want split at last of run of upper
                  ['AABar', 'AA Bar'],

                  # how this behaves is experimental ...
                  # no split at an upper case followed by a digit 
                  ['A1B2C', 'A1 B2 C'],
                  ['AR2W2Blah', 'AR2 W2 Blah'],
                 ) {
  my ($nick, $want) = @$elem;
  {
    my $got = Glib::Ex::EnumBits::to_display('EnumBits-Test-Enum',$nick);
    is ($got, $want, "to_display() $nick");
  }
  {
    my $got = Glib::Ex::EnumBits::to_display_default('EnumBits-Test-Enum',$nick);
    is ($got, $want, "to_display_default() $nick");
  }
}

#-----------------------------------------------------------------------------
# to_display()

require Glib;
MyTestHelpers::glib_gtk_versions();

Glib::Type->register_enum ('My::Test1', 'foo', 'bar-ski', 'quux');
my $test1_called = 0;
sub My::Test1::EnumBits_to_display {
  my ($class, $nick) = @_;
  # diag "My::Test1::EnumBits_to_display called";
  $test1_called++;
  if ($nick eq 'foo') {
    return "Method \u$nick";
  } else {
    return undef;
  }
}

Glib::Type->register_enum ('My::Test2', 'foo', 'bar-ski', 'quux');
{
  no warnings 'once';
  %My::Test2::EnumBits_to_display = ('foo'     => 'Food',
                                     'bar-ski' => 'Barrage');
}

{
  package My::Test3;
  Glib::Type->register_enum (__PACKAGE__, 'foo');
  our %EnumBits_to_display = ('foo' => 'Oof');
}

# Glib::Type->register_enum ('My::Test4', 'foo', 'bar-ski', 'quux');
# our %My::Test4::EnumBits_to_display = ('foo'     => 'Food',
#                                        'bar-ski' => 'Barrage');




foreach my $elem (['My::Test1', 'foo',     'Method Foo'],
                  ['My::Test1', 'bar-ski', 'Bar Ski'],

                  ['My::Test2', 'foo',     'Food'],
                  ['My::Test2', 'bar-ski', 'Barrage'],
                  ['My::Test2', 'quux',    'Quux'],
                 ) {
  my ($enum_class, $nick, $want) = @$elem;

  my $got = Glib::Ex::EnumBits::to_display($enum_class,$nick);
  is ($got, $want, "to_display() $enum_class $nick");
}
is ($test1_called, 2, "My::Test1::EnumBits_to_display method called");

exit 0;
