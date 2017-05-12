#!/usr/bin/perl -w

$header = shift @ARGV;
$footer = shift @ARGV;
$data   = shift @ARGV;

die "usage: $0 header footer xsfiles...\n"
	unless $data;

# load the data from xsdocparse...  predeclare its vars to keep perl
# happy about "possible typo" warnings.
our ($xspods, $data);
require "./$data";

$/ = undef;

open IN, $header or die "can't open $header: $!\n";
$text = <IN>;
close IN;
print $text;

# just dump all of the xs pods in the order we found them.
foreach my $p (@{ $xspods }) {
	print join("\n", @{ $p->{lines} })."\n\n";
}

open IN, $footer or die "can't open $footer: $!\n";
$text = <IN>;
close IN;
print $text;

__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list)

This library is free software; you can redistribute it and/or modify it under
the terms of the GNU Library General Public License as published by the Free
Software Foundation; either version 2.1 of the License, or (at your option) any
later version.

This library is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU Library General Public License for more
details.

You should have received a copy of the GNU Library General Public License along
with this library; if not, write to the Free Software Foundation, Inc., 
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
