#!/usr/bin/perl

# $Id: ancestors.pl,v 1.7 2007/11/15 18:30:47 sherlock Exp $

# License information (the MIT license)

# Copyright (c) 2003, 2007 Gavin Sherlock; Stanford University

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
&Usage("Your obo file does not exist")                  if (!-e $ontologyFile);
&Usage("Your obo file does not have a .obo extension")  if (!-e $ontologyFile);
&Usage("You must provide an aspect (P|C|F)")            if (!$aspect);

my $ontology = GO::OntologyProvider::OboParser->new(ontologyFile => $ontologyFile,
						    aspect       => $aspect);

my $node = $ontology->nodeFromId($goid) || &Usage("No GO term matches your goid ($goid) in the aspect ($aspect) that you provided");

my @pathsToRoot = $node->pathsToRoot;

foreach my $path (@pathsToRoot){

    for (my $i = 0; $i < @{$path}; $i++){

	print "    " x $i , $path->[$i]->goid, "    ", $path->[$i]->term, "\n";

    }

    print "    " x @{$path} , $node->goid, "    ", $node->term, "\n";

    print "\n";

}

sub Usage{

    my $message = shift;

    print $message, ".\n\n";

    print "Usage :

ancestors.pl <goid> <obo_file> <aspect>

Where aspect is P, C or F.  Note, the provided GOID must be for a GO term in the aspect that you provide.\n\n";

    exit;

}

=pod

=head1 NAME

ancestors.pl - prints paths from root to a GO node

=head1 SYNOPSIS

ancestors.pl simply takes as input a GOID, an obo file, and an
ontology aspect (P, C or F) and prints out the all the paths from that
GO node to the root of the ontology, e.g:

    >ancestors.pl GO:0008346 ../t/gene_ontology_edit.obo P
    GO:0003673    Gene_Ontology
        GO:0008150    biological_process
            GO:0050896    response to stimulus
                GO:0007610    behavior
                    GO:0007626    locomotory behavior
                        GO:0008345    larval locomotory behavior
                            GO:0008346    larval walking behavior

    GO:0003673    Gene_Ontology
        GO:0008150    biological_process
            GO:0050896    response to stimulus
                GO:0007610    behavior
                    GO:0030537    larval behavior
                        GO:0008345    larval locomotory behavior
                            GO:0008346    larval walking behavior

=head1 AUTHORS

Gavin Sherlock, sherlock@genome.stanford.edu

=cut
