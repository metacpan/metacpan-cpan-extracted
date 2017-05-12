#!/usr/bin/perl

# Test program for Perl module MassCalculator.pm
# Copyright (C) 2005 Jacques Colinge

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

# Contact:
#  Prof. Jacques Colinge
#  Upper Austria University of Applied Science at Hagenberg
#  Hauptstrasse 117
#  A-4232 Hagenberg, Austria

BEGIN{
    use File::Basename;
    push @INC, basename($0);
}
BEGIN {
    use CGIUtils;
}

use strict;
use CGI qw(:standard);
use InSilicoSpectro;
use InSilicoSpectro::InSilico::ModRes;

InSilicoSpectro::init();
print header();
print <<end_of_html;
<html>

<head>

<title>modifications list</title>

<META HTTP-EQUIV="CONTENT-TYPE" CONTENT="text/html; charset=utf-8">

</head>

<body bgcolor=white>
<h1>Available modifications</h1>

<table border=1 cellspacing=0 cellpadding=5>
<tr><td><b>Name</b></td><td><b>Description</b></td><td><b>Mono delta</b></td><td><b>Avg delta</b></td></tr>
end_of_html

foreach (InSilicoSpectro::InSilico::ModRes::getList()){
  print "<tr><td align=left>",$_->name(),"</td><td align=left>",($_->get('description') || '&nbsp;'),"</td><td align=left>",$_->get('delta_monoisotopic'),"</td><td align=left>",$_->get('delta_average'),"</td></tr>\n";
}

print <<end_of_html;
</table>
</body>
</html>
end_of_html
