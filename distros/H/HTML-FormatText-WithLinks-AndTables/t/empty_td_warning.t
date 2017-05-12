#!/usr/bin/perl

use HTML::FormatText::WithLinks::AndTables;
use Test::More tests => 1;
my $html ='<table>
<tr>
   <td></td>
</tr>
</table>';

{
   my @warnings;
   local $SIG{__WARN__} = sub {
      push @warnings, @_;
   };
   my $text = HTML::FormatText::WithLinks::AndTables->convert($html, {rm=>80,cellpadding=>2});
   ok(scalar(@warnings == 0),"no warnings from empty cell");
}

