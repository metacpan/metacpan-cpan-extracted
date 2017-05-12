#!/usr/bin/perl -w

# Copyright 2015 Kevin Ryde

# This file is part of HTML-FormatExternal.
#
# HTML-FormatExternal is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# HTML-FormatExternal is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with HTML-FormatExternal.  If not, see <http://www.gnu.org/licenses/>.

use 5.006;
use strict;
use warnings;
use FindBin;
use File::Spec;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

if (defined $ENV{PATH}) {
  ($ENV{PATH}) = ($ENV{PATH} =~ /(.*)/);  # untaint so programs can run
}

eval {
  my $str = '';
  utf8::upgrade($str);
  utf8::is_utf8($str)
  } or plan skip_all => "due to no wide chars in this perl";

# A couple of the tests depend on w3m giving U+263A smiley face back as that
# utf-8 character, or not as that character if asked for ascii output.
# Should be good with any reasonably recent w3m.
#
require HTML::FormatText::W3m;
my $class = 'HTML::FormatText::W3m';
diag $class;

unless ($class->program_full_version) {
  plan skip_all => "due to $class program not available";
}

plan tests => 13;

my $smiley = 0x263A;

#------------------------------------------------------------------------------
# format_string()

{
  my $html = '<html><body>Hello '.chr($smiley).' </body><html>';
  ok (utf8::is_utf8($html), "input is wide");

  my $text = $class->format_string ($html);
  ok (utf8::is_utf8($text), "format_string() wide input gives wide output");
  like ($text, qr/[^[:ascii:]]/,
        "format_string() wide input gives wide output -- has non-ascii");
}

{
  my $html = '<html><body>Hello</body><html>';
  ok (! utf8::is_utf8($html), "input not wide");

  my $text = $class->format_string ($html, output_wide => 1);
  ok (utf8::is_utf8($text), "format_string() output_wide forced on");
}

{
  my $html = '<html><body>Hello '.chr($smiley).' </body><html>';
  ok (utf8::is_utf8($html), "input is wide");

  my $text = $class->format_string ($html, output_wide => 0);
  ok (! utf8::is_utf8($text), "format_string() output_wide forced off");
}

{
  my $html = '<html><body>Hello '.chr($smiley).' </body><html>';
  ok (utf8::is_utf8($html), "input is wide");

  my $text = $class->format_string ($html, output_charset => 'ascii');
  ok (utf8::is_utf8($text), "format_string() wide but output_charset ascii");
  like ($text, qr/^[[:ascii:]]*$/,
        "format_string() wide but output_charset ascii -- contain ascii only");
}

#------------------------------------------------------------------------------
# format_file()

my $testfilename = File::Spec->catfile($FindBin::Bin,'test.html');

{
  my $text = $class->format_file ($testfilename);
  ok (! utf8::is_utf8($text), "format_file() output not wide");
}
{
  my $text = $class->format_file ($testfilename, output_wide => 1);
  ok (utf8::is_utf8($text), "format_file() output_wide forced on");
}
{
  my $text = $class->format_file ($testfilename, output_wide => 0);
  ok (! utf8::is_utf8($text), "format_file() output_wide forced off");
}

exit 0;
