#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

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

use strict;
use warnings;
use Test::More tests => 4;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use Glib::Ex::SignalBits qw (accumulator_first
                             accumulator_first_defined);


#------------------------------------------------------------------------------
# accumulator_first

{
  my $default_run = 0;

  {
    package TestAccumulatorFirst;
    use Glib::Object::Subclass
      'Glib::Object',
        signals =>
          { foo =>
            { param_types   => [],
              return_type   => 'Glib::String',
              flags         => ['run-last'],
              class_closure => sub {$default_run++; return "default_run" },
              accumulator   => \&Glib::Ex::SignalBits::accumulator_first_defined,
            },
          };
  }
  my $obj = TestAccumulatorFirst->new;
  my $ret = $obj->signal_emit ('foo');
  is ($ret, "default_run");
  is ($default_run, 1);
}

#------------------------------------------------------------------------------
# accumulator_first_defined

{
  my $default_run = 0;
  my $default_return = "default_run";

  {
    package TestAccumulatorFirstDefined;
    use Glib::Object::Subclass
      'Glib::Object',
        signals =>
          { foo =>
            { param_types   => [],
              return_type   => 'Glib::String',
              flags         => ['run-last'],
              class_closure => sub {
                $default_run++;
                return $default_return;
              },
              accumulator   => \&Glib::Ex::SignalBits::accumulator_first_defined,
            },
          };
  }
  my $obj = TestAccumulatorFirstDefined->new;
  my $ret = $obj->signal_emit ('foo');
  is ($ret, "default_run");
  is ($default_run, 1);
}

exit 0;
