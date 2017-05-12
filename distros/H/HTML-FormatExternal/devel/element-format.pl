#!/usr/bin/perl -w

# Copyright 2013 Kevin Ryde

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

use strict;
use warnings;
use Module::Load;
use HTML::TreeBuilder;
use Data::Dumper;
$Data::Dumper::Useqq = 1;
use FindBin qw($Bin);

my $class;
$class = 'HTML::FormatText::WithLinks';
$class = 'HTML::FormatText::WithLinks::AndTables';
$class = 'HTML::FormatText::W3m';
$class = 'HTML::FormatText';
$class = 'HTML::FormatText::Netrik';
$class = 'HTML::FormatText::Links';
$class = 'HTML::FormatText::Html2text';
$class = 'HTML::FormatText::Elinks';
$class = 'HTML::FormatText::Lynx';
Module::Load::load ($class);

#  <base href="file:///tmp/">

{
  # output_charset => 'ascii',
  # output_charset => 'ANSI_X3.4-1968',
  # output_charset => 'utf-8'
  my $output_charset = 'utf-8';

  # input_charset => 'shift-jis',
  # input_charset => 'iso-8859-1',
  # input_charset => 'utf-8',
  my $input_charset;
  $input_charset = 'utf16le';
  $input_charset = 'ascii';

  my $formatter = $class->new (
                               input_charset  => $input_charset,
                               output_charset => $output_charset,
                               rightmargin => 60,
                               # leftmargin => 20,
                               justify => 1,

                               base => "http://foo.org/\x{2022}/foo.html",


                               #      lynx_options => [ '-underscore',
                               #                        '-underline_links',
                               #                        '-with_backspaces',
                               #                      ],
                               justify => 1,
                              );

  # {
  #   my $filename = "$FindBin::Bin/base.html";
  #   # my $filename = "/tmp/rsquo.html";
  #   my $tree = HTML::TreeBuilder->new;
  #   $tree->parse_file($filename);
  # }

  my $tree = HTML::Element->new('a', href => 'http://www.perl.com/');
  $tree->push_content("The Perl Homepage");
  print "$tree\n";
  print $tree->as_HTML;

  my $str = $tree->format($formatter);
  $Data::Dumper::Purity = 1;
  print $str;
  print Data::Dumper->new([\$str],['output'])->Useqq(0)->Dump;
  print "utf8 flag ",(utf8::is_utf8($str) ? 'yes' : 'no'), "\n";
  exit 0;
}

