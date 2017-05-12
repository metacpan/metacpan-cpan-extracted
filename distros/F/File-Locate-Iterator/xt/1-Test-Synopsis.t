#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde

# This file is part of File-Locate-Iterator.
#
# File-Locate-Iterator is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# File-Locate-Iterator is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with File-Locate-Iterator.  If not, see <http://www.gnu.org/licenses/>.


use strict;
use warnings;
use Test::More;

use lib 't';
use MyTestHelpers;
# no nowarnings() for now since Iterator::Simple 0.05 does an import of
# UNIVERSAL.pm 'isa', which perl 5.12.0 spams about to warn()
# BEGIN { MyTestHelpers::nowarnings() }

eval 'use Test::Synopsis; 1'
  or plan skip_all => "due to Test::Synopsis not available -- $@";

my $manifest = ExtUtils::Manifest::maniread();
my @files = grep m{^lib/.*\.pm$}, keys %$manifest;

if (! eval { require Iterator }) {
  diag "skip Iterator::Locate since Iterator.pm not available -- $@";
  @files = grep {! m{/Iterator/Locate.pm} } @files;
}

if (! eval { require Iterator::Simple }) {
  diag "skip Iterator::Simple::Locate since Iterator::Simple not available -- $@";
  @files = grep {! m{/Iterator/Simple/Locate.pm} } @files;
}

if (! eval { require MooseX::Iterator }) {
  diag "skip MooseX::Iterator::Locate since MooseX::Iterator not available -- $@";
  @files = grep {! m{/MooseX/Iterator/Locate.pm} } @files;
}

plan tests => 1 * scalar @files;

Test::Synopsis::synopsis_ok(@files);
exit 0;
