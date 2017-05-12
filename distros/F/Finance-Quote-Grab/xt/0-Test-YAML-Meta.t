#!/usr/bin/perl -w

# 0-Test-YAML-Meta.t -- run Test::CPAN::Meta::YAML if available

# Copyright 2009, 2010, 2011, 2013, 2014 Kevin Ryde

# 0-Test-YAML-Meta.t is shared by several distributions.
#
# 0-Test-YAML-Meta.t is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# 0-Test-YAML-Meta.t is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with this file.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use Test::More;


my $meta_filename = 'META.yml';
unless (-e $meta_filename) {
  plan skip_all => "$meta_filename doesn't exist -- assume this is a working directory not a dist";
}

plan tests => 3;

SKIP: {
  eval { require CPAN::Meta::Validator; 1 }
    or skip "due to CPAN::Meta::Validator not available -- $@";
  eval { require YAML; 1 }
    or skip "due to YAML module not available -- $@", 1;
  diag "CPAN::Meta::Validator version ", CPAN::Meta::Validator->VERSION;

  my $struct = YAML::LoadFile ($meta_filename);
  my $cmv = CPAN::Meta::Validator->new($struct);
  ok ($cmv->is_valid);
  if (! $cmv->is_valid) {
    diag "CPAN::Meta::Validator errors:";
    foreach ($cmv->errors) { diag $_; }
  }
}

{
  # Test::CPAN::Meta::YAML version 0.15 for upper case "optional_features" names
  #
  eval 'use Test::CPAN::Meta::YAML 0.15; 1'
    or plan skip_all => "due to Test::CPAN::Meta::YAML 0.15 not available -- $@";
  
  Test::CPAN::Meta::YAML::meta_spec_ok('META.yml');
}

exit 0;
