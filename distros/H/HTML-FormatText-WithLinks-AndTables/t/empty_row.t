#!/usr/bin/perl

use HTML::FormatText::WithLinks::AndTables;
use Test::More tests => 1;
my $html ='
<table>
   <tr>
   </tr>
   <tr>
      <td>cell 1</td>
      <td>cell 2</td>
   </tr>
</table>';

my $text = HTML::FormatText::WithLinks::AndTables->convert($html, {rm=>80,cellpadding=>2});
my $expected = '     cell 1    cell 2  

';
#print "got: '$text'\n";
#print "expected: '$expected'\n";
ok($expected eq $text,"table header displayed");

