#!/usr/bin/perl

use HTML::FormatText::WithLinks::AndTables;
use Test::More tests => 1;
my $html ='<table>
<tr>
   <th>header1</th>
</tr>
</table>';

my $text = HTML::FormatText::WithLinks::AndTables->convert($html, {rm=>80,cellpadding=>2});
my $expected = '     header1

';
#print "expected: $expected\n";
#print "got: $text\n";
ok($expected eq $text,"table header displayed");
