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

use 5.006;
use strict;
use warnings;
use File::Locate::Iterator;
use Text::Glob;

{
  for (;;) {
    my $sub;
    $sub = sub {
      $sub = 123;
    };
    # undef $sub;
    $sub = 456;
  }
}

{
  require File::FnMatch::Regexp;
  print File::FnMatch::Regexp::pattern_to_regex_string('[!ab]?',FNM_PERIOD=>1),"\n";
  print File::FnMatch::Regexp::pattern_to_regex_string('&'),"\n";
  print File::FnMatch::Regexp::pattern_to_regex_string('[!ab].c'),"\n";
  print File::FnMatch::Regexp::pattern_to_regex_string('?*.c'),"\n";
  print File::FnMatch::Regexp::pattern_to_regex_string('[\\\\x]'),"\n";
  print File::FnMatch::Regexp::pattern_to_regex_string('[\\*]',FNM_NOESCAPE=>1),"\n";
  print File::FnMatch::Regexp::pattern_to_regex_string('[x:\\][:digit:]]'),"\n";

#   print File::FnMatch::Regexp::_char_class('&#'),"\n";
#   print File::FnMatch::Regexp::_char_class('\\'),"\n";
  exit 0;
}

{
  my $re = qr/[abc]/i;
  print $re,"\n";
  my $str = 'XAX';
  $re = "(?i:[abc])";
  print "match ", ($str =~ $re ? 'yes' : 'no'), "\n";
  exit 0;
}

{
  my $re = qr/.{1,}.{1,}.{1,}.{1,}.{1,}.{1,}.{1,}.{1,}a$/;
#  $re = qr/.{1,}a$/;
  my $str = 'a' x 10000;
  require Devel::TimeThis;
  {
    my $t = Devel::TimeThis->new('qr3');
    foreach (1 .. 100) {
      $str =~ $re;
    }
  }
  exit 0;
}

{
print Text::Glob::glob_to_regex('*.c'),"\n";
print File::Locate::Iterator::_glob_to_regex_string('*.c'),"\n";
print File::Locate::Iterator::_glob_to_regex_string('x?y'),"\n";
print File::Locate::Iterator::_glob_to_regex_string('[abc]def'),"\n";
print File::Locate::Iterator::_glob_to_regex_string('.t'),"\n";
print File::Locate::Iterator::_glob_to_regex_string('.t*'),"\n";
exit 0;
}


# sub _glob_to_regex_string {
#   my ($glob) = @_;
# 
#   require Text::Glob;
#   local $Text::Glob::strict_leading_dot    = 0;
#   local $Text::Glob::strict_wildcard_slash = 0;
#   my $re = Text::Glob::glob_to_regex_string ($glob);
# 
#   # anchor to start/end if any wildcards; this doesn't pay attention to
#   # backslashing, the same as "locate" doesn't
#   if ($glob =~ /[*?[]/) {
#     $re = "^$re\$";
#   }
# 
#   # can optimize away leading "^.*" or trailing ".*$"
#   $re =~ s/^\^(\.\*)+//;
#   $re =~ s/(\.\*)+\$$//;
# 
#   return $re;
# }
