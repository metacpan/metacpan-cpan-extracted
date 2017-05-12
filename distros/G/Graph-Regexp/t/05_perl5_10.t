#!/usr/bin/perl -w

# test that we understand the output of Perl 5.10

use Test::More;
use strict;

BEGIN
   {
   plan tests => 4 + 5 * 2;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Regexp") or die($@);
   };

#############################################################################
# inputs:

my $anyof_5_10 = <<EOF
   1: BOL (2)
   2: ANYOF[ab] (13)
  13: EOL (14)
  14: END (0)
EOF
;

my $anyof = <<EOF
   1: BOL(2)
   2: ANYOF[ab](13)
  13: EOL(14)
  14: END(0)
EOF
;

my $specials_5_10 = <<EOS
   1: EXACT <\$\@> (3)
   3: END (0)
EOS
;
my $specials = <<EOS
   1: EXACT <\$\@>(3)
   3: END(0)
EOS
;

my $trie_2 = <<TRIE_2
   1: OPEN1 (3)
   3:   EXACT <fo> (5)
   5:   TRIE-EXACT[bo] (9)
        <o>
        <b>
   9: CLOSE1 (11)
  11: END (0)
TRIE_2
;

# (foo|fob|bar)
my $trie_3 = <<TRIE
   1: OPEN1 (3)
   3:   TRIE-EXACT[bf] (12)
        <foo>
        <fob>
        <bar>
  12: CLOSE1 (14)
  14: END (0)
TRIE
;

#############################################################################
# tests comparing 5.8 and 5.10 

compare('anyof',$anyof,$anyof_5_10);
compare('specials',$specials,$specials_5_10);

#############################################################################
# tests with 5.10 input

my $graph = Graph::Regexp->graph( \$trie_2 );
is (ref($graph), 'Graph::Easy');
is ($graph->error(), '', 'no error yet');

is ($graph->node('5')->label(), '[bo]', 'found [bo]');

#############################################################################

sub compare
  {
  my ($name, $input, $input_5_10) = @_;

  my $graph = Graph::Regexp->graph( \$input );
  is (ref($graph), 'Graph::Easy');
  is ($graph->error(), '', 'no error yet');

  my $graph_5_10 = Graph::Regexp->graph( \$input_5_10 );
  is (ref($graph), 'Graph::Easy');
  is ($graph->error(), '', 'no error yet');

  is ($graph->as_ascii(), $graph_5_10->as_ascii(), "as_ascii of $name is equal");

  }
