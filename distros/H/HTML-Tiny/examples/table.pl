#!/usr/bin/perl

use strict;
use warnings;
use HTML::Tiny;

$| = 1;

my $h = HTML::Tiny->new;

# Output a simple HTML page
print $h->table(
  [
    $h->tr(
      [ $h->th( 'Name', 'Score', 'Position' ) ],
      [ $h->td( 'Therese',  90, 1 ) ],
      [ $h->td( 'Chrissie', 85, 2 ) ],
      [ $h->td( 'Andy',     50, 3 ) ]
    )
  ]
);

# Outputs
# <table>
#     <tr><th>Name</th><th>Score</th><th>Position</th></tr>
#     <tr><td>Therese</td><td>90</td><td>1</td></tr>
#     <tr><td>Chrissie</td><td>85</td><td>2</td></tr>
#     <tr><td>Andy</td><td>50</td><td>3</td></tr>
# </table>
