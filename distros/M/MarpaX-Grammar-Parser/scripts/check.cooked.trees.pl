#!/usr/bin/env perl

use 5.20.2;
use strict;
use warnings;

use Path::Tiny;

use Tree::DAG_Node;

# -----------------------------------------------

my($dir_name) = './share';

my($root);

for my $file (path($dir_name) -> children(qr/cooked.tree$/) )
{
	say $file;

	$root = Tree::DAG_Node -> read_tree($file);
}
