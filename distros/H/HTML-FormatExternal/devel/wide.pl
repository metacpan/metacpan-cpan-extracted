#!/usr/bin/perl -w

# Copyright 2015 Kevin Ryde

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
use Data::Dumper;
use HTML::FormatText;
use charnames ':full';
$Data::Dumper::Useqq=1;

my $html = "<html><body>\x{263A}</body></html>";
my $formatter = HTML::FormatText->new;
my $str = $formatter->format_string($html);
print Dumper(\$str);
exit 0;
