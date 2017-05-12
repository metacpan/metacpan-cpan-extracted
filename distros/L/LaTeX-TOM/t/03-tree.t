#!/usr/bin/perl

use strict;
use warnings;

use File::Spec;
use FindBin qw($Bin);
use LaTeX::TOM;
use Test::More tests => 8;

my $file = File::Spec->catfile($Bin, 'data', 'tex.in');
my $tex = do {
    open(my $fh, '<', $file) or die "Cannot open $file: $!\n";
    local $/; <$fh>;
};

my $parser = LaTeX::TOM->new;
my $tree = $parser->parseFile($file);

is_deeply($tree->plainText, [
    'Some Test Doc',
    "\n"                 .
    "    \\maketitle\n"  .
    "    \\mainmatter\n" .
    "    ",
    "\n    ",
    "\n",
], 'Tree as plain text');
is($tree->indexableText, 'Some Test Doc ', 'Tree as indexable text');
is($tree->toLaTeX, do { $_ = $tex; $_ =~ s/\[.*?pt\]//; $_ }, 'Tree to LaTeX');
is(@{$tree->getAllNodes}, 19, 'Amount of all nodes');
is($tree->getTopLevelNodes, 9, 'Amount of top level nodes');
is(@{$tree->getCommandNodesByName('title')}, 1, "Amount of 'title' command nodes");
is(@{$tree->getEnvironmentsByName('document')}, 1, "Amount of 'document' environment nodes");
is(@{$tree->getNodesByCondition(sub {
    my $node = shift;
    return ($node->getNodeType eq 'COMMAND' && $node->getCommandName eq 'title');
})}, 1, "Amount of 'title' command nodes by condition");
