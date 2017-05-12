#!/usr/bin/perl

use strict;
use warnings;

use LaTeX::TOM;
use Test::More tests => 2;

my $parser = LaTeX::TOM->new;

my $tex = do { local $/; <DATA> };

my $tree = $parser->parse($tex);

{
    my $nodes = $tree->getCommandNodesByName('section');

    my $ok = (@$nodes == 1
           &&  $nodes->[0]->getNodeType    eq 'COMMAND'
           &&  $nodes->[0]->getCommandName eq 'section'
    );

    ok($ok, 'getCommandNodesByName');
}

{
    my $nodes = $tree->getEnvironmentsByName('document');

    my $ok = (@$nodes == 1
           &&  $nodes->[0]->getNodeType         eq 'ENVIRONMENT'
           &&  $nodes->[0]->getEnvironmentClass eq 'document'
    );

    ok($ok, 'getEnvironmentsByName');
}

__DATA__
\documentclass[10pt]{article}
\begin{document}
\section{abc}
\end{document}
