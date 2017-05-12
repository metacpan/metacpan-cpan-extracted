#!/usr/bin/perl

use warnings;
use strict;

use List::oo qw(L);

print L(qw(a b c))->map(sub {"|$_|"})->join(" "), "\n";
print L(qw(c a c))->sort->map(sub {"|$_|"})->join(" "), "\n";
print L(qw(a b c))->reverse->map(sub {"|$_|"})->join(","), "\n";

########################################################################
print L(qw(
  This_Page
  That_Page
  The_Other_Page
  Something
  Something_Else
  And_This
  And_That
  ))->
  map( sub {my $t = $_; $t =~ s/_/ /g;[$t, lc($_)]})->
  map( sub {qq(<a href="$_->[1].html">$_->[0]</a>)})->
  map( sub {qq(<td>$_</td>)})->
  dice( sub {rows(3, @_)})->
  map( sub {join("\n    ", '<tr>', @$_ ) . "\n  </tr>"})->
  iunshift('<table>')->
  join("\n  ") . "\n</table>\n";

sub rows {
  my ($n, @l) = @_;
  my @out;
  while(@l) {
    push(@out, []);
    for(1..$n) {
      @l or last;
      push(@{$out[-1]}, shift(@l));
    }
  }
  return(@out);
}
 
# vim:ts=2:sw=2:et:sta
