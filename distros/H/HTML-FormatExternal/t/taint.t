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

require HTML::FormatText::W3m;
my $class = 'HTML::FormatText::W3m';
diag $class;

eval { require Taint::Util }
  or plan skip_all => "due to Taint::Util not available";
{
  my $str = 'hello';
  Taint::Util::taint($str);
  Taint::Util::tainted($str)
      or plan skip_all => "due to not running in perl -T taint mode";
}

plan tests => 35;

Taint::Util::untaint($ENV{PATH});  # so programs can run

foreach my $class ('HTML::FormatText::Elinks',
                   'HTML::FormatText::Html2text',
                   'HTML::FormatText::Links',
                   'HTML::FormatText::Lynx',
                   'HTML::FormatText::Netrik',
                   'HTML::FormatText::W3m',
                   'HTML::FormatText::Zen',
                  ) {
  diag $class;
  use_ok ($class);

  my $good_taint = sub {
    my ($str) = @_;
    return ! defined $str
      || Taint::Util::tainted($str)
      || $str eq '(not reported)'; # as from Netrik.pm
  };

  { my $version = $class->program_full_version;
    ok ($good_taint->($version),
        'program_full_version() should be tainted');
  }
  { my $version = $class->program_version;
    ok ($good_taint->($version),
        'program_version() should be tainted');
  }

  my $have_program = defined($class->program_full_version);
 SKIP: {
    if (! $have_program) {
      skip "$class program not available", 2;
    }
    {
      my $str = $class->format_string ("<html><body><p>Hello</p></body><html>\n");
      ok (Taint::Util::tainted($str),
          "format_string() tainted");
    }
    {
      my $testfilename = File::Spec->catfile($FindBin::Bin,'test.html');
      my $str = $class->format_file ($testfilename);
      ok (Taint::Util::tainted($str),
          "format_file() tainted");
    }
  }
}
exit 0;
