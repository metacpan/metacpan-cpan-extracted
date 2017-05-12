#!/usr/bin/perl

use strict;
use warnings;
use diagnostics;

use Test;
BEGIN { plan tests => 19 };

# File       : GO-OntologyProvider-OboParser.t
# Author     : Gavin Sherlock
# Date Begun : March 9th 2002

# $Id: GO-OntologyProvider-OboParser.t,v 1.1 2007/03/18 01:33:14 sherlock Exp $

# This file forms a set of tests for the
# GO::AnnotationProvider::AnnotationParser class

use GO::OntologyProvider::OboParser;

# 'make test' command will be run from one directory up

my $ontologyFile = "t/gene_ontology_edit.obo";

my $ontology = GO::OntologyProvider::OboParser->new(ontologyFile => $ontologyFile,
						    aspect       => 'P');

# check we're the right type of object

ok($ontology->isa("GO::OntologyProvider::OboParser"));

ok($ontology->isa("GO::OntologyProvider"));

# check the object returns a code reference when asked if it can do a
# method that should exist

my @methods = qw (printOntology allNodes rootNode nodeFromId numNodes
		  serializeToDisk);

foreach my $method (@methods){

    ok(ref($ontology->can($method)), "CODE");

}

# now we want to check some of the attributes

# check the total number of nodes, which has been manually checked.
# Note, this number includes an extra '1', which is the Gene_Ontology
# node that is specifically created by the parser.

ok(scalar($ontology->allNodes), 12556);

my $rootNode = $ontology->rootNode;

# some specifics about the root node

ok($rootNode->goid, "GO:0003673");

ok($rootNode->term, "Gene_Ontology");

ok(scalar($rootNode->childNodes), 1); # should only have 1 child

ok(scalar($rootNode->parentNodes), 0); # should be no parents

# check it's only child is biological_process

ok(($rootNode->childNodes)[0]->goid, "GO:0008150");

ok(($rootNode->childNodes)[0]->term, "biological_process");

# check a random node with plenty of parents

my $node = $ontology->nodeFromId("GO:0042217");

ok(scalar($node->parentNodes), 6);

# now check a random node with lots of children

my $otherNode = $ontology->nodeFromId("GO:0006520");

ok(scalar($otherNode->childNodes), 16); # manually checked

# now check that each node is valid

my $validNodes = 0;

foreach my $node ($ontology->allNodes){

    $validNodes += $node->isValid;

}

ok(scalar($ontology->allNodes), $validNodes);

ok($ontology->numNodes, $validNodes);

=head1 Modifications

 List them here.

 CVS information:

 # $Author: sherlock $
 # $Date: 2007/03/18 01:33:14 $
 # $Log: GO-OntologyProvider-OboParser.t,v $
 # Revision 1.1  2007/03/18 01:33:14  sherlock
 # Adding new test files
 #
 # Revision 1.2  2004/05/06 01:39:57  sherlock
 # couple of extra tests, to check all nodes are valid.
 #

=cut
