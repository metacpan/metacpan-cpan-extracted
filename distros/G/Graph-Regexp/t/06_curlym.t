#!/usr/bin/perl -w

# test CURLYM[1] nodes

use Test::More;
use strict;

BEGIN
   {
   plan tests => 3;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Regexp") or die($@);
   };

#############################################################################
# inputs:

my $curlym = <<EOF
   1: EXACT <\$>(3)
   3: END(0)
EOF
;

#############################################################################
# tests

my $graph = Graph::Regexp->graph( \$curlym );

is (ref($graph), 'Graph::Easy');

is ($graph->error(), '', 'no error yet');


