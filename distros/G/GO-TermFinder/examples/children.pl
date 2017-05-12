#!/usr/bin/perl

# $Id: children.pl,v 1.8 2007/03/18 05:47:33 sherlock Exp $

# License information (the MIT license)

# Copyright (c) 2003 Gavin Sherlock; Stanford University

# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation files
# (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:

# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
# BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

use strict;
use diagnostics;
use warnings;

use GO::OntologyProvider::OboParser;

my ($goid, $ontologyFile, $aspect) = @ARGV;

&Usage("You must provide a goid")                       if (!$goid);
&Usage("You must provide an obo file")                  if (!$ontologyFile);
&Usage("Your ontology file does not exist")             if (!-e $ontologyFile);
&Usage("Your obo file does not have a .obo extension")  if (!-e $ontologyFile);
&Usage("You must provide an aspect (P|C|F)")            if (!$aspect);

my $ontology = GO::OntologyProvider::OboParser->new(ontologyFile => $ontologyFile,
						    aspect       => $aspect);

my $node = $ontology->nodeFromId($goid) || &Usage("No GO term matches your goid : $goid");

my @children = $node->childNodes;

print "\n";

if (@children){

    print "Children of $goid (", $node->term, ") : \n\n";

    foreach my $child (@children){

	print $child->goid, "    ", $child->term, "\n";

    }

}else{

    print $goid, " has no children.\n";

}

print "\n";

sub Usage{

    my $message = shift;

    print $message, ".\n\n";

    print "Usage :

ancestors.pl <goid> <ontology_file>\n\n";

    exit;

}

=pod

=head1 NAME

children.pl - prints children of a supplied GO node

=head1 SYNOPSIS

children.pl simply takes as input a GOID, and an obo file, and an
ontology aspect (P, C or F) and prints out the children of that GO
node, e.g.:

    >children.pl GO:0008150 ../t/gene_ontology_edit.obo P

    Children of GO:0008150 (biological_process) : 

    GO:0000003    reproduction
    GO:0007582    physiological process
    GO:0021700    developmental maturation
    GO:0050789    regulation of biological process
    GO:0016032    viral life cycle
    GO:0043473    pigmentation
    GO:0007275    development
    GO:0050896    response to stimulus
    GO:0009987    cellular process
    GO:0040007    growth
    GO:0051704    interaction between organisms


=head1 AUTHORS

Gavin Sherlock, sherlock@genome.stanford.edu

=cut
