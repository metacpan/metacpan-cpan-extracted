#!/usr/bin/perl

use strict;
use warnings;

use File::Spec;
use FindBin qw($Bin);
use LaTeX::TOM;
use Test::More tests => 1;

my $abs_path = File::Spec->catfile($Bin, 'data', 'mapping.t');

my $parser = LaTeX::TOM->new(0,0,1);

my $tex = do { local $/; <DATA> };

my $tree_string = $parser->parse($tex);
my $tree_file   = $parser->parseFile(File::Spec->catfile($abs_path, 'mapping.in'));

is_deeply(
    [ grep /\S/, split /\n/, $tree_string->toLaTeX ],
    [ grep /\S/, split /\n/, $tree_file->toLaTeX   ],
'mapping');

__DATA__
\documentclass[10pt]{article}
\newenvironment{centered}{\begin{center}}{\end{center}}
\newcommand{\bold}[1]{{\bf #1}}
\begin{document}
\begin{centered}
foo \bold{bar} baz
\end{centered}
\end{document}
