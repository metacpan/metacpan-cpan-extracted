#!/usr/bin/perl

use HTML::FormatText::WithLinks::AndTables;
use Test::More tests => 1;
my $html ='
<TABLE>
<TR>
    <TD>&nbsp;</TD>
</TR>
</TABLE>';

my $text = HTML::FormatText::WithLinks::AndTables->convert($html, {rm=>80,cellpadding=>2});
#print "got: '$text'\n";
#print "expected: '$expected'\n";
ok($text =~ /^\s+$/s,"blank output, no token strings");


