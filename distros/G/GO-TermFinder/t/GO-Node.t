#!/usr/bin/perl

use strict;
use warnings;
use diagnostics;

use Test::More tests => 6;

# File       : GO-Node.t
# Author     : Gavin Sherlock
# Date Begun : March 9th 2002

# $Id: GO-Node.t,v 1.4 2007/05/02 16:26:12 sherlock Exp $

# This file forms a set of tests for the GO::Node class

use GO::Node;

my $goid = "GO:0008150";
my $term = "biological_process";

my $node = GO::Node->new(goid => $goid,
			 term => $term);

# check that we're the right kind of object

isa_ok($node, "GO::Node");

# check the object implements all the methods in the API

my @methods = qw(addChildNodes addParentNodes addPathToRoot goid term
		 childNodes parentNodes pathsToRoot pathsToAncestor
		 ancestors lengthOfLongestPathToRoot
		 lengthOfShortestPathToRoot meanLengthOfPathsToRoot
		 isValid isAParentOf isAChildOf isAnAncestorOf
		 isADescendantOf isLeaf isRoot);

can_ok($node, @methods);

# now check attribute values

is($node->goid, $goid);

is($node->term, $term);

# now check we get an appropriate error thrown if we miss out a
# required argument

# leave out term

eval {

    $node = GO::Node->new(goid => $goid);

};

like($@, qr/did not provide a value for the 'term' argument/);

# leave out goid

eval {

    $node = GO::Node->new(term => $term);

};

like($@, qr/did not provide a value for the 'goid' argument/);
