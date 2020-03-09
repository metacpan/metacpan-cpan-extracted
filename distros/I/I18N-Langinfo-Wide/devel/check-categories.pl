#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

# This file is part of I18N-Langinfo-Wide.
#
# I18N-Langinfo-Wide is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# I18N-Langinfo-Wide is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with I18N-Langinfo-Wide.  If not, see <http://www.gnu.org/licenses/>.


use strict;
use warnings;
use I18N::Langinfo;
use I18N::Langinfo::Wide;

my $filename = '/down/glibc/locale/categories.def';

open my $fh, '<', $filename or die;
while (<$fh>) {
  my ($key, $type) = /DEFINE_ELEMENT *\((.+?),.*?([a-z]+)[0-9, ]*\)/m
    or next;
  if ($type =~ /string/) { next; }
  # if ($key  =~ /^_NL/) { next; }
  printf "%-9s %s\n", $type, $key;
  if (defined (eval "I18N::Langinfo::$key()")) {
     print "  -- is in I18N::Langinfo\n";
  }
}

use Data::Dumper;
print Data::Dumper->new([\%I18N::Langinfo::Wide::_byte],['_byte'])->Sortkeys(1)->Dump;


exit 0;
