#!/usr/bin/perl

# Copyright 2008, 2009, 2010, 2013 Kevin Ryde

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

use strict;
use warnings;
use 5.008;
use Encode;
use HTML::FormatExternal;
use Test::More tests => 29;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use HTML::FormatText::Elinks;
use HTML::FormatText::Links;
use HTML::FormatText::Lynx;
use HTML::FormatText::Netrik;
use HTML::FormatText::Vilistextum;
use HTML::FormatText::W3m;
use HTML::FormatText::Zen;

# uncomment this to run the ### lines
# use Smart::Comments;

#------------------------------------------------------------------------------
# vilistextum version 2.6.9 complains
#   "?? getopt returned character code 0%o %c??\n"
# if -u, -c or -y used when no --enable-multibyte
#
my $vilistextum_have_multibyte = do {
  require File::Spec;
  require IPC::Run;
  my $str;
  eval { IPC::Run::run(['vilistextum','-u'],
                       '<',File::Spec->devnull,
                       '>',\$str,
                       '2>&1') };
  defined $str && $str !~ /getopt/
    ? 1 : 0
  };
diag "vilistextum_have_multibyte is $vilistextum_have_multibyte";


#------------------------------------------------------------------------------
# links: U+263A input becomes ":-)" in latin1 output
#
SKIP: {
  my $class = 'HTML::FormatText::Links';
  $class->program_version or skip "$class not available", 1;
  diag $class;

  my $input_charset = 'utf-8';
  my $output_charset = 'latin-1';
  my $html = "<html><body>\x{263A}</body></html>";
  $html = Encode::encode ($input_charset, $html);
  my $str = $class->format_string
    ($html,
     input_charset => $input_charset,
     output_charset => $output_charset);
  like ($str, qr/\Q:-)/,
        "$class U+263A smiley $input_charset -> $output_charset");
}

# lynx undocumented 'justify' option
#
SKIP: {
  my $class = 'HTML::FormatText::Lynx';
  $class->program_version or skip "$class not available", 1;
  diag $class;

  my $html = "<html><body>x y z aaaa</body></html>";
  $html = Encode::encode ('utf-8', $html);
  my $str = $class->format_string
    ($html,
     leftmargin => 0,
     rightmargin => 7,
     justify => 1);
  like ($str, qr/^x  y  z$/m, "$class justify option");
}

foreach my $class ('HTML::FormatText::Elinks',
                   'HTML::FormatText::Links',
                   'HTML::FormatText::Lynx',
                   # 'HTML::FormatText::Netrik',  # no charsets
                   'HTML::FormatText::Vilistextum',
                   'HTML::FormatText::W3m',
                   # 'HTML::FormatText::Zen',  # no charsets
                  ) {
 SKIP: {
    diag $class;
    $class->program_full_version
      or skip "$class program not available", 3;

    my $input_charset = 'utf-8';
    my $output_charset = 'iso-8859-1';
    my $html = "<html><body>\x{B0}</body>\n</html>";
    $html = Encode::encode ($input_charset, $html);
    is (length($html), 12+2+15);
    my $str = $class->format_string
      ($html,
       input_charset => $input_charset,
       output_charset => $output_charset);
    my $degree_bytes = "\x{B0}";
    $degree_bytes = Encode::encode ($output_charset, $degree_bytes);
    is (length($degree_bytes), 1);
    like ($str, qr/\Q$degree_bytes/,
          "$class degree sign $input_charset -> $output_charset");
    ### $str
  }
}

foreach my $class ('HTML::FormatText::Elinks',
                   # 'HTML::FormatText::Links',  # no utf-8 output
                   'HTML::FormatText::Lynx',
                   # 'HTML::FormatText::Netrik',  # no charsets
                   'HTML::FormatText::Vilistextum',
                   'HTML::FormatText::W3m',
                   # 'HTML::FormatText::Zen',  # no charsets
                  ) {
 SKIP: {
    diag $class;
    $class->program_full_version or skip "$class program not available", 3;

    if ($class eq 'HTML::FormatText::Vilistextum'
        && ! $vilistextum_have_multibyte) {
      skip "vilistextum not built with multibyte", 3;
    }

    my $input_charset = 'iso-8859-1';
    my $output_charset = 'utf-8';
    my $html = "<html><body>\x{B0}</body>\n</html>";
    $html = Encode::encode ($input_charset, $html);
    is (length($html), 12+1+15);
    my $str = $class->format_string
      ($html,
       input_charset => $input_charset,
       output_charset => $output_charset);
    my $degree_bytes = "\x{B0}";
    $degree_bytes = Encode::encode ($output_charset, $degree_bytes);
    is (length($degree_bytes), 2);
    like ($str, qr/\Q$degree_bytes/,
          "$class degree sign $input_charset -> $output_charset");
  }
}

exit 0;
