#!/usr/bin/perl

use strict;
use warnings;

use LaTeX::TOM;
use Test::More tests => 1;

my $parser = LaTeX::TOM->new;

my $tex = do { local $/; <DATA> };

my $tree = $parser->parse($tex);

my $nodes = $tree->getNodesByCondition(sub {
    my $node = shift;
    return (
      $node->getNodeType    eq 'COMMAND'
   && $node->getCommandName =~ /section$/
   );
});

my $count = 3;

my $ok = (
    @$nodes == $count
    && (grep { $_->getNodeType    eq 'COMMAND'  } @$nodes) == $count
    && (grep { $_->getCommandName =~ /section$/ } @$nodes) == $count
);

ok($ok, 'getNodesByCondition');

__DATA__
\documentclass[10pt]{article}
\begin{document}
\section{abc}
\subsection{def}
\subsubsection{ghi}
\end{document}
