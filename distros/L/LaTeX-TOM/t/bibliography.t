#!/usr/bin/perl

use strict;
use warnings;

use File::Spec;
use FindBin qw($Bin);
use LaTeX::TOM;
use Test::More tests => 1;

my $abs_path = File::Spec->catfile($Bin, 'data', 'bibliography.t');

my $parser = LaTeX::TOM->new(0,1,0);

my $tex = do { local $/; <DATA> };

chdir $abs_path;

my $tree_string = $parser->parse($tex);
my $tree_file   = $parser->parseFile(File::Spec->catfile($abs_path, 'sample.in'));

is_deeply(
    [ grep /\S/, split /\n/, $tree_string->toLaTeX ],
    [ grep /\S/, split /\n/, $tree_file->toLaTeX   ],
'sample');

__DATA__
\documentclass[10pt]{article}
\begin{document}
\bibliography{sample}
\end{document}
